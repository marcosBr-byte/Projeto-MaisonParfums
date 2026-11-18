require "net/smtp"

class Usuarios::PasswordsController < Devise::PasswordsController
  rate_limit store: SecurityRateLimitStore, to: 5, within: 10.minutes, only: :create

  rescue_from Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPFatalError,
    Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, with: :falha_no_envio

  private

  def falha_no_envio(erro)
    # Não expõe credenciais/tokens nem revela a existência da conta pela resposta.
    Rails.logger.error("Falha no envio da recuperação de senha: #{erro.class}. Verifique a configuração SMTP.")
    set_flash_message!(:notice, :send_paranoid_instructions)
    redirect_to after_sending_reset_password_instructions_path_for(resource_name), status: :see_other
  end
end
