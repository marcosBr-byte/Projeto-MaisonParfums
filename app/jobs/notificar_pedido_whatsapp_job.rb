class NotificarPedidoWhatsappJob < ApplicationJob
  retry_on WhatsAppPedido::Erro, Net::OpenTimeout, Net::ReadTimeout, SocketError, wait: :polynomially_longer, attempts: 4
  discard_on ActiveRecord::RecordNotFound

  def perform(pedido_id)
    configuracao = Configuracao.atual
    return unless configuracao.whatsapp_notificacoes_ativas? && WhatsAppPedido.configurado?

    pedido = Pedido.find(pedido_id)
    pedido.with_lock do
      return unless pedido.aviso_whatsapp_permitido? && pedido.whatsapp_notificado_em.nil?
      mensagem_id = WhatsAppPedido.enviar(pedido, configuracao)
      pedido.update!(whatsapp_notificado_em: Time.current, whatsapp_mensagem_id: mensagem_id)
    end
  end
end
