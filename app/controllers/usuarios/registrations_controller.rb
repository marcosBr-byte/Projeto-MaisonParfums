class Usuarios::RegistrationsController < Devise::RegistrationsController
  layout :layout_da_conta, only: [ :edit, :update ]

  rate_limit store: SecurityRateLimitStore, to: 10, within: 10.minutes, only: :create

  protected

  def layout_da_conta
    current_usuario&.admin? ? "admin" : "application"
  end

  def after_update_path_for(resource)
    resource.admin? ? admin_perfil_path : root_path
  end
end
