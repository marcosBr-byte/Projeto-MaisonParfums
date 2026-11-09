module Admin
  class MensagensController < ApplicationController
    layout "admin"

    before_action :authenticate_usuario!
    before_action :exigir_admin
    before_action :set_mensagem, only: [:show, :destroy]

    def index
      @mensagens = Mensagem.recentes
      @nao_lidas = Mensagem.nao_lidas.count
    end

    def show
      @mensagem.update(lida: true) unless @mensagem.lida?
    end

    def destroy
      @mensagem.destroy
      redirect_to admin_mensagens_path,notice: "Mensagem excluída com sucesso!"
    end

    private

    def set_mensagem
      @mensagem = Mensagem.find(params[:id])
    end
  end
end