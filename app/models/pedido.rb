class Pedido < ApplicationRecord
  before_create { self.reserva_expira_em ||= 24.hours.from_now }
  before_create { self.pagamento_referencia ||= SecureRandom.uuid }

  after_update_commit :agendar_aviso_whatsapp, if: -> { saved_change_to_status? && pago? }

  def aviso_whatsapp_permitido?
    (pago? || enviado? || entregue?) && !pagamento_teste?
  end

  def agendar_aviso_whatsapp
    return unless aviso_whatsapp_permitido? && whatsapp_notificado_em.nil? && Configuracao.atual.whatsapp_notificacoes_ativas?
    NotificarPedidoWhatsappJob.perform_later(id)
  rescue StandardError => erro
    # O pedido já foi confirmado; uma falha de fila não deve repetir a compra.
    Rails.logger.error("Falha ao agendar aviso do pedido #{id}: #{erro.class}")
  end

  class OperacaoInvalida < StandardError; end

  def cobranca_online?
    pagamento_order_id.present? || pagamento_preferencia.present?
  end

  def confirmar_pagamento_manual!
    with_lock do
      unless pendente? && !cobranca_online? && pagamento_id.blank? && !estoque_devolvido_em
        raise OperacaoInvalida, "Somente pedidos pendentes sem cobrança online aceitam confirmação manual."
      end
      update!(status: :pago, pago_em: Time.current, pagamento_metodo: "manual", pagamento_status: "confirmado_manualmente")
    end
  end

  def cancelar!(motivo:, reembolso_confirmado: false, cobranca_encerrada: false)
    with_lock do
      return if cancelado?
      if pendente? && cobranca_online? && !cobranca_encerrada
        raise OperacaoInvalida, "Encerre a cobrança no Mercado Pago antes de liberar o estoque."
      end
      raise OperacaoInvalida, "Pedidos entregues exigem atendimento de devolução." if entregue?
      if (pago? || enviado?) && !reembolso_confirmado
        raise OperacaoInvalida, "Confirme o reembolso no provedor antes de cancelar um pedido pago."
      end
      unless estoque_devolvido_em
        itens_pedidos.order(:variante_id, :produto_id).each do |item|
          alvo = item.variante || item.produto
          alvo.with_lock { alvo.update!(estoque: alvo.estoque.to_i + item.quantidade) }
        end
      end
      update!(status: :cancelado, cancelamento_motivo: motivo, estoque_devolvido_em: estoque_devolvido_em || Time.current)
    end
  end

  def atualizar_entrega!(dados)
    with_lock do
      destino = dados.delete(:status).presence || status
      permitido = destino == status || (pago? && destino == "enviado") || (enviado? && destino == "entregue")
      raise OperacaoInvalida, "A entrega deve seguir a ordem: pago, enviado e entregue." unless permitido
      raise OperacaoInvalida, "Resolva a pendência de pagamento antes de enviar." if pagamento_requer_atencao?
      if destino == "enviado" && (dados[:transportadora].presence || transportadora).blank?
        raise OperacaoInvalida, "Informe a transportadora ou o responsável pela entrega local."
      end
      dados[:enviado_em] = Time.current if destino == "enviado" && !enviado_em
      dados[:entregue_em] = Time.current if destino == "entregue" && !entregue_em
      update!(dados.merge(status: destino))
    end
  end

  belongs_to :usuario
  has_many :itens_pedidos, class_name: "ItemPedido", dependent: :destroy
  has_many :produtos, through: :itens_pedidos
  has_many :mensagens, class_name: "Mensagem", dependent: :nullify

  enum :status, {
    pendente: "pendente",
    pago: "pago",
    enviado: "enviado",
    entregue: "entregue",
    cancelado: "cancelado"
  }
end
