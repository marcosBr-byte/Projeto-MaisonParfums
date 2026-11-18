class LoginSocial
  class Erro < StandardError; end
  NOMES = { "google_oauth2" => "Google", "facebook" => "Facebook" }.freeze

  def self.autenticar(auth, usuario_atual: nil)
    provider = auth&.provider.to_s
    uid = auth&.uid.to_s
    raise Erro, "Não foi possível confirmar sua identidade. Tente novamente." unless NOMES.key?(provider) && uid.present?

    identidade = IdentidadeSocial.find_by(provider: provider, uid: uid)
    if identidade
      if usuario_atual && identidade.usuario_id != usuario_atual.id
        raise Erro, "Essa conta já está conectada a outro cadastro da loja."
      end
      return identidade.usuario
    end

    if usuario_atual
      usuario_atual.identidades_sociais.create!(provider: provider, uid: uid)
      return usuario_atual
    end

    email = auth.info&.email.to_s.strip.downcase
    raise Erro, "Precisamos do seu e-mail para criar a conta. Autorize o compartilhamento ou cadastre-se com e-mail e senha." if email.blank?
    if provider == "google_oauth2" && auth.extra&.raw_info&.email_verified != true
      raise Erro, "Confirme seu e-mail no Google antes de continuar."
    end
    if Usuario.exists?(email: email)
      raise Erro, "Já existe uma conta com esse e-mail. Entre com seu acesso atual e conecte #{NOMES[provider]} em Meu perfil. Se necessário, use Esqueceu sua senha."
    end

    Usuario.transaction do
      usuario = Usuario.new(nome: auth.info&.name.to_s.strip.presence || "Cliente Maison", email: email,
        password: Devise.friendly_token(48), role: :cliente)
      usuario.identidades_sociais.build(provider: provider, uid: uid)
      usuario.save!
      usuario
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    raise Erro, "Não foi possível conectar essa conta. Entre com seu acesso atual ou tente novamente."
  end
end
