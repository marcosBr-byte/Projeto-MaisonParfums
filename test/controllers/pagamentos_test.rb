require "test_helper"

class PagamentosTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @config = Configuracao.atual
    @config.update!(pagamento_ativo: true, pagamento_teste: true, pagamento_token: "token-pagamentos",
      pagamento_webhook_secret: "segredo-pagamentos", pagamento_site_url: "https://maison.example", frete_pago_valor: 25,
      desconto_ativo: false, frete_gratis_ativo: true, frete_gratis_meta_nordeste: 300)
    @cliente = Usuario.create!(nome: "Cliente Pix", email: "pix@example.com", telefone: "85999999999", password: "senha-teste-123",
      cep: "60000000", estado: "CE", cidade: "Fortaleza", bairro: "Centro", rua: "Teste", numero_casa: "1")
    @pedido = @cliente.pedidos.create!(status: :pendente, valor_total: 100)
    sign_in @cliente
  end

  test "somente administrador configura e segredos vazios mantem credenciais" do
    patch admin_configuracoes_path, params: { configuracao: { pagamento_token: "invasor" } }
    assert_equal "token-pagamentos", @config.reload.pagamento_token
    @cliente.update!(role: :admin)
    get admin_configuracoes_path
    assert_response :success
    assert_select 'input[type="password"][name="configuracao[pagamento_token]"][value=""]', count: 1
    assert_select 'input[type="password"][name="configuracao[pagamento_webhook_secret]"][value=""]', count: 1
    assert_select "input#mercado-pago-webhook[readonly]", count: 1
    assert_select 'input[type="tel"][name="configuracao[whatsapp_notificacao]"]', count: 1
    assert_no_match(/token-pagamentos|segredo-pagamentos/, response.body)
    patch admin_configuracoes_path, params: { configuracao: { pagamento_token: "", pagamento_webhook_secret: "", pagamento_teste: "0" } }
    assert_redirected_to admin_configuracoes_path
    assert_equal "token-pagamentos", @config.reload.pagamento_token
    assert_not @config.pagamento_teste?
  end

  test "configuracao incompleta nao permite ativar" do
    @cliente.update!(role: :admin)
    patch admin_configuracoes_path, params: { configuracao: { pagamento_site_url: "http://loja.example",
      pagamento_token: "novo-token-secreto", pagamento_webhook_secret: "nova-chave-secreta" } }
    assert_response :unprocessable_entity
    assert_no_match(/novo-token-secreto|nova-chave-secreta/, response.body)
  end

  test "cliente nao acessa cobranca de outro e retorno falso nao confirma pagamento" do
    outro = Usuario.create!(nome: "Outro", email: "outro-pix@example.com", telefone: "85999999999", password: "senha-teste-123")
    get pagamento_pedido_path(outro.pedidos.create!(status: :pendente, valor_total: 100))
    assert_response :not_found
    sign_in @cliente
    get pagamento_pedido_path(@pedido), params: { status: "approved", payment_id: "123" }
    assert_response :success
    assert @pedido.reload.pendente?
    assert_select "form[action=?]", pagar_pedido_path(@pedido)
    sign_out @cliente
    post pagar_pedido_path(@pedido)
    assert_redirected_to new_usuario_session_path
  end

  test "admin nao agenda aviso para pedido pendente ou teste" do
    @cliente.update!(role: :admin)
    assert_no_enqueued_jobs do
      post notificar_whatsapp_admin_pedido_path(@pedido)
    end
    assert_redirected_to admin_pedido_path(@pedido)
    follow_redirect!
    assert_select ".system-message", text: /apenas para pedidos com pagamento confirmado/
    assert_select "form[action=?]", notificar_whatsapp_admin_pedido_path(@pedido), count: 0
  end

  test "notificacao sem assinatura nao altera pedido" do
    post mercado_pago_webhook_path, params: { type: "payment", data: { id: "123" } }, as: :json
    assert_response :unauthorized
    assert @pedido.reload.pendente?
  end

  test "webhook order assinado ignora estados enviados pelo navegador" do
    id = "ORDTST01DESCONHECIDA"
    assinatura = OpenSSL::HMAC.hexdigest("SHA256", "segredo-pagamentos", "id:#{id};request-id:req-order;ts:123456;")
    headers = { "x-request-id" => "req-order", "x-signature" => "ts=123456,v1=#{assinatura}" }
    post "#{mercado_pago_webhook_path}?data.id=#{id}&type=order", headers: headers,
      params: { type: "order", data: { id: id, status: "processed", external_reference: @pedido.pagamento_referencia } }, as: :json
    assert_response :ok
    assert @pedido.reload.pendente?
    post "#{mercado_pago_webhook_path}?data.id=ORDTST01ADULTERADA&type=order", headers: headers, params: {}, as: :json
    assert_response :unauthorized
  end

  test "retoma checkout existente sem criar outro pedido" do
    @pedido.update!(pagamento_preferencia: "pref-123", pagamento_teste: true,
      pagamento_url: "https://sandbox.mercadopago.com.br/checkout/v1/redirect?pref_id=123")
    assert_no_difference "Pedido.count" do
      post pagar_pedido_path(@pedido)
    end
    assert_response :see_other
    assert_redirected_to "https://sandbox.mercadopago.com.br/checkout/v1/redirect?pref_id=123"
  end

  test "falha permite tentar pagar novamente pelo mesmo pedido" do
    @config.update!(pagamento_ativo: false)
    assert_no_difference "Pedido.count" do
      post pagar_pedido_path(@pedido)
    end
    assert_redirected_to pagamento_pedido_path(@pedido)
    assert @pedido.reload.pendente?
  end

  test "finalizar soma frete configurado e encaminha para pagamento sem aprovar" do
    produto = Produto.create!(nome: "Perfume Pix", categoria: :unissex, variantes_attributes: [ { tamanho: :tamanho_5ml, preco: 100, estoque: 10 } ])
    variante = produto.variantes.first
    post adicionar_carrinho_path, params: { produto_id: produto.id, variante_id: variante.id, quantidade: 1 }
    get carrinho_path
    assert_select "p", text: /Produtos:.*100,00.*Frete:.*25,00/
    post finalizar_carrinho_path
    pedido = @cliente.pedidos.order(:id).last
    assert_redirected_to pagamento_pedido_path(pedido)
    assert_equal 125, pedido.valor_total
    assert_equal 25, pedido.valor_frete
    assert pedido.pendente?
    get perfil_path
    assert_select "a[href=?]", pagamento_pedido_path(pedido)
  end
end
