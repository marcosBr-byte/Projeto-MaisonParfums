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
      permitidos = params.require(:configuracao).permit( :descricao, :whatsapp, :email_contato, :instagram_url, :desconto_ativo, :desconto_percentual, :frete_gratis_ativo, :frete_gratis_meta, :frete_gratis_meta_nordeste, :brinde_ativo, :brinde_meta, :brinde_descricao, :borrifadas_por_ml, :whatsapp_notificacoes_ativas, :whatsapp_notificacao, :pagamento_ativo, :pagamento_teste, :pagamento_token, :pagamento_webhook_secret, :pagamento_site_url, :frete_pago_valor )
      %w[pagamento_token pagamento_webhook_secret].each { |chave| permitidos.delete(chave) if permitidos[chave].blank? }
      permitidos
    end
  end
end