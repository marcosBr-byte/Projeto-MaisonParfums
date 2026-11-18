require "test_helper"

class OperacaoPedidosTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @cliente = Usuario.create!(nome: "Cliente Entrega", email: "entrega@example.com", telefone: "85999999999", password: "senha-teste-123", rua: "Rua atual")
    @admin = Usuario.create!(nome: "Admin Entrega", email: "admin-entrega@example.com", telefone: "85999999999", password: "senha-teste-123", role: :admin)
    @produto = Produto.create!(nome: "Perfume Entrega", preco: 100, estoque: 8)
    @variante = @produto.variantes.create!(tamanho: :tamanho_5ml, preco: 100, estoque: 3)
    @pedido = @cliente.pedidos.create!(status: :pendente, valor_total: 200, rua: "Rua da compra", telefone_entrega: "85111111111")
    @pedido.itens_pedidos.create!(produto: @produto, variante: @variante, quantidade: 2, preco_unitario: 100)
    sign_in @admin
  end

  test "cliente nao pode gerenciar pedidos" do
    sign_in @cliente
    patch admin_pedido_path(@pedido), params: { pedido: { status: "enviado" } }
    post cancelar_admin_pedido_path(@pedido)
    post confirmar_pagamento_admin_pedido_path(@pedido), params: { recebimento_confirmado: "1" }
    assert @pedido.reload.pendente?
    assert_equal 3, @variante.reload.estoque
  end

  test "admin ve endereco congelado e entrega segue transicoes validas" do
    get admin_pedido_path(@pedido)
    assert_response :success
    assert_includes response.body, "Rua da compra"
    assert_not_includes response.body, "Rua atual"
    patch admin_pedido_path(@pedido), params: { pedido: { status: "entregue" } }
    assert @pedido.reload.pendente?
    post confirmar_pagamento_admin_pedido_path(@pedido), params: { recebimento_confirmado: "1" }
    assert @pedido.reload.pago?
    patch admin_pedido_path(@pedido), params: { pedido: { status: "enviado", transportadora: "Correios", codigo_rastreio: "BR123", prazo_entrega: "2026-12-01" } }
    assert @pedido.reload.enviado?
    assert @pedido.enviado_em
    sign_in @cliente
    get pagamento_pedido_path(@pedido)
    assert_includes response.body, "BR123"
    assert_includes response.body, "01/12/2026"
    sign_in @admin
    patch admin_pedido_path(@pedido), params: { pedido: { status: "entregue" } }
    assert @pedido.reload.entregue?
    assert @pedido.entregue_em
  end

  test "cancelamento devolve estoque uma unica vez e exige reembolso quando pago" do
    @pedido.update!(status: :pago)
    post cancelar_admin_pedido_path(@pedido)
    assert @pedido.reload.pago?
    assert_equal 3, @variante.reload.estoque
    2.times { post cancelar_admin_pedido_path(@pedido), params: { reembolso_confirmado: "1" } }
    assert @pedido.reload.cancelado?
    assert_equal 5, @variante.reload.estoque
  end

  test "reservas vencidas sem checkout expiram mas checkout externo exige conferencia" do
    @pedido.update!(reserva_expira_em: 1.minute.ago)
    2.times { ExpirarReservasJob.perform_now }
    assert @pedido.reload.cancelado?
    assert_equal 5, @variante.reload.estoque
    externo = @cliente.pedidos.create!(status: :pendente, valor_total: 100, reserva_expira_em: 1.minute.ago, pagamento_preferencia: "pref")
    ExpirarReservasJob.perform_now
    assert externo.reload.pendente?
    assert externo.pagamento_requer_atencao?
    post cancelar_admin_pedido_path(externo)
    assert externo.reload.pendente?
    post cancelar_admin_pedido_path(externo), params: { cobranca_encerrada: "1" }
    assert externo.reload.cancelado?
  end

  test "confirmacao manual nao substitui cobranca online e pedido novo tem prazo" do
    assert_in_delta 24.hours.from_now, @pedido.reserva_expira_em, 10
    @pedido.update!(pagamento_preferencia: "pref")
    post confirmar_pagamento_admin_pedido_path(@pedido), params: { recebimento_confirmado: "1" }
    assert @pedido.reload.pendente?
  end

  test "order impede confirmacao manual e devolucao automatica do estoque" do
    @pedido.update!(pagamento_order_id: "ORDTST01RESERVA", reserva_expira_em: 1.minute.ago)
    post confirmar_pagamento_admin_pedido_path(@pedido), params: { recebimento_confirmado: "1" }
    assert @pedido.reload.pendente?
    ExpirarReservasJob.perform_now
    assert @pedido.reload.pendente?
    assert @pedido.pagamento_requer_atencao?
    post cancelar_admin_pedido_path(@pedido)
    assert @pedido.reload.pendente?
    assert_equal 3, @variante.reload.estoque
    post cancelar_admin_pedido_path(@pedido), params: { cobranca_encerrada: "1" }
    assert @pedido.reload.cancelado?
    assert_equal 5, @variante.reload.estoque
  end
  test "frete fixo aparece e e cobrado mesmo sem checkout online" do
    Configuracao.atual.update!(pagamento_ativo: false, frete_pago_valor: 25, frete_gratis_ativo: false, desconto_ativo: false)
    sign_in @cliente
    @cliente.update!(cep: "60000000", estado: "CE", cidade: "Fortaleza", bairro: "Centro", numero_casa: "1")
    post adicionar_carrinho_path, params: { produto_id: @produto.id, variante_id: @variante.id, quantidade: 1 }
    get carrinho_path
    assert_select "p", text: /Produtos:.*100,00.*Frete:.*25,00/
    post finalizar_carrinho_path
    pedido = @cliente.pedidos.order(:id).last
    assert_equal 125, pedido.valor_total
    assert_equal 25, pedido.valor_frete
  end

end
