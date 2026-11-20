require "test_helper"

class ProdutoOrigemFiltrosTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    %w[feminino masculino unissex].each do |categoria|
      Produto::ORIGENS.each_key do |origem|
        Produto.create!(nome: "Perfume #{categoria} #{origem}", categoria: categoria, origem: origem,
          variantes_attributes: [ { tamanho: "tamanho_5ml", preco: 20, estoque: 5 } ])
      end
    end
  end

  test "menu aponta para origem dentro de cada categoria" do
    get root_path
    [ decants_femininos_path, decants_masculinos_path, decants_unissex_path ].each do |path|
      assert_select "a[href='#{path}?origem=arabe']", text: "Árabes"
      assert_select "a[href='#{path}?origem=importado']", text: "Importados"
    end
  end

  test "listas filtram categoria e origem sem receber produtos de outra origem por stream" do
    { feminino: decants_femininos_path, masculino: decants_masculinos_path, unissex: decants_unissex_path }.each do |categoria, path|
      Produto::ORIGENS.each_key do |origem|
        get path, params: { origem: origem }
        assert_response :success
        Produto.all.each do |produto|
          assert_select "#produtos a[href='#{produto_path(produto)}']", count: (produto.categoria == categoria.to_s && produto.origem == origem ? 1 : 0)
        end
        assert_select "turbo-cable-stream-source", count: 0
      end
      get path
      assert_response :success
      assert_select "#produtos a[href]", count: Produto::ORIGENS.size
    end
  end
end
