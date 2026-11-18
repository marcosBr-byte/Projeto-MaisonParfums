class Usuarios::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    autenticar("google_oauth2")
  end

  def facebook
    autenticar("facebook")
  end

  def failure
    redirect_to new_usuario_session_path, alert: "Não foi possível concluir a conexão. Tente novamente ou entre com e-mail e senha."
  end

  private

  def autenticar(provider)
    auth = request.env["omniauth.auth"]
    unless Usuario.omniauth_providers.include?(provider.to_sym) && auth&.provider.to_s == provider
      return failure
    end
    conectado = usuario_signed_in?
    usuario = LoginSocial.autenticar(auth, usuario_atual: current_usuario)
    if conectado
      redirect_to(usuario.admin? ? admin_perfil_path : perfil_path, notice: "Conta #{LoginSocial::NOMES[provider]} conectada com sucesso.")
    else
      sign_in(:usuario, usuario)
      destino = usuario.perfil_completo? || usuario.admin? ? after_sign_in_path_for(usuario) : perfil_path
      redirect_to destino, notice: "Você entrou com #{LoginSocial::NOMES[provider]}.#{' Complete seu telefone e endereço antes de comprar.' unless usuario.admin? || usuario.perfil_completo?}"
    end
  rescue LoginSocial::Erro => erro
    redirect_to new_usuario_session_path, alert: erro.message
  end
end
