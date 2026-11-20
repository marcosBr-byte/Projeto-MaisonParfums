require "test_helper"

class CatalogoTest < ActionDispatch::SystemTestCase
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  driven_by :selenium, using: :headless_chrome, screen_size: [ 390, 844 ] do |options|
    options.add_argument("--no-sandbox") if Process.uid.zero?
    options.binary = ENV["SE_BROWSER_PATH"] if ENV["SE_BROWSER_PATH"].present?
  end

  test "salva notas digitadas no painel e mostra a piramide na loja" do
    admin = Usuario.create!(nome: "Admin", email: "catalogo-admin@example.com",
      telefone: "85999999999", password: "senha-teste-123", role: :admin)
    produto = Produto.create!(nome: "Perfume de teste", categoria: :feminino,
      variantes_attributes: [ { tamanho: :tamanho_5ml, preco: 75, estoque: 5 } ])

    sign_in admin
    visit edit_produto_path(produto)
    fill_in "notas-nomes-topo", with: "Pera, Limão"
    fill_in "notas-nomes-coracao", with: "Frésia"
    within find_field("notas-nomes-coracao").ancestor("fieldset") do
      click_button "Aplicar nomes à seleção"
      assert_field "Nome da nota", with: "Frésia"
      assert_field "notas-nomes-coracao", with: ""
    end
    find("form[action='#{produto_path(produto)}'] input[type=submit]").click
    assert_current_path admin_path, wait: 10

    sign_out admin
    visit produto_path(produto)
    within "#notas-olfativas" do
      assert_selector "figcaption", exact_text: "Pera", count: 1
      assert_selector "figcaption", exact_text: "Limão", count: 1
      assert_selector "figcaption", exact_text: "Frésia", count: 1
    end

    [ 360, 768, 1440 ].each do |largura|
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
        width: largura, height: 900, deviceScaleFactor: 1, mobile: largura < 768)
      assert_selector "#notas-olfativas"
      assert_equal largura, page.evaluate_script("window.innerWidth")
      assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, largura
    end
  end
end
