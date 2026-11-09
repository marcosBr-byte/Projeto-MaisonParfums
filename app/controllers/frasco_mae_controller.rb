class FrascoMaeController < ApplicationController
  layout "admin"

  before_action :exigir_admin
  before_action :set_frasco_mae, only: %i[edit update destroy]

  def index
    @frascos = FrascoMae.includes(:produtos).order(:nome)
  end

  def new
    @frasco_mae = FrascoMae.new
  end

  def create
    @frasco_mae = FrascoMae.new(frasco_mae_params)
    if @frasco_mae.save
      redirect_to frasco_maes_path, notice: "Frasco Mãe criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @frasco_mae.update(frasco_mae_params)
      redirect_to frasco_maes_path, notice: "Frasco Mãe atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @frasco_mae.destroy
      redirect_to frasco_maes_path, notice: "Frasco Mãe excluído com sucesso.", status: :see_other
    else
      redirect_to frasco_maes_path, alert: "Este frasco está em uso por produtos e não pode ser excluído.", status: :see_other
    end
  end

  private

  def set_frasco_mae
    @frasco_mae = FrascoMae.find(params[:id])
  end

  def frasco_mae_params
    params.require(:frasco_mae).permit(:nome, :estoque_ml)
  end
end
