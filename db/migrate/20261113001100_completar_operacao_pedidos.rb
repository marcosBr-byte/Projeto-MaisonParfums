class CompletarOperacaoPedidos < ActiveRecord::Migration[8.1]
  def change
    add_column :pedidos, :reserva_expira_em, :datetime
    add_column :pedidos, :estoque_devolvido_em, :datetime
    add_column :pedidos, :cancelamento_motivo, :string
    add_column :pedidos, :transportadora, :string
    add_column :pedidos, :codigo_rastreio, :string
    add_column :pedidos, :prazo_entrega, :date
    add_column :pedidos, :enviado_em, :datetime
    add_column :pedidos, :entregue_em, :datetime
    add_column :pedidos, :pagamento_requer_atencao, :boolean, default: false, null: false
    add_index :pedidos, [:status, :reserva_expira_em]
  end
end
