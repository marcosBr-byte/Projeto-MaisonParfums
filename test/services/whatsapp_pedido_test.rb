require "test_helper"

class WhatsappPedidoTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  self.fixture_table_names = []

  setup do
    @ambiente = WhatsAppPedido::CHAVES.to_h { |chave| [ chave, ENV[chave] ] }
    ENV["WHATSAPP_ACCESS_TOKEN"] = "token-simulado"
    ENV["WHATSAPP_PHONE_NUMBER_ID"] = "123456789"
    ENV["WHATSAPP_API_VERSION"] = "v99.0"
    ENV["WHATSAPP_TEMPLATE_NAME"] = "pedido_novo"
    @configuracao = Configuracao.atual
    @configuracao.update!(whatsapp_notificacao: "+55 (83) 98838-3800", whatsapp_notificacoes_ativas: false)
    usuario = Usuario.create!(nome: "Teste", email: "whatsapp-test@example.com", telefone: "83999999999", password: "senha-teste-123")
    @pedido = usuario.pedidos.create!(status: :pendente, valor_total: 199)
  end

  teardown do
    @ambiente.each { |chave, valor| valor.nil? ? ENV.delete(chave) : ENV[chave] = valor }
  end

  class TransporteSimulado
    attr_reader :requisicao, :opcoes
    def initialize(codigo: "200", corpo: { messages: [ { id: "wamid.simulado" } ] }.to_json)
      @resposta = Struct.new(:code, :body).new(codigo, corpo)
    end
    def start(host, port, **opcoes)
      @opcoes = opcoes
      yield self
    end
    def request(requisicao)
      @requisicao = requisicao
      @resposta
    end
  end

  test "envia modelo com numero e valor sem dados pessoais" do
    http = TransporteSimulado.new
    assert_equal "wamid.simulado", WhatsAppPedido.enviar(@pedido, @configuracao, http: http)
    corpo = JSON.parse(http.requisicao.body)
    assert_equal "5583988383800", corpo["to"]
    assert_equal "template", corpo["type"]
    assert_equal [ @pedido.id.to_s, "R$ 199,00" ], corpo.dig("template", "components", 0, "parameters").map { |p| p["text"] }
    assert_equal true, http.opcoes[:use_ssl]
    assert_not_includes http.requisicao.body, @pedido.usuario.email
  end

  test "recusa configuracao ausente e respostas de erro" do
    assert_raises(WhatsAppPedido::Erro) { WhatsAppPedido.enviar(@pedido, @configuracao, http: TransporteSimulado.new(codigo: "401")) }
    assert_raises(WhatsAppPedido::Erro) { WhatsAppPedido.enviar(@pedido, @configuracao, http: TransporteSimulado.new(corpo: "invalido")) }
    ENV.delete("WHATSAPP_ACCESS_TOKEN")
    assert_not WhatsAppPedido.configurado?
    assert_not @configuracao.update(whatsapp_notificacoes_ativas: true)
  end

  test "confirmacao de pagamento agenda aviso quando integrado e ativado" do
    @configuracao.update!(whatsapp_notificacoes_ativas: true)
    assert_enqueued_with(job: NotificarPedidoWhatsappJob, args: [ @pedido.id ]) do
      @pedido.update!(status: :pago)
    end
  end

  test "pedido pendente cancelado ou de teste nao envia aviso" do
    @configuracao.update!(whatsapp_notificacoes_ativas: true)
    assert_no_enqueued_jobs do
      @pedido.agendar_aviso_whatsapp
      NotificarPedidoWhatsappJob.perform_now(@pedido.id)
      @pedido.update!(status: :cancelado)
      NotificarPedidoWhatsappJob.perform_now(@pedido.id)
      @pedido.update!(status: :pendente, pagamento_teste: true)
      @pedido.update!(status: :pago)
      NotificarPedidoWhatsappJob.perform_now(@pedido.id)
    end
    assert_nil @pedido.reload.whatsapp_notificado_em
  end

  test "criar pedido nao avisa e repeticao de confirmacao nao agenda de novo" do
    @configuracao.update!(whatsapp_notificacoes_ativas: true)
    assert_no_enqueued_jobs do
      @pedido.usuario.pedidos.create!(status: :pendente, valor_total: 50)
    end
    assert_enqueued_jobs 1, only: NotificarPedidoWhatsappJob do
      @pedido.update!(status: :pago)
      @pedido.update!(pagamento_status: "approved")
      @pedido.update!(status: :enviado)
    end
  end

  test "confirmacao real de Pix ou cartao agenda aviso apenas uma vez" do
    @configuracao.update!(whatsapp_notificacoes_ativas: true)
    %w[pix visa].each do |metodo|
      pedido = @pedido.usuario.pedidos.create!(status: :pendente, valor_total: 199,
        pagamento_preferencia: "pref-#{metodo}", pagamento_teste: false)
      pagamento_id = metodo == "pix" ? "123" : "456"
      pagamento = { id: pagamento_id.to_i, external_reference: pedido.pagamento_referencia,
        currency_id: "BRL", transaction_amount: 199, live_mode: true,
        status: "approved", payment_method_id: metodo }
      http = TransporteSimulado.new(corpo: pagamento.to_json)
      servico = MercadoPagoCheckout.new(@configuracao, http: http)
      assert_enqueued_with(job: NotificarPedidoWhatsappJob, args: [ pedido.id ]) do
        servico.atualizar(pagamento_id)
      end
      assert pedido.reload.pago?
      assert_no_enqueued_jobs { servico.atualizar(pagamento_id) }
    end
  end

  test "avisos desativados nao enfileiram e job nao envia" do
    assert_no_enqueued_jobs { @pedido.agendar_aviso_whatsapp }
    NotificarPedidoWhatsappJob.perform_now(@pedido.id)
    assert_nil @pedido.reload.whatsapp_notificado_em
  end

  test "job nao reenvia pedido que ja tem confirmacao" do
    @configuracao.update!(whatsapp_notificacoes_ativas: true)
    instante = Time.current
    @pedido.update!(status: :pago, whatsapp_notificado_em: instante, whatsapp_mensagem_id: "wamid.anterior")
    NotificarPedidoWhatsappJob.perform_now(@pedido.id)
    assert_equal "wamid.anterior", @pedido.reload.whatsapp_mensagem_id
  end
end
