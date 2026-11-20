require "test_helper"

class RecuperacaoSenhaTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @usuario = Usuario.create!(nome: "Teste", email: "senha@example.com", telefone: "83999999999", password: "senha-antiga-123")
  end

  def trocar(token, senha: "senha-nova-456", confirmacao: "senha-nova-456")
    put usuario_password_path, params: { usuario: { reset_password_token: token, password: senha, password_confirmation: confirmacao } }
  end

  test "email contem token original e banco armazena digest" do
    token = @usuario.send_reset_password_instructions
    assert_not_equal token, @usuario.reload.reset_password_token
    assert_includes ActionMailer::Base.deliveries.last.body.to_s, "reset_password_token=#{token}"
    get edit_usuario_password_path(reset_password_token: token)
    assert_response :success
    assert_select 'input[name="usuario[reset_password_token]"][value=?]', token
  end

  test "token e de uso unico e exige novo login" do
    token = @usuario.send_reset_password_instructions
    trocar(token)
    assert_response :redirect
    assert @usuario.reload.valid_password?("senha-nova-456")
    assert_nil @usuario.reset_password_token
    get perfil_path
    assert_redirected_to new_usuario_session_path
    trocar(token)
    assert_response :unprocessable_entity
  end

  test "token expirado ou antigo nao altera senha" do
    antigo = @usuario.send_reset_password_instructions
    token = @usuario.send_reset_password_instructions
    trocar(antigo)
    assert_response :unprocessable_entity
    @usuario.update_column(:reset_password_sent_at, Time.current - Usuario.reset_password_within - 1.minute)
    trocar(token)
    assert_response :unprocessable_entity
    assert @usuario.reload.valid_password?("senha-antiga-123")
  end

  test "erro de confirmacao permite corrigir sem perder token" do
    token = @usuario.send_reset_password_instructions
    trocar(token, confirmacao: "diferente")
    assert_response :unprocessable_entity
    assert_select 'input[name="usuario[reset_password_token]"][value=?]', token
    trocar(token)
    assert_response :redirect
  end
  test "falha de autenticacao SMTP nao causa erro 500 nem expoe detalhes" do
    Devise.mailer.define_singleton_method(:reset_password_instructions) { |*| raise Net::SMTPAuthenticationError, "535 credencial-invalida-secreta" }
    post usuario_password_path, params: { usuario: { email: @usuario.email } }
    assert_redirected_to new_usuario_session_path
    mensagem = flash[:notice]
    assert_not_includes mensagem, "credencial-invalida-secreta"
    assert_match /Se este e-mail estiver cadastrado/, mensagem
    post usuario_password_path, params: { usuario: { email: "inexistente@example.com" } }
    assert_equal mensagem, flash[:notice]
  ensure
    Devise.mailer.singleton_class.remove_method(:reset_password_instructions)
  end

  test "recuperacao usa remetente da loja e ignora Gmail pessoal" do
    chaves = %w[SMTP_FROM SMTP_USERNAME GMAIL_USER]
    anteriores = chaves.to_h { |chave| [ chave, ENV[chave] ] }
    ENV["SMTP_FROM"] = "loja@example.com"
    ENV["SMTP_USERNAME"] = "loja@example.com"
    ENV["GMAIL_USER"] = "pessoal@example.com"
    @usuario.send_reset_password_instructions
    email = ActionMailer::Base.deliveries.last
    assert_equal [ "loja@example.com" ], email.from
    assert_not_includes email.from, "pessoal@example.com"
  ensure
    anteriores.each { |chave, valor| valor.nil? ? ENV.delete(chave) : ENV[chave] = valor }
  end
end
