class UsuarioController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_usuario

  def show
  end

  def update
    if @usuario.update(perfil_params)
      redirect_to perfil_path, notice: "Perfil atualizado com sucesso!"
    else
      flash.now[:alert] = "Não foi possível atualizar seu perfil."
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_usuario
    @usuario = current_usuario
  end

  def perfil_params
    params.require(:usuario).permit(:nome, :telefone, :cpf, :cep, :estado, :cidade, :bairro, :rua, :numero_casa, :complemento, :ponto_referencia, :imagem
    )
  end

  def params_login
    params.require(:usuario).permit(:email, :password)
  end

  def params_cadastrar
    params.require(:usuario).permit(:nome, :email, :telefone, :password, :password_confirmation)
  end
end
