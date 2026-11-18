ENV["RAILS_ENV"] ||= "test"
# Os testes usam configurações simuladas, independentemente do .env da loja.
%w[ACCESS_TOKEN WEBHOOK_SECRET SITE_URL ATIVO TESTE].each do |chave|
  ENV["MERCADO_PAGO_#{chave}"] = ""
end
# Credenciais fictícias habilitam somente as rotas; os testes usam OmniAuth simulado.
ENV["GOOGLE_CLIENT_ID"] = "google-client-test"
ENV["GOOGLE_CLIENT_SECRET"] = "google-secret-test"
ENV["FACEBOOK_APP_ID"] = "facebook-app-test"
ENV["FACEBOOK_APP_SECRET"] = "facebook-secret-test"
# Os testes não precisam de chaves ou credenciais do ambiente real.
ENV["ENC_PRIMARY_KEY"] = "a" * 64
ENV["ENC_DETERMINISTIC_KEY"] = "b" * 64
ENV["ENC_KEY_DERIVATION_SALT"] = "c" * 64
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
