require "uri"

habilitado = (ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?) ||
  (ENV["FACEBOOK_APP_ID"].present? && ENV["FACEBOOK_APP_SECRET"].present?)

if habilitado
  # O middleware pode receber uma requisição antes de o Rails carregar as rotas.
  OmniAuth.config.path_prefix = "/usuarios/auth"
  base = ENV["OAUTH_BASE_URL"].presence || ("http://localhost:3000" unless Rails.env.production?)
  uri = URI.parse(base.to_s)
  local = !Rails.env.production? && uri.host.in?(%w[localhost 127.0.0.1])
  unless uri.is_a?(URI::HTTP) && (uri.scheme == "https" || local) && uri.host.present? &&
      uri.userinfo.nil? && uri.query.nil? && uri.fragment.nil? && [ "", "/" ].include?(uri.path)
    raise "Configure OAUTH_BASE_URL com o endereço HTTPS da loja para habilitar o login social."
  end
  # O retorno OAuth usa um endereço fixo, sem confiar no Host recebido na requisição.
  OmniAuth.config.full_host = base.delete_suffix("/")
end
