module Admin
  class VideosHomeController < ApplicationController
    before_action :authenticate_usuario!
    before_action :exigir_admin

    def create
      salvar(VideoHome.new, "Vídeo adicionado ao carrossel.")
    end

    def update
      salvar(VideoHome.find(params[:id]), "Vídeo atualizado.")
    end

    def destroy
      VideoHome.find(params[:id]).destroy!
      redirect_to admin_customizar_path(anchor: "videos-home"), notice: "Vídeo removido do carrossel."
    end

    private

    def salvar(video, mensagem)
      if video.update(params.require(:video_home).permit(:titulo, :ordem, :ativo, :arquivo))
        redirect_to admin_customizar_path(anchor: "videos-home"), notice: mensagem
      else
        redirect_to admin_customizar_path(anchor: "videos-home"), alert: video.errors.full_messages.to_sentence
      end
    end
  end
end
