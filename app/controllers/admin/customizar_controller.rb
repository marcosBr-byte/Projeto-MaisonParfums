module Admin
  class CustomizarController < ApplicationController
    layout "admin"

    before_action :authenticate_usuario!
    before_action :exigir_admin
    before_action :carregar_videos

    def index
      Banner::ATALHOS.each_key.with_index do |chave, indice|
        Banner.find_or_create_by!(chave: chave) { |banner| banner.ordem = 10 + indice; banner.ativo = true }
      end
      Banner.find_or_create_by!(chave: "nicho") { |banner| banner.ordem = 6; banner.ativo = false }
      Banner.find_or_create_by!(chave: "experiencia") { |banner| banner.ordem = 7; banner.ativo = false }
      Banner.find_or_create_by!(chave: "amostra") { |banner| banner.ordem = 3; banner.ativo = false }
      @banners = Banner.where.not(chave: "atalho_mais_vendidos").with_attached_imagem.order(:ordem)
    end

    def update
      @banner = Banner.find(params[:id])

      if @banner.update(banner_params)
        redirect_to admin_customizar_path, notice: "Banner atualizado com sucesso!"
      else
        @banners = Banner.where.not(chave: "atalho_mais_vendidos").with_attached_imagem.order(:ordem).map { |banner| banner.id == @banner.id ? @banner : banner }
        render :index, status: :unprocessable_entity
      end
    end

    private

    def carregar_videos
      @videos_home = VideoHome.with_attached_arquivo.ordenados
      @novo_video = VideoHome.new(ordem: VideoHome.maximum(:ordem).to_i + 1)
    end

    def banner_params
      params.require(:banner).permit(:ativo, :ordem, :imagem)
    end
  end
end
