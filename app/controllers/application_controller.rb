class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # Atalhos para não quebrar views/controllers que ainda usam esses nomes
  def logado?
    usuario_signed_in?
  end

  def usuario_logado
    current_usuario
  end
  helper_method :logado?, :usuario_logado

  def exigir_admin
    authenticate_usuario!
    redirect_to root_path, alert: "Acesso negado" unless current_usuario.admin?
  end

  def after_sign_in_path_for(usuario)
    stored_location_for(usuario) || (usuario.admin? ? admin_path : root_path)
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_usuario_session_path
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[nome telefone estado cidade bairro])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[nome telefone estado cidade bairro])
  end
end