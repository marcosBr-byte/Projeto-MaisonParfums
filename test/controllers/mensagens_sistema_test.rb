require "test_helper"

class MensagensSistemaTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  test "visitante recebe convite para entrar em portugues" do
    get carrinho_path
    assert_redirected_to new_usuario_session_path
    follow_redirect!
    assert_select ".system-message[role='alert']", text: /Entre na sua conta ou cadastre-se para continuar/
    assert_select "button[aria-label='Fechar mensagem']"
    assert_no_match(/translation missing/i, response.body)
  end

  test "admin recebe aviso de compra sem criar carrinho" do
    admin = criar_usuario("admin")
    sign_in admin
    post adicionar_carrinho_path, params: { produto_id: "inexistente", quantidade: "1" }
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".system-message[role='alert']", text: /conta de administrador.*conta de cliente/
    assert_nil admin.reload.carrinho
  end

  test "login do cliente e do admin usa aviso padronizado em portugues" do
    %w[cliente admin].each do |role|
      usuario = criar_usuario(role)
      post usuario_session_path, params: { usuario: { email: usuario.email, password: "senha-teste-123" } }
      follow_redirect!
      assert_select ".system-message[role='status']", text: /Você entrou na sua conta/
      delete destroy_usuario_session_path
    end
  end

  test "erros de cadastro mostram campos e orientacao em portugues" do
    post usuario_registration_path, params: { usuario: { nome: "", email: "invalido", password: "123", password_confirmation: "456" } }
    assert_response :unprocessable_entity
    assert_select "#error_explanation[role='alert']", text: /Confira os dados para continuar/
    assert_match "não é válido", response.body
    assert_no_match(/translation missing|is invalid|too short/i, response.body)
  end

  private

  def criar_usuario(role)
    Usuario.create!(nome: "Teste", email: "#{role}@mensagens.example.com", telefone: "85999999999", password: "senha-teste-123", role: role)
  end
end
