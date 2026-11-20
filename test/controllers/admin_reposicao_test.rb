require "test_helper"

class AdminReposicaoTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    sign_in Usuario.create!(nome: "Admin", email: "reposicao@example.com", role: :admin, password: "senha-teste-123")
  end

  test "inicio mostra foto nome categoria marca e tamanhos com estoque baixo sem duplicar produto" do
    produto = Produto.create!(nome: "Perfume para repor", marca: "Maison", categoria: :unissex,
      variantes_attributes: [ { tamanho: :tamanho_5ml, preco: 50, estoque: 0 }, { tamanho: :tamanho_10ml, preco: 80, estoque: 4 }, { tamanho: :tamanho_15ml, preco: 100, estoque: 5 } ])
    produto.imagem.attach(io: File.open(Rails.root.join("public/icon.png")), filename: "perfume.png", content_type: "image/png")
    regular = Produto.create!(nome: "Estoque suficiente", variantes_attributes: [ { tamanho: :lacrado, preco: 90, estoque: 9 } ])
    get admin_path
    assert_response :success
    assert_select "#reposicao [data-reposicao-produto='#{produto.id}']", count: 1 do
      assert_select 'img[alt="Perfume para repor"]'
      assert_select "a", text: "Perfume para repor"
      assert_select "p", text: "Categoria: Unissex"
      assert_select "p", text: "Marca: Maison"
      assert_select "li", text: /5ml · 0 unidades/
      assert_select "li", text: /10ml · 4 unidades/
      assert_select "li", text: /15ml/, count: 0
      assert_select "a[href=?]", edit_produto_path(produto), text: "Repor estoque →"
    end
    assert_select "#reposicao [data-reposicao-produto='#{regular.id}']", count: 0
  end

  test "inicio mostra estado vazio quando nao ha estoque baixo" do
    get admin_path
    assert_response :success
    assert_select "#reposicao", text: /Nenhum produto precisa de reposição/
  end
end
