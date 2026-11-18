module Webhooks
  class MercadoPagoController < ActionController::Base
    skip_forgery_protection

    def create
      configuracao = Configuracao.atual
      return head :service_unavailable unless configuracao.pagamento_token.present? && configuracao.pagamento_webhook_secret.present?
      id = request.query_parameters["data.id"]
      servico = MercadoPagoCheckout.new(configuracao)
      return head :unauthorized unless servico.assinatura_valida?(id: id, request_id: request.headers["x-request-id"], assinatura: request.headers["x-signature"])
      case params[:type]
      when "order"
        servico.atualizar_order(id)
      when "payment"
        servico.atualizar_pagamento_legado(id)
      end
      head :ok
    rescue MercadoPagoCheckout::Erro
      head :service_unavailable
    end
  end
end
