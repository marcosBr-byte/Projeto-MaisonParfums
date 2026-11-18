require "test_helper"

class ProdutosDestaqueTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @admin = Usuario.create!(nome: "Admin", email: "destaques@example.com", telefone: "85999999999", password: "senha-teste-123", role: :admin)
    @produto = Produto.create!(nome: "Perfume selecionado", categoria: :unissex, variantes_attributes: [{ tamanho: :tamanho_5ml, preco: 50, estoque: 5 }])
  end

  test "admin destaca produto sem vendas e pode retirar da home" do
    sign_in @admin
    get edit_produto_path(@produto)
    assert_response :success
    assert_select 'input[type="checkbox"][name="produto[destaque]"]'
    patch produto_path(@produto), params: { produto: { destaque: "1" } }
    assert @produto.reload.destaque?
    get root_path
    assert_response :success
    assert_select '#selecao-maison h4', text: @produto.nome
    patch produto_path(@produto), params: { produto: { destaque: "0" } }
    assert_not @produto.reload.destaque?
    get root_path
    assert_select '#selecao-maison', count: 0
  end

  test "visitante nao pode destacar produto" do
    patch produto_path(@produto), params: { produto: { destaque: "1" } }
    assert_not @produto.reload.destaque?
  end
end
