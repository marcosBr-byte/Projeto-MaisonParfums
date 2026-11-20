require "test_helper"

class BannersLojaTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @banner = Banner.create!(chave: "mais_vendidos", ordem: 2)
    @admin = Usuario.create!(nome: "Admin", email: "banners@example.com", telefone: "85999999999",
      password: "senha-teste-123", role: :admin)
  end

  test "atalhos circulares permitem foto ordem e desativacao pelo admin" do
    get root_path
    assert_select ".home-category-shortcut", count: 3
    assert_select "#destaques", count: 0
    assert_select ".home-category-shortcut", text: "Mais Vendidos", count: 0
    assert_select ".home-category-shortcut[href=?]", decants_nicho_path
    sign_in @admin
    get admin_customizar_path
    atalho = Banner.find_by!(chave: "atalho_nicho")
    patch admin_atualizar_banner_path(atalho), params: { banner: { ordem: 0, ativo: "1", imagem: fixture_file_upload(Rails.root.join("app/assets/images/slide-frete.jpeg"), "image/jpeg") } }
    assert_redirected_to admin_customizar_path
    get root_path
    assert_select ".home-category-shortcut:first-child[href=?] img", decants_nicho_path
    assert_select "#secao-carrossel img", count: 1
    patch admin_atualizar_banner_path(atalho), params: { banner: { ativo: "0" } }
    get root_path
    assert_select ".home-category-shortcut", count: 2
    assert_select ".home-category-shortcut[href=?]", decants_nicho_path, count: 0
  end

  test "personalizacao oferece videos e fotos de colecoes sem a antiga foto de experiencia" do
    sign_in @admin
    get admin_customizar_path
    assert_response :success
    assert_not Banner.find_by!(chave: "nicho").ativo?
    assert_select "#videos-home"
    assert_select "h2", text: "Foto da seção Uma experiência em cada fragrância", count: 0
    get root_path
    assert_response :success
    assert_select "#video img", count: 0
    assert_select "#video video", count: VideoHome.ativos.count
    assert_select "#busca-mobile", count: 1
  end

  test "colecao nicho usa foto enviada e link correto" do
    banner = Banner.create!(chave: "nicho", ordem: 6, ativo: true)
    get root_path
    assert_select "#secao-decants", count: 0
    banner.imagem.attach(io: File.open(Rails.root.join("app/assets/images/slide-frete.jpeg")), filename: "nicho.jpeg", content_type: "image/jpeg")
    get root_path
    assert_response :success
    assert_select "#secao-decants a[href=?] img", decants_nicho_path
    assert_select "#secao-carrossel img", count: 1
  end

  test "personalizacao salva imagem sem titulo ou subtitulo" do
    sign_in @admin
    get admin_customizar_path
    assert_select 'input[name="banner[titulo]"]', count: 0
    assert_select 'input[name="banner[subtitulo]"]', count: 0
    patch admin_atualizar_banner_path(@banner), params: { banner: {
      ordem: 1, imagem: fixture_file_upload(Rails.root.join("app/assets/images/slide-frete.jpeg"), "image/jpeg")
    } }
    assert_redirected_to admin_customizar_path
    get root_path
    assert_response :success
    assert_select "#secao-carrossel h2, #secao-carrossel p", count: 0
    assert_select '#secao-carrossel img[alt="Destaques da loja"]' do |images|
      assert_equal foto_path(chave: @banner.reload.imagem.blob.key, tamanho: :banner), images.first["src"]
    end
  end

  test "respeita ordem e nao exibe banners desativados" do
    Banner.create!(chave: "frete", ordem: 1)
    Banner.create!(chave: "quiz", ordem: 3, ativo: false)
    get root_path
    assert_response :success
    assert_select "#secao-carrossel img" do |imagens|
      assert_equal [ "Envio para o Brasil", "Destaques da loja" ], imagens.map { |i| i["alt"] }
    end
    assert_select 'button[data-action="carousel#next"]', count: 0
    assert_select '[data-carousel-target="dot"]', count: 2
  end

  test "colecoes mostram imagem sem texto e somem quando desativadas" do
    banner = Banner.create!(chave: "masculino", titulo: "Antigo titulo", subtitulo: "Antigo subtitulo", ordem: 4)
    get root_path
    assert_select "#secao-decants h2, #secao-decants p", count: 0
    assert_select "#secao-decants a[href=?] img", decants_masculinos_path
    banner.update!(ativo: false)
    get root_path
    assert_select "#secao-decants", count: 0
  end

  test "ordem invalida com upload mostra erro sem quebrar previa" do
    sign_in @admin
    patch admin_atualizar_banner_path(@banner), params: { banner: {
      ordem: -1, imagem: fixture_file_upload(Rails.root.join("app/assets/images/slide-frete.jpeg"), "image/jpeg")
    } }
    assert_response :unprocessable_entity
    assert_select '[role="alert"]'
    assert_not @banner.reload.imagem.attached?
  end

  test "upload invalido preserva a previa da imagem anterior" do
    @banner.imagem.attach(io: File.open(Rails.root.join("app/assets/images/slide-frete.jpeg")), filename: "anterior.jpeg", content_type: "image/jpeg")
    anterior = @banner.imagem.blob_id
    sign_in @admin
    patch admin_atualizar_banner_path(@banner), params: { banner: {
      ordem: -1, imagem: fixture_file_upload(Rails.root.join("app/assets/images/slide-quiz.jpeg"), "image/jpeg")
    } }
    assert_response :unprocessable_entity
    assert_select '[role="alert"]'
    assert_equal anterior, @banner.reload.imagem.blob_id
  end

  test "sem banners ativos nao exibe carrossel" do
    @banner.update!(ativo: false)
    get root_path
    assert_response :success
    assert_select "#secao-carrossel", count: 0
  end

  test "banner do quiz permanece clicavel sem texto sobre a imagem" do
    Banner.create!(chave: "quiz", ordem: 3)
    get root_path
    assert_select '#secao-carrossel a[href=?][aria-label="Descobrir meu perfume"]', quiz_path
    assert_select "#secao-carrossel h2, #secao-carrossel p", count: 0
  end
end
