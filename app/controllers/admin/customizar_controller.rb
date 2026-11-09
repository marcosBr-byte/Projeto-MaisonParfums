module Admin
  class CustomizarController < ApplicationController
    layout "admin"

    before_action :authenticate_usuario!
    before_action :exigir_admin

    def index
      @banners = Banner.order(:ordem)
    end

    def update
      @banner = Banner.find(params[:id])

      if @banner.update(banner_params)
        redirect_to admin_customizar_path, notice: "Banner atualizado com sucesso!"
      else
        @banners = Banner.order(:ordem)
        render :index, status: :unprocessable_entity
      end
    end

    private

    def banner_params
      params.require(:banner).permit( :titulo, :subtitulo, :ativo, :ordem,:imagem)
    end
  end
end