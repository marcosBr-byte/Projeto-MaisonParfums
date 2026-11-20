require "test_helper"

class UsuarioControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @admin = Usuario.create!(nome: "Admin perfil", email: "admin-perfil@example.com",
      telefone: "83999999999", password: "senha-perfil-123", role: :admin)
    sign_in @admin
  end

  test "administrador altera telefone na edicao da conta e ve o numero salvo no perfil" do
    get edit_usuario_registration_path
    assert_response :success
    assert_select "#endereco", count: 0
    assert_select 'input[name="usuario[cep]"]', count: 0
    assert_select 'input[type="tel"][name="usuario[telefone]"][value="83999999999"]'
    put usuario_registration_path, params: { usuario: { telefone: "(83) 98888-7777", current_password: "senha-perfil-123" } }
    assert_redirected_to admin_perfil_path
    assert_equal "(83) 98888-7777", @admin.reload.telefone
    follow_redirect!
    assert_response :success
    assert_includes response.body, "(83) 98888-7777"
  end

  test "administrador troca o email e entra novamente com o novo acesso" do
    novo_email = "novo-admin@example.com"

    put usuario_registration_path, params: { usuario: { email: novo_email, current_password: "incorreta" } }
    assert_response :unprocessable_entity
    assert_equal "admin-perfil@example.com", @admin.reload.email

    put usuario_registration_path, params: { usuario: { email: novo_email, current_password: "senha-perfil-123" } }
    assert_redirected_to admin_perfil_path
    assert_equal novo_email, @admin.reload.email
    assert_predicate @admin, :admin?

    sign_out @admin
    post usuario_session_path, params: { usuario: { email: novo_email, password: "senha-perfil-123" } }
    assert_response :redirect
    get admin_perfil_path
    assert_response :success
    assert_includes response.body, novo_email
  end

  test "administrador abre seu perfil sem formulario de endereco do cliente" do
    get perfil_path
    assert_redirected_to admin_perfil_path
  end

  test "administrador pode deixar o telefone em branco" do
    put usuario_registration_path, params: { usuario: { telefone: "", current_password: "senha-perfil-123" } }
    assert_redirected_to admin_perfil_path
    assert_empty @admin.reload.telefone
  end

  test "senha atual incorreta impede alterar o telefone" do
    put usuario_registration_path, params: { usuario: { telefone: "(83) 98888-7777", current_password: "incorreta" } }
    assert_response :unprocessable_entity
    assert_equal "83999999999", @admin.reload.telefone
  end
end
