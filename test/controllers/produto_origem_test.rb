require "test_helper"

class ProdutoOrigemTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    sign_in Usuario.create!(nome: "Admin", email: "origem@example.com", telefone: "85999999999", password: "senha-teste-123", role: :admin)
  end

  test "admin cadastra perfume de nicho de qualquer marca e ele aparece na loja" do
    get new_produto_path
    assert_select "select[name='produto[categoria]'] option[value='nicho']", text: "Nicho"
    post produtos_path, params: { produto: { nome: "Nicho exclusivo", marca: "Outra marca", categoria: "nicho", origem: "xerjoff",
      variantes_attributes: [{ tamanho: "tamanho_5ml", preco: 90, estoque: 5 }] } }
    assert_redirected_to admin_path
    produto = Produto.find_by!(nome: "Nicho exclusivo")
    assert_equal "xerjoff", produto.origem
    sign_out :usuario
    get decants_nicho_path
    assert_response :success
    assert_select "a[href='#{produto_path(produto)}']", text: /Nicho exclusivo/
    get produto_path(produto)
    assert_response :success
    assert_select 'input[type="submit"][value="Comprar"]'
    sign_in Usuario.find_by!(email: "origem@example.com")
    patch produto_path(produto), params: { produto: { categoria: "unissex", origem: "importado" } }
    assert_redirected_to admin_path
    get decants_nicho_path
    assert_select "a[href='#{produto_path(produto)}']", count: 0
  end

  test "origens respeitam a categoria e a vitrine filtra as marcas de nicho" do
    Produto::ORIGENS_NICHO.each do |origem, nome|
      post produtos_path, params: { produto: { nome: "Nicho #{nome}", categoria: "nicho", origem: origem,
        variantes_attributes: [{ tamanho: "tamanho_5ml", preco: 80, estoque: 3 }] } }
      assert_redirected_to admin_path
    end
    produto = Produto.find_by!(origem: "nishane")
    get edit_produto_path(produto)
    assert_select "select[name='produto[origem]'] option[value='nishane'][selected]"
    assert_select "select[name='produto[origem]'] option[value='arabe']", count: 0
    patch produto_path(produto), params: { produto: { origem: "arabe" } }
    assert_response :unprocessable_entity
    assert_equal "nishane", produto.reload.origem
    patch produto_path(produto), params: { produto: { categoria: "feminino", origem: "sospiro" } }
    assert_response :unprocessable_entity
    assert produto.reload.nicho?
    Produto::ORIGENS_NICHO.each_key do |origem|
      get decants_nicho_path(origem: origem)
      assert_response :success
      Produto.nicho.each do |item|
        assert_select "a[href='#{produto_path(item)}']", count: (item.origem == origem ? 1 : 0)
      end
    end
    get produtos_todos_path
    assert_select "a[href='#{produto_path(produto)}']"
  end

  test "admin cadastra origem e altera na edicao" do
    get new_produto_path
    assert_response :success
    assert_select "select[name='produto[origem]']" do
      assert_select "option[value='arabe']", text: "Árabes"
      assert_select "option[value='importado']", text: "Importados"
    end

    post produtos_path, params: { produto: { nome: "Perfume árabe", origem: "arabe",
      variantes_attributes: [{ tamanho: "lacrado", preco: 100, estoque: 5 }] } }
    assert_redirected_to admin_path
    produto = Produto.find_by!(nome: "Perfume árabe")
    assert_equal "arabe", produto.origem

    get edit_produto_path(produto)
    assert_response :success
    assert_select "select[name='produto[origem]'] option[value='arabe'][selected]"

    patch produto_path(produto), params: { produto: { origem: "importado" } }
    assert_redirected_to admin_path
    assert_equal "importado", produto.reload.origem

    patch produto_path(produto), params: { produto: { origem: "invalida" } }
    assert_response :unprocessable_entity
    assert_equal "importado", produto.reload.origem
  end
end
