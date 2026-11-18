class AdicionarOrderMercadoPago < ActiveRecord::Migration[8.1]
  def change
    add_column :pedidos, :pagamento_order_id, :string
    add_index :pedidos, :pagamento_order_id, unique: true
  end
end
