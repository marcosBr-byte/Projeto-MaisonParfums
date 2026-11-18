require "test_helper"

class MercadoPagoCheckoutTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  class Transporte
    attr_reader :requisicao
    attr_accessor :corpo, :codigo
    def initialize(corpo)
      @corpo, @codigo = corpo, "200"
    end
    def start(*)
      yield self
    end
    def request(req)
      @requisicao = req
      Struct.new(:code, :body).new(codigo, JSON.generate(corpo))
    end
  end

  setup do
    @config = Configuracao.atual
    @config.update!(pagamento_ativo: true, pagamento_teste: true, pagamento_token: "credencial-de-teste",
      pagamento_webhook_secret: "assinatura-de-teste", pagamento_site_url: "https://maison.example", frete_pago_valor: 20)
    @usuario = Usuario.create!(nome: "Pagador", email: "pagador@example.com", telefone: "85999999999", password: "senha-teste-123")
    @pedido = @usuario.pedidos.create!(valor_total: 120, status: :pendente)
    @http = Transporte.new({ "id" => "ORDTST01MAISON123", "checkout_url" => "https://www.mercadopago.com.br/checkout/v1/redirect?order_id=ORDTST01MAISON123" })
    @servico = MercadoPagoCheckout.new(@config, http: @http)
  end

  test "cria checkout com valor do servidor e reutiliza order" do
    url = @servico.criar(@pedido)
    corpo = JSON.parse(@http.requisicao.body)
    assert_equal "120.00", corpo.dig("items", 0, "unit_price")
    assert_equal "120.00", corpo["total_amount"]
    assert_equal "online", corpo["type"]
    assert_equal "manual", corpo["processing_mode"]
    assert_equal "/v1/orders", @http.requisicao.path
    assert_equal @pedido.pagamento_referencia, @http.requisicao["X-Idempotency-Key"]
    assert_equal @pedido.pagamento_referencia, corpo["external_reference"]
    assert_equal "https://maison.example/pedidos/#{@pedido.id}/pagamento", corpo.dig("config", "online", "success_url")
    assert_nil corpo["notification_url"]
    assert_equal "ORDTST01MAISON123", @pedido.reload.pagamento_order_id
    assert @pedido.reload.pagamento_teste?
    assert_equal "Bearer credencial-de-teste", @http.requisicao["Authorization"]
    @http.codigo = "500"
    assert_equal url, @servico.criar(@pedido)
  end

  test "rejeita redirecionamentos externos e erros do provedor sem perder pedido" do
    @http.corpo["checkout_url"] = "https://site-malicioso.example/cobrar"
    assert_raises(MercadoPagoCheckout::Erro) { @servico.criar(@pedido) }
    assert_nil @pedido.reload.pagamento_order_id
    @http.codigo = "401"
    assert_raises(MercadoPagoCheckout::Erro) { @servico.criar(@pedido) }
    assert @pedido.reload.pendente?
  end

  test "confirma aprovacao somente com moeda total e ambiente corretos e tolera repeticoes" do
    @servico.criar(@pedido)
    @http.corpo = pagamento
    @servico.atualizar(@pedido.pagamento_order_id)
    assert @pedido.reload.pago?
    assert_equal "PAY01MAISON123", @pedido.pagamento_id
    assert_equal "pix", @pedido.pagamento_metodo
    instante = @pedido.pago_em
    @servico.atualizar(@pedido.pagamento_order_id)
    assert_equal instante, @pedido.reload.pago_em
    @pedido.update!(status: :enviado)
    @servico.atualizar(@pedido.pagamento_order_id)
    assert @pedido.reload.enviado?
  end

  test "aprova cartao em producao e rejeita checkout salvo em dominio estranho" do
    @config.update!(pagamento_teste: false)
    @http.corpo["id"] = "ORD01MAISON123"
    @http.corpo["checkout_url"] = "https://www.mercadopago.com.br/checkout/v1/redirect?order_id=ORD01MAISON123"
    assert_equal @http.corpo["checkout_url"], @servico.criar(@pedido)
    @http.corpo = pagamento
    @http.corpo["transactions"]["payments"][0]["payment_method"]["id"] = "visa"
    @servico.atualizar(@pedido.pagamento_order_id)
    assert @pedido.reload.pago?
    assert_equal "visa", @pedido.pagamento_metodo
    @pedido.update!(status: :pendente, pagamento_url: "https://malicioso.example")
    assert_raises(MercadoPagoCheckout::Erro) { @servico.criar(@pedido) }
  end

  test "nao aprova valor moeda ou ambiente divergente nem pagamento pendente" do
    @servico.criar(@pedido)
    [{ "total_amount" => "1.00" }, { "currency" => "USD" }, { "id" => "ORD01MAISON123" }, { "external_reference" => "outro" }, { "total_paid_amount" => "1.00" }].each do |alteracao|
      @http.corpo = pagamento.merge(alteracao)
      assert_raises(MercadoPagoCheckout::Erro) { @servico.atualizar(@pedido.pagamento_order_id) }
      assert @pedido.reload.pendente?
    end
    @http.corpo = pagamento.merge("status" => "processing")
    @servico.atualizar(@pedido.pagamento_order_id)
    assert @pedido.reload.pendente?
    assert_nil @pedido.pago_em
  end

  test "assinatura vincula id timestamp e request id" do
    ts = Time.current.to_i.to_s
    hash = OpenSSL::HMAC.hexdigest("SHA256", "assinatura-de-teste", "id:123;request-id:req-1;ts:#{ts};")
    args = { id: "123", request_id: "req-1", assinatura: "ts=#{ts},v1=#{hash}" }
    assert @servico.assinatura_valida?(**args)
    assert_not @servico.assinatura_valida?(**args.merge(id: "456"))
    assert_not @servico.assinatura_valida?(**args.merge(request_id: "outro"))
    assert_not @servico.assinatura_valida?(**args.merge(assinatura: ""))
  end

  test "assinatura de order preserva a caixa e rejeita id adulterado" do
    id = "ORDTST01MAISON123"
    hash = OpenSSL::HMAC.hexdigest("SHA256", "assinatura-de-teste", "id:#{id};request-id:req-order;ts:123456;")
    args = { id: id, request_id: "req-order", assinatura: "ts=123456,v1=#{hash}" }
    assert @servico.assinatura_valida?(**args)
    assert_not @servico.assinatura_valida?(**args.merge(id: id.downcase))
    assert_not @servico.assinatura_valida?(**args.merge(id: "../v1/orders"))
  end

  test "recusa credencial de producao em configuracao de teste" do
    @http.corpo["id"] = "ORD01PRODUCAO"
    assert_raises(MercadoPagoCheckout::Erro) { @servico.criar(@pedido) }
    assert_nil @pedido.reload.pagamento_order_id
  end

  test "reembolso parcial nao aprova pedido e exige conferencia" do
    @servico.criar(@pedido)
    @http.corpo = pagamento.merge("status_detail" => "partially_refunded")
    @servico.atualizar(@pedido.pagamento_order_id)
    assert @pedido.reload.pendente?
    assert @pedido.pagamento_requer_atencao?
  end

  test "nao consulta orders desconhecidas nem aprova uma transacao incompleta" do
    @servico.atualizar_order("ORDTST01DESCONHECIDA")
    assert_nil @http.requisicao
    @servico.criar(@pedido)
    @http.corpo = pagamento
    @http.corpo["transactions"]["payments"][0]["paid_amount"] = "1.00"
    assert_raises(MercadoPagoCheckout::Erro) { @servico.atualizar(@pedido.pagamento_order_id) }
    assert @pedido.reload.pendente?
  end

  test "segredos ficam criptografados e teste nao entra no faturamento" do
    bruto = Configuracao.connection.select_value("SELECT pagamento_token FROM configuracaos WHERE id = #{@config.id}")
    assert_not_includes bruto, "credencial-de-teste"
    @servico.criar(@pedido)
    @http.corpo = pagamento
    @servico.atualizar(@pedido.pagamento_order_id)
    resumo = ResumoVendas.new(inicio: Date.current, fim: Date.current)
    assert_equal 0, resumo.faturamento
  end

  test "aprovacao apos cancelamento exige conferencia sem reativar pedido" do
    @servico.criar(@pedido)
    @pedido.cancelar!(motivo: "Cancelamento conferido", cobranca_encerrada: true)
    @http.corpo = pagamento
    @servico.atualizar(@pedido.pagamento_order_id)
    assert @pedido.reload.cancelado?
    assert @pedido.pagamento_requer_atencao?
    assert_nil @pedido.pago_em
  end

  test "estorno exige conferencia e reserva vencida bloqueia checkout" do
    @pedido.update!(reserva_expira_em: 1.minute.ago)
    assert_raises(MercadoPagoCheckout::Erro) { @servico.criar(@pedido) }
    @pedido.update!(reserva_expira_em: 1.hour.from_now)
    @servico.criar(@pedido)
    @http.corpo = pagamento
    @servico.atualizar(@pedido.pagamento_order_id)
    @http.corpo = pagamento.merge("status" => "refunded")
    @servico.atualizar(@pedido.pagamento_order_id)
    assert @pedido.reload.pagamento_requer_atencao?
    assert @pedido.pago?
  end

  private

  def pagamento
    { "id" => @pedido.pagamento_order_id, "external_reference" => @pedido.pagamento_referencia,
      "type" => "online", "currency" => "BRL", "total_amount" => "120.00", "total_paid_amount" => "120.00",
      "status" => "processed", "status_detail" => "accredited",
      "transactions" => { "payments" => [{ "id" => "PAY01MAISON123", "status" => "processed", "status_detail" => "accredited",
        "paid_amount" => "120.00", "payment_method" => { "id" => "pix" } }] } }
  end
end
