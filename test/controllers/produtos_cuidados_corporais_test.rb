require "test_helper"

class ProdutosCuidadosCorporaisTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  test "Body Splash e Hidratantes têm páginas próprias e aparecem no catálogo" do
    splash = criar_produto("Body Splash Baunilha", :body_splash)
    hidratante = criar_produto("Hidratante Baunilha", :hidratante)

    get body_splash_path
    assert_response :success
    assert_select "main a[href='#{produto_path(splash)}']"
    assert_select "main a[href='#{produto_path(hidratante)}']", count: 0

    get hidratantes_path
    assert_response :success
    assert_select "main a[href='#{produto_path(hidratante)}']"
    assert_select "main a[href='#{produto_path(splash)}']", count: 0

    get body_splash_path(publico: :masculino)
    assert_response :success
    assert_select "main a[href='#{body_splash_path(publico: :masculino)}'][aria-current=page]"
    assert_select "main a[href='#{produto_path(splash)}']"

    get body_splash_path(publico: :feminino)
    assert_response :success
    assert_select "main a[href='#{produto_path(splash)}']", count: 0

    get hidratantes_path(publico: :masculino)
    assert_response :success
    assert_select "main a[href='#{produto_path(hidratante)}']"

    get hidratantes_path(publico: :unissex)
    assert_response :success
    assert_select "main a[href='#{produto_path(hidratante)}']", count: 0

    get produtos_todos_path
    assert_response :success
    assert_select "main a[href='#{produto_path(splash)}']"
    assert_select "main a[href='#{produto_path(hidratante)}']"

    get produto_path(hidratante)
    assert_response :success
    assert_select "main a[href='#{hidratantes_path}']"
    assert_select ".product-sizes span", text: "200 ml"
    assert_select "[data-variante-target=borrifadas]", count: 0
    assert_select "form[action='#{adicionar_carrinho_path}']"
  end

  test "administrador cadastra os novos produtos com embalagem lacrada" do
    admin = Usuario.create!(nome: "Admin", email: "cuidados@example.com", password: "senha-teste-123", role: :admin)
    sign_in admin

    get new_produto_path
    assert_response :success
    assert_select 'select[name="produto[categoria]"] option[value=body_splash]', text: "Body Splash"
    assert_select 'select[name="produto[categoria]"] option[value=hidratante]', text: "Hidratantes"

    assert_select 'select[name="produto[publico]"] option[value=unissex]', text: "Unissex"

    %w[body_splash hidratante].each do |categoria|
      post produtos_path, params: { produto: { nome: "Produto #{categoria}", categoria: categoria, publico: "unissex",
        variantes_attributes: { "0" => { tamanho: "lacrado", volume_lacrado_ml: "200", preco: "60", estoque: "2" } } } }
      assert_redirected_to admin_path
      produto = Produto.find_by!(nome: "Produto #{categoria}", categoria: categoria)
      assert_equal "unissex", produto.publico
      assert_equal 200, produto.variantes.first.volume_ml
    end
  end

  private

  def criar_produto(nome, categoria)
    Produto.create!(nome: nome, categoria: categoria, publico: :masculino,
      variantes_attributes: [{ tamanho: :lacrado, volume_lacrado_ml: 200, preco: 60, estoque: 2 }])
  end
end
