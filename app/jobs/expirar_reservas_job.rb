class ExpirarReservasJob < ApplicationJob
  queue_as :default

  def perform
    Pedido.where(status: :pendente).where("reserva_expira_em <= ?", Time.current).find_each do |pedido|
      pedido.with_lock do
        next unless pedido.pendente? && pedido.reserva_expira_em <= Time.current
        # Cobranças externas podem ter pagamentos em processamento. Exigem conferência
        # antes da liberação; não arriscamos vender duas vezes o mesmo estoque.
        if pedido.cobranca_online?
          pedido.update!(pagamento_requer_atencao: true)
        else
          pedido.cancelar!(motivo: "Reserva expirada sem início de pagamento")
        end
      end
    end
  end
end
