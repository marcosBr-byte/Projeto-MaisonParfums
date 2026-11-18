class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV["SMTP_FROM"].presence || ENV["SMTP_USERNAME"].presence || "no-reply@maisonparfum.com" }
  layout "mailer"
end
