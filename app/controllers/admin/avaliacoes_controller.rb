module Admin
  class AvaliacoesController < ApplicationController
    layout "admin"
    before_action :authenticate_usuario!
    before_action :exigir_admin

    def index
      @avaliacoes = Avaliacao.includes(:usuario, :produto).with_attached_fotos.order(publicada: :asc, created_at: :desc).limit(100)
    end

    def update
      avaliacao = Avaliacao.find(params[:id])
      avaliacao.update!(publicada: params.require(:avaliacao).permit(:publicada)[:publicada])
      redirect_to admin_avaliacoes_path, notice: avaliacao.conteudo_ofensivo? ? "Avaliação mantida oculta por conter linguagem ofensiva." : "Visibilidade da avaliação atualizada."
    end

    def destroy
      Avaliacao.find(params[:id]).destroy!
      redirect_to admin_avaliacoes_path, notice: "Avaliação excluída."
    end
  end
end
