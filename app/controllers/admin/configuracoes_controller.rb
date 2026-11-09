module Admin
  class ConfiguracoesController < ApplicationController
    layout "admin"

    before_action :authenticate_usuario!
    before_action :exigir_admin

    before_action :carregar_configuracao

    def index
    end

    def update
      if @configuracao.update(configuracao_params)
        redirect_to admin_configuracoes_path, notice: "Configurações atualizadas com sucesso!"
      else
        render :index, status: :unprocessable_entity
      end
    end

    private

    def carregar_configuracao
      @configuracao = Configuracao.atual
    end

    def configuracao_params
      params.require(:configuracao).permit( :descricao, :whatsapp, :email_contato, :instagram_url )
    end
  end
end