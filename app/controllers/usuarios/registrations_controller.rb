class Usuarios::RegistrationsController < Devise::RegistrationsController
  protected

  def after_update_path_for(resource)
    resource.admin? ? admin_perfil_path : root_path
  end
end