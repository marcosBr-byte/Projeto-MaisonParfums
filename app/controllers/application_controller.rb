class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def exigir_admin
    authenticate_usuario!
    redirect_to root_path, alert: "Acesso negado" unless current_usuario.admin?
  end

  def after_sign_in_path_for(usuario)
    stored_location_for(usuario) || (usuario.admin? ? admin_path : perfil_path)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[nome telefone])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[nome telefone])
  end
end