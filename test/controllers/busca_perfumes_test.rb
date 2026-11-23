require "test_helper"

class BuscaPerfumesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @perfume = Produto.create!(nome: "Éclat de Sândalo", marca: "Maison Árabe", categoria: :masculino,
      origem: "arabe", fragancia: "Amadeirada", variantes_attributes: [ { tamanho: :tamanho_5ml, preco: 50, estoque: 5 } ])
    @outro = Produto.create!(nome: "Rosa", marca: "Outra", categoria: :feminino, origem: "importado",
      fragancia: "Floral", variantes_attributes: [ { tamanho: :tamanho_5ml, preco: 40, estoque: 3 } ])
  end

  test "busca ignora acentos e combina nome marca categoria origem e fragrancia" do
    [ "eclat", "SANDALO", "arabes masculino", "maison amadeirado", "masculino eclat" ].each do |termo|
      get busca_path(q: termo)
      assert_response :success
      assert_select ".catalog-card[href='#{produto_path(@perfume)}']", count: 1
      assert_select ".catalog-card[href='#{produto_path(@outro)}']", count: 0
    end
    get busca_path(q: "sandalo floral")
    assert_select ".catalog-card", count: 0
  end

  test "catalogo oferece busca e ordena nomes com acentos entre categorias" do
    get produtos_todos_path
    assert_response :success
    assert_select "form[action='#{busca_path}'] #busca-catalogo"
    assert_select "main .catalog-card" do |cards|
      assert_equal [ produto_path(@perfume), produto_path(@outro) ], cards.map { |card| card["href"] }
    end

    get produtos_todos_path(visualizacao: "categorias")
    assert_response :success
    assert_select "section h2", text: "Decantes Masculinos"
    assert_select "section h2", text: "Decantes Femininos"
  end

  test "caracteres especiais nao viram curingas e a busca vazia nao lista o catalogo" do
    [ "%", "_", "' OR 1=1 --", "" ].each do |termo|
      get busca_path(q: termo)
      assert_response :success
      assert_select ".catalog-card", count: 0
    end
  end

  test "admin pesquisa e edita produtos pela lista em ordem alfabetica" do
    sign_in Usuario.create!(nome: "Admin", email: "busca-admin@example.com", telefone: "85999999999", password: "senha-teste-123", role: :admin)

    get produtos_path
    assert_response :success
    assert_select "tbody a", text: "Editar" do |links|
      assert_equal [ edit_produto_path(@perfume), edit_produto_path(@outro) ], links.map { |link| link["href"] }
    end

    get produtos_path(q: "maison arabe")
    assert_response :success
    assert_select "#busca-produtos-admin[value='maison arabe']"
    assert_select "tbody a[href='#{edit_produto_path(@perfume)}']"
    assert_select "tbody a[href='#{edit_produto_path(@outro)}']", count: 0

    get produtos_path(q: "inexistente")
    assert_response :success
    assert_select "h2", text: "Nenhum produto encontrado"
    assert_select "a[href='#{produtos_path}']", text: "Limpar busca"
  end

  test "sugestoes mostram produto marca e preco e estao disponiveis no celular" do
    get busca_sugestoes_path(q: "eclat masculino")
    assert_response :success
    assert_select "a[href='#{produto_path(@perfume)}']", text: /Maison Árabe/
    assert_includes response.body, "50,00"
    get root_path
    assert_select '#busca-mobile[data-busca-target="input"]'
    assert_select "#busca-mobile-sugestoes"
    assert_select '#busca-desktop[data-busca-target="input"]'
  end
end
