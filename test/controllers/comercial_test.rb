require "test_helper"

class ComercialTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @configuracao = Configuracao.atual
    @configuracao.update!(desconto_ativo: true, desconto_percentual: 20, brinde_ativo: true, brinde_meta: 199, brinde_descricao: "Amostra especial")
    @usuario = Usuario.create!(nome: "Cliente", email: "comercial@example.com", telefone: "83999999999", password: "senha-teste-123",
      cep: "58000000", estado: "PB", cidade: "João Pessoa", bairro: "Centro", rua: "Rua teste", numero_casa: "1")
    @produto = Produto.create!(nome: "Perfume comercial", categoria: :masculino, fragancia: "Amadeirada", descricao: "<div><strong>Descrição formatada</strong></div>",
      variantes_attributes: [ { tamanho: :tamanho_10ml, preco: 100, estoque: 10 } ])
    @variante = @produto.variantes.first
    sign_in @usuario
  end

  def adicionar(quantidade)
    post adicionar_carrinho_path, params: { produto_id: @produto.id, variante_id: @variante.id, quantidade: quantidade }
    assert_redirected_to carrinho_path
  end

  test "atalhos flutuantes aparecem para visitantes e clientes e ficam fora do admin" do
    @configuracao.update!(whatsapp: "5585999999999", brinde_ativo: true)
    adicionar(1)
    get produto_path(@produto)
    assert_select "[data-floating-gift] summary", text: /119,00/
    assert_select '[data-floating-whatsapp][href="https://wa.me/5585999999999"]', count: 1
    get carrinho_path
    assert_select "[data-floating-gift] [data-brinde]", count: 1
    assert_select "[data-brinde]", count: 1
    sign_out @usuario
    get root_path
    assert_select "[data-floating-gift] summary", text: /199,00/
    assert_select "[data-floating-whatsapp]", count: 1
    assert_select "[data-brinde]", count: 1
    get produto_path(@produto)
    assert_select "[data-floating-gift]", count: 1
    @usuario.update!(role: :admin)
    sign_in @usuario
    get admin_configuracoes_path
    assert_select "[data-floating-gift]", count: 0
    assert_select "[data-floating-whatsapp]", count: 0
  end

  test "caminhao acompanha total com desconto e frete fica registrado no pedido" do
    @configuracao.update!(frete_gratis_ativo: true, frete_gratis_meta_nordeste: 160)
    get carrinho_path
    assert_select '[data-shipping-progress-percent-value="0.0"]'
    adicionar(1)
    get carrinho_path
    assert_select '[data-shipping-progress-percent-value="50.0"]'
    assert_select "[data-frete-gratis]", text: /Faltam.*80,00/m
    adicionar(1)
    get carrinho_path
    assert_select '[data-shipping-progress-percent-value="100.0"]'
    assert_select "[data-frete-gratis]", text: /Você ganhou frete grátis/
    post finalizar_carrinho_path
    assert @usuario.pedidos.last.frete_gratis?
    @configuracao.update!(frete_gratis_meta_nordeste: 500)
    assert @usuario.pedidos.last.frete_gratis?
  end

  test "frete depende do CEP e estado e respeita os limites regionais" do
    @configuracao.update!(frete_gratis_ativo: true, frete_gratis_meta_nordeste: 300, frete_gratis_meta: 400)
    assert_not @configuracao.frete_gratis_liberado?(299.99, cep: "58000-000", estado: "PB")
    assert @configuracao.frete_gratis_liberado?(300, cep: "58000-000", estado: "PB")
    assert_not @configuracao.frete_gratis_liberado?(399.99, cep: "01001000", estado: "SP")
    assert @configuracao.frete_gratis_liberado?(400, cep: "01001000", estado: "SP")
    assert_not @configuracao.frete_gratis_liberado?(1000, cep: "01001000", estado: "PB")
    assert_not @configuracao.frete_gratis_liberado?(1000, cep: "", estado: "PB")
    @usuario.update!(cep: nil)
    adicionar(5)
    get carrinho_path
    assert_select "[data-frete-gratis]", text: /Informe ou confira o CEP/
    assert_select "[data-shipping-progress-percent-value]", count: 0
    @usuario.update!(cep: "01001000", estado: "SP")
    post finalizar_carrinho_path
    assert @usuario.pedidos.last.frete_gratis?
  end

  test "frete pode ser desligado e meta precisa ser positiva" do
    @configuracao.update!(frete_gratis_ativo: false)
    get carrinho_path
    assert_select "[data-frete-gratis]", count: 0
    assert_not @configuracao.frete_gratis_liberado?(1000)
    assert_not @configuracao.update(frete_gratis_meta: 0)
  end

  test "precos promocionais volume borrifadas e editor aparecem nas paginas" do
    get produto_path(@produto)
    assert_response :success
    assert_select '[data-variante-target="preco"]', text: /80,00/
    assert_select '[data-variante-target="porMl"]', text: /8,00\/ml/
    assert_select '[data-variante-target="borrifadas"]', text: /160 borrifadas/
    assert_select "strong", text: "Descrição formatada"
    assert_select "header a[href=?] img[alt='Maison Parfum']", root_path
    assert_select 'input[name="produto[frasco_mae_id]"]', count: 0
  end

  test "brinde mostra valor restante e total promocional no carrinho" do
    adicionar(1)
    get carrinho_path
    assert_response :success
    assert_select "[data-brinde]", text: /119,00/
    assert_select "dt", text: /Desconto global/
    assert_select "dd", text: /20,00/
  end

  test "pedido preserva desconto brinde total e baixa de estoque" do
    adicionar(3)
    get carrinho_path
    assert_select "[data-brinde]", text: /Você ganhou um brinde/
    assert_difference "Pedido.count", 1 do
      post finalizar_carrinho_path
    end
    pedido = @usuario.pedidos.last
    assert_equal 300, pedido.subtotal
    assert_equal 240, pedido.valor_total
    assert_equal 60, pedido.desconto_valor
    assert_equal 80, pedido.itens_pedidos.first.preco_unitario
    assert pedido.brinde_incluso?
    assert_equal "Amostra especial", pedido.brinde_descricao
    assert_equal 7, @variante.reload.estoque
    @configuracao.update!(desconto_percentual: 50, brinde_descricao: "Outro brinde")
    assert_equal 240, pedido.reload.valor_total
    assert_equal "Amostra especial", pedido.brinde_descricao
    assert_no_difference "Pedido.count" do
      post finalizar_carrinho_path
    end
  end

  test "amostra promocional a partir de 199 e 99 e fica registrada no pedido" do
    @configuracao.update!(brinde_ativo: true, brinde_meta: 199.99, brinde_descricao: "1 amostra exclusiva da Maison Parfum")
    assert_not @configuracao.brinde_liberado?(199.98)
    assert @configuracao.brinde_liberado?(199.99)
    assert @configuracao.brinde_liberado?(200)
    sign_out @usuario
    get root_path
    assert_select "[data-floating-gift] summary span:last-child", text: "Faltam R$ 199,99 para ganhar uma amostra"
    sign_in @usuario
    @variante.update!(preco: 250)
    adicionar(1)
    get carrinho_path
    assert_select "[data-brinde]", text: /1 amostra exclusiva da Maison Parfum/
    assert_select "[data-brinde]", text: /incluído automaticamente/
    post finalizar_carrinho_path
    pedido = @usuario.pedidos.last
    assert pedido.brinde_incluso?
    assert_equal "1 amostra exclusiva da Maison Parfum", pedido.brinde_descricao
  end

  test "brinde considera limite exato e pode ser desligado" do
    assert_not @configuracao.brinde_liberado?(198.99)
    assert @configuracao.brinde_liberado?(199)
    @configuracao.update!(brinde_ativo: false)
    get carrinho_path
    assert_select "[data-brinde]", count: 0
  end

  test "administrador configura promocoes e editor sem frasco mae" do
    @usuario.update!(role: :admin)
    get admin_configuracoes_path
    assert_response :success
    assert_select 'input[name="configuracao[desconto_percentual]"]'
    assert_select 'input[name="configuracao[brinde_meta]"]'
    assert_select 'input[name="configuracao[borrifadas_por_ml]"]'
    assert_select "trix-editor"
    get edit_produto_path(@produto)
    assert_response :success
    assert_select 'select[name="produto[frasco_mae_id]"]', count: 0
    assert_select 'input[name$="[estoque]"]', count: 5
    patch admin_configuracoes_path, params: { configuracao: { desconto_percentual: 101, borrifadas_por_ml: 0 } }
    assert_response :unprocessable_entity
    assert_equal 20, @configuracao.reload.desconto_percentual
  end

  test "quiz considera desconto ao limitar orçamento" do
    quiz = PerfumeQuiz.new(categoria: "masculino", familias: [ "amadeirada" ], momento: "dia", intensidade: "qualquer", orcamento: "100")
    @variante.update!(preco: 120)
    resultado = RecomendadorPerfumes.new(quiz).resultados.first
    assert_equal 96, resultado.preco
  end

  test "volume do lacrado e opcional e estoque nao pode ser negativo" do
    lacrado = @produto.variantes.create!(tamanho: :lacrado, preco: 200, estoque: 1)
    assert_nil lacrado.preco_por_ml(@configuracao)
    lacrado.update!(volume_lacrado_ml: 100)
    assert_equal 1.6, lacrado.preco_por_ml(@configuracao)
    assert_not lacrado.update(estoque: -1)
  end
  test "faixa de beneficios usa alternancia automatica sem controles" do
    get root_path
    assert_response :success
    assert_select '.home-benefits[data-controller="benefits-carousel"]' do
      assert_select '[data-benefits-carousel-target="slide"]', count: 4
      assert_select '[data-benefits-carousel-target="slide"][hidden]', count: 0
      assert_select "button", count: 0
    end
  end
end
