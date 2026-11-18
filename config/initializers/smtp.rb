unless Rails.env.test?
  usuario_smtp = ENV["SMTP_USERNAME"].presence
  if usuario_smtp
    servidor_smtp = ENV.fetch("SMTP_ADDRESS", "smtp.gmail.com").strip
    senha_smtp = ENV["SMTP_PASSWORD"].to_s
    # O Google exibe a senha de app em grupos; espaços não fazem parte da senha.
    senha_smtp = senha_smtp.delete(" \t\r\n") if servidor_smtp == "smtp.gmail.com"
    Rails.application.config.action_mailer.delivery_method = :smtp
    Rails.application.config.action_mailer.perform_deliveries = true
    Rails.application.config.action_mailer.raise_delivery_errors = true
    Rails.application.config.action_mailer.smtp_settings = {
      address: servidor_smtp, port: ENV.fetch("SMTP_PORT", "587").to_i,
      domain: ENV["SMTP_DOMAIN"].presence || ENV["APP_HOST"].presence || "localhost",
      user_name: usuario_smtp.strip, password: senha_smtp,
      authentication: :plain, enable_starttls_auto: true, open_timeout: 5, read_timeout: 10
    }
  elsif Rails.env.development?
    Rails.application.config.action_mailer.delivery_method = :letter_opener
  end
end
