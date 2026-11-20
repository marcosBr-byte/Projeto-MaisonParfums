require "test_helper"

class AdminAnalisesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveSupport::Testing::TimeHelpers
  self.fixture_table_names = []

  setup do
    travel_to Time.utc(2026, 11, 12, 15)
    @admin = Usuario.create!(nome: "Admin", email: "analises@example.com", telefone: "83999999999", password: "senha-teste-123", role: :admin)
    @produto = Produto.create!(nome: "Perfume em alta", variantes_attributes: [ { tamanho: :lacrado, preco: 50, estoque: 2 } ])
    @pago = @admin.pedidos.create!(status: :pago, valor_total: 100, desconto_valor: 10, brinde_incluso: true)
    @pago.itens_pedidos.create!(produto: @produto, variante: @produto.variantes.first, quantidade: 2, preco_unitario: 50)
    @admin.pedidos.create!(status: :enviado, valor_total: 40)
    @admin.pedidos.create!(status: :entregue, valor_total: 60)
    @admin.pedidos.create!(status: :pendente, valor_total: 300)
    @admin.pedidos.create!(status: :cancelado, valor_total: 500)
    sign_in @admin
  end

  teardown { travel_back }

  test "painel mostra vendas confirmadas e links uteis" do
    get admin_path
    assert_response :success
    assert_select '[data-indicador="receita-mes"]', text: /200,00/
    assert_select '[data-indicador="ticket-mes"]', text: /66,67/
    assert_select "a[href=?]", admin_pedidos_path(status: "pendente")
    assert_select "a[href=?]", admin_pedido_path(@pago)
    assert_select '[data-controller="grafico-vendas"]'
  end

  test "analise mostra dados do mes produtos em alta e dia selecionado" do
    get admin_analisar_path(data: "2026-11-12")
    assert_response :success
    assert_select '[data-indicador="receita-mes"]', text: /200,00/
    assert_select '[data-indicador="pendente-mes"]', text: /300,00/
    assert_select "[data-resumo-dia]", text: /200,00/
    assert_select "a", text: "Perfume em alta"
    assert_select 'a[aria-current="date"]', count: 1
  end

  test "mudar mes corrige data selecionada fora do periodo" do
    get admin_analisar_path(mes: "2026-10", data: "2026-11-12")
    assert_response :success
    assert_select 'input[name="data"][value="2026-10-01"]'
    assert_select '[data-indicador="receita-mes"]', text: /0,00/
  end

  test "datas invalidas e formato adulterado recebem resposta amigavel" do
    [ { mes: "2026-99" }, { data: "2026-02-30" }, { mes: [ "2026-11" ] }, { mes: "9999-01" } ].each do |parametros|
      get admin_analisar_path, params: parametros
      assert_redirected_to admin_analisar_path
    end
  end

  test "resumo agrupa pedidos pela data de Fortaleza e preenche dias sem pedido" do
    noturno = @admin.pedidos.create!(status: :pago, valor_total: 25, created_at: Time.utc(2026, 11, 12, 2, 30))
    resumo = ResumoVendas.new(inicio: Date.new(2026, 11, 11), fim: Date.new(2026, 11, 12))
    assert_equal [ 1, 5 ], resumo.evolucao.map { |linha| linha[:pedidos] }
    assert_equal [ 25, 200 ], resumo.evolucao.map { |linha| linha[:receita] }
    assert_equal 225, resumo.faturamento
    assert_equal 56.25, resumo.ticket_medio
  end

  test "cliente nao acessa painel nem analise" do
    @admin.update!(role: :cliente)
    get admin_path
    assert_redirected_to root_path
    get admin_analisar_path
    assert_redirected_to root_path
  end
end
