class AdicionarPagamentoOnline < ActiveRecord::Migration[8.1]
  def change
    add_column :configuracaos, :pagamento_ativo, :boolean, default: false, null: false
    add_column :configuracaos, :pagamento_teste, :boolean, default: true, null: false
    add_column :configuracaos, :pagamento_token, :text
    add_column :configuracaos, :pagamento_webhook_secret, :text
    add_column :configuracaos, :pagamento_site_url, :string
    add_column :configuracaos, :frete_pago_valor, :decimal, precision: 10, scale: 2
    add_column :pedidos, :pagamento_referencia, :string
    add_index :pedidos, :pagamento_referencia, unique: true
    add_column :pedidos, :pagamento_id, :string
    add_index :pedidos, :pagamento_id, unique: true
    add_column :pedidos, :pagamento_preferencia, :string
    add_column :pedidos, :pagamento_url, :text
    add_column :pedidos, :pagamento_teste, :boolean
    add_column :pedidos, :pagamento_status, :string
    add_column :pedidos, :pagamento_metodo, :string
    add_column :pedidos, :pago_em, :datetime
    add_column :pedidos, :valor_frete, :decimal, precision: 10, scale: 2, default: 0, null: false
  end
end
