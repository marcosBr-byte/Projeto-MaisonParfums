require "test_helper"

class LoginSocialTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "cria cliente social sem telefone e exige dados para comprar" do
    usuario = LoginSocial.autenticar(auth)
    assert usuario.persisted?
    assert usuario.cliente?
    assert_nil usuario.telefone
    assert_not usuario.perfil_completo?
    assert_equal 1, usuario.identidades_sociais.count
    assert usuario.valid_password?("senha-impossivel") == false
    assert_equal usuario, LoginSocial.autenticar(auth)
  end

  test "facebook cria conta com email autorizado" do
    usuario = LoginSocial.autenticar(auth(provider: "facebook"))
    assert_equal "facebook", usuario.identidades_sociais.sole.provider
    assert usuario.cliente?
  end

  test "nao permite cadastro sem email nem email google sem verificacao" do
    assert_no_difference [ "Usuario.count", "IdentidadeSocial.count" ] do
      assert_raises(LoginSocial::Erro) { LoginSocial.autenticar(auth(email: "")) }
      assert_raises(LoginSocial::Erro) { LoginSocial.autenticar(auth(verified: false)) }
      assert_raises(LoginSocial::Erro) { LoginSocial.autenticar(nil) }
    end
  end

  test "email existente inclusive admin nao e vinculado automaticamente" do
    usuario = Usuario.create!(nome: "Admin", email: "social@example.com", telefone: "85999999999", password: "senha-teste-123", role: :admin)
    assert_no_difference [ "Usuario.count", "IdentidadeSocial.count" ] do
      assert_raises(LoginSocial::Erro) { LoginSocial.autenticar(auth) }
    end
    assert usuario.reload.admin?
  end

  test "usuario autenticado conecta ambos provedores sem perder seu cadastro" do
    usuario = Usuario.create!(nome: "Cliente", email: "social@example.com", telefone: "85999999999", password: "senha-teste-123")
    assert_equal usuario, LoginSocial.autenticar(auth, usuario_atual: usuario)
    assert_equal usuario, LoginSocial.autenticar(auth(provider: "facebook"), usuario_atual: usuario)
    assert_equal 2, usuario.identidades_sociais.count
    assert_equal usuario, LoginSocial.autenticar(auth(provider: "facebook"))
  end

  test "identidade nao pode ser transferida para outro usuario" do
    usuario = LoginSocial.autenticar(auth)
    outro = Usuario.create!(nome: "Outro", email: "outro-social@example.com", telefone: "85999999999", password: "senha-teste-123")
    assert_raises(LoginSocial::Erro) { LoginSocial.autenticar(auth, usuario_atual: outro) }
    assert_equal usuario.id, IdentidadeSocial.sole.usuario_id
  end

  test "cadastro comum ainda exige telefone e exclusao remove identidades" do
    usuario = Usuario.new(nome: "Teste", email: "teste@example.com", password: "senha-teste-123")
    assert_not usuario.valid?
    assert usuario.errors.added?(:telefone, :blank)
    usuario = LoginSocial.autenticar(auth)
    usuario.destroy!
    assert_equal 0, IdentidadeSocial.count
  end

  private

  def auth(provider: "google_oauth2", email: "social@example.com", verified: true)
    OmniAuth::AuthHash.new(provider: provider, uid: "uid-123", info: { email: email, name: "Cliente Social" },
      extra: { raw_info: { email_verified: verified } })
  end
end
