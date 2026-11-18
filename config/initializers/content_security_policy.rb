Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src :self
    policy.style_src :self, :unsafe_inline, "https://fonts.googleapis.com", "https://cdnjs.cloudflare.com"
    policy.font_src :self, :data, "https://fonts.gstatic.com", "https://cdnjs.cloudflare.com"
    policy.img_src :self, :data, :blob
    policy.media_src :self, :blob
    policy.connect_src :self
    policy.object_src :none
    policy.base_uri :self
    policy.frame_ancestors :none
    policy.form_action :self, "https://www.mercadopago.com.br", "https://sandbox.mercadopago.com.br"
  end
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
  config.content_security_policy_nonce_auto = true
end
