require "test_helper"

class LoginSocialControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    host! "localhost:3000"
    @test_mode = OmniAuth.config.test_mode
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(provider: "google_oauth2", uid: "google-123",
      info: { name: "Cliente Google", email: "google-login@example.com" }, extra: { raw_info: { email_verified: true } })
    OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new(provider: "facebook", uid: "facebook-123",
      info: { name: "Cliente Facebook", email: "facebook-login@example.com" })
  end

  teardown do
    OmniAuth.config.test_mode = @test_mode
    OmniAuth.config.mock_auth.delete(:google_oauth2)
    OmniAuth.config.mock_auth.delete(:facebook)
  end

  test "telas de login e cadastro oferecem botoes POST sem turbo" do
    [new_usuario_session_path, new_usuario_registration_path].each do |path|
      get path
      assert_response :success
      %w[google_oauth2 facebook].each do |provider|
        assert_select "form[action='/usuarios/auth/#{provider}'][method='post'][data-turbo='false'] button"
      end
    end
  end

  test "primeiro acesso social entra e encaminha ao perfil" do
    %w[google_oauth2 facebook].each do |provider|
      post "/usuarios/auth/#{provider}"
      assert_response :redirect
      follow_redirect!
      assert_redirected_to perfil_path
      follow_redirect!
      assert_response :success
      assert_select ".system-message", text: /Complete seu telefone e endereço/
      delete destroy_usuario_session_path
    end
  end

  test "cancelamento apresenta aviso em portugues sem criar conta" do
    OmniAuth.config.mock_auth[:google_oauth2] = :access_denied
    assert_no_difference "Usuario.count" do
      post "/usuarios/auth/google_oauth2"
      follow_redirect!
    end
    assert_redirected_to new_usuario_session_path
    follow_redirect!
    assert_select ".system-message[role='alert']", text: /Não foi possível concluir a conexão/
  end

  test "conecta conta existente pelo perfil e depois permite login" do
    usuario = Usuario.create!(nome: "Existente", email: "google-login@example.com", telefone: "85999999999", password: "senha-teste-123")
    sign_in usuario
    get perfil_path
    assert_select ".social-login__button", text: /Conectar Google/
    assert_no_difference "Usuario.count" do
      post "/usuarios/auth/google_oauth2"
      follow_redirect!
    end
    assert_redirected_to perfil_path
    assert_equal "google-123", usuario.identidades_sociais.sole.uid
    sign_out usuario
    post "/usuarios/auth/google_oauth2"
    follow_redirect!
    assert_redirected_to perfil_path
  end

  test "inicio real exige POST com token CSRF" do
    OmniAuth.config.test_mode = false
    protecao_anterior = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    post "/usuarios/auth/google_oauth2"
    assert_response :unprocessable_entity

    get new_usuario_session_path
    token = css_select("form[action='/usuarios/auth/google_oauth2'] input[name='authenticity_token']").first["value"]
    post "/usuarios/auth/google_oauth2", params: { authenticity_token: token }
    assert_response :redirect
    assert_equal "accounts.google.com", URI.parse(response.location).host
    assert URI.decode_www_form(URI.parse(response.location).query).to_h["state"].present?
  ensure
    ActionController::Base.allow_forgery_protection = protecao_anterior
  end

  test "coincidencia de email nao concede acesso" do
    Usuario.create!(nome: "Existente", email: "google-login@example.com", telefone: "85999999999", password: "senha-teste-123", role: :admin)
    assert_no_difference "IdentidadeSocial.count" do
      post "/usuarios/auth/google_oauth2"
      follow_redirect!
    end
    assert_redirected_to new_usuario_session_path
    get admin_path
    assert_redirected_to new_usuario_session_path
  end
end
