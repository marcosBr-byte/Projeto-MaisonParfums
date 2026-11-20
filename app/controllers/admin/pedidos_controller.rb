module Admin
  class PedidosController < ApplicationController
    layout "admin"

    before_action :authenticate_usuario!
    before_action :exigir_admin

    def index
      @status = params[:status].presence_in(Pedido.defined_enums["status"].keys)

      @pedidos = Pedido.includes(:usuario).order(created_at: :desc)
      @pedidos = @pedidos.where(status: @status) if @status
    end

    def notificar_whatsapp
      pedido = Pedido.find(params[:id])
      configuracao = Configuracao.atual
      if !pedido.aviso_whatsapp_permitido?
        redirect_to admin_pedido_path(pedido), alert: "O aviso está disponível apenas para pedidos com pagamento confirmado e fora do ambiente de teste."
      elsif pedido.whatsapp_notificado_em.present?
        redirect_to admin_pedido_path(pedido), notice: "Este aviso já foi aceito pelo WhatsApp."
      elsif configuracao.whatsapp_notificacoes_ativas? && WhatsAppPedido.configurado?
        NotificarPedidoWhatsappJob.perform_later(pedido.id)
        redirect_to admin_pedido_path(pedido), notice: "Aviso colocado na fila de envio."
      else
        redirect_to admin_pedido_path(pedido), alert: "Configure e ative o WhatsApp nas configurações da loja."
      end
    rescue ActiveJob::EnqueueError
      redirect_to admin_pedido_path(pedido), alert: "Não foi possível colocar o aviso na fila. Tente novamente."
    end

    def confirmar_pagamento
      pedido = Pedido.find(params[:id])
      raise Pedido::OperacaoInvalida, "Confirme o recebimento do valor antes de continuar." unless params[:recebimento_confirmado] == "1"
      pedido.confirmar_pagamento_manual!
      redirect_to admin_pedido_path(pedido), notice: "Recebimento manual confirmado."
    rescue Pedido::OperacaoInvalida => erro
      redirect_to admin_pedido_path(pedido), alert: erro.message
    end

    def update
      pedido = Pedido.find(params[:id])
      pedido.atualizar_entrega!(params.require(:pedido).permit(:status, :transportadora, :codigo_rastreio, :prazo_entrega).to_h.symbolize_keys)
      redirect_to admin_pedido_path(pedido), notice: "Entrega atualizada."
    rescue Pedido::OperacaoInvalida, ActiveRecord::RecordInvalid => erro
      redirect_to admin_pedido_path(pedido), alert: erro.message
    end

    def cancelar
      pedido = Pedido.find(params[:id])
      if pedido.pendente? && pedido.cobranca_online?
        raise Pedido::OperacaoInvalida, "Encerre a cobrança no Mercado Pago e confirme abaixo antes de liberar o estoque." unless params[:cobranca_encerrada] == "1"
      end
      pedido.cancelar!(motivo: "Cancelado pelo administrador", reembolso_confirmado: params[:reembolso_confirmado] == "1", cobranca_encerrada: params[:cobranca_encerrada] == "1")
      redirect_to admin_pedido_path(pedido), notice: "Pedido cancelado e estoque devolvido."
    rescue Pedido::OperacaoInvalida => erro
      redirect_to admin_pedido_path(pedido), alert: erro.message
    end

    def show
      @pedido = Pedido.includes(:usuario, itens_pedidos: [ :produto, :variante ]).find(params[:id])
    end
  end
end
