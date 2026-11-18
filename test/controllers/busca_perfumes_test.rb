require "test_helper"

class BuscaPerfumesTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @perfume = Produto.create!(nome: "Éclat de Sândalo", marca: "Maison Árabe", categoria: :masculino,
      origem: "arabe", fragancia: "Amadeirada", variantes_attributes: [{ tamanho: :tamanho_5ml, preco: 50, estoque: 5 }])
    @outro = Produto.create!(nome: "Rosa", marca: "Outra", categoria: :feminino, origem: "importado",
      fragancia: "Floral", variantes_attributes: [{ tamanho: :tamanho_5ml, preco: 40, estoque: 3 }])
  end

  test "busca ignora acentos e combina nome marca categoria origem e fragrancia" do
    ["eclat", "SANDALO", "arabes masculino", "maison amadeirado", "masculino eclat"].each do |termo|
      get busca_path(q: termo)
      assert_response :success
      assert_select ".catalog-card[href='#{produto_path(@perfume)}']", count: 1
      assert_select ".catalog-card[href='#{produto_path(@outro)}']", count: 0
    end
    get busca_path(q: "sandalo floral")
    assert_select ".catalog-card", count: 0
  end

  test "caracteres especiais nao viram curingas e a busca vazia nao lista o catalogo" do
    ["%", "_", "' OR 1=1 --", ""].each do |termo|
      get busca_path(q: termo)
      assert_response :success
      assert_select ".catalog-card", count: 0
    end
  end

  test "sugestoes mostram produto marca e preco e estao disponiveis no celular" do
    get busca_sugestoes_path(q: "eclat masculino")
    assert_response :success
    assert_select "a[href='#{produto_path(@perfume)}']", text: /Maison Árabe/
    assert_includes response.body, "50,00"
    get root_path
    assert_select '#busca-mobile[data-busca-target="input"]'
    assert_select '#busca-mobile-sugestoes'
    assert_select '#busca-desktop[data-busca-target="input"]'
  end
end
