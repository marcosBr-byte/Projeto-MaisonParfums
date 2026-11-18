class AddFreteGratisSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :configuracaos, :frete_gratis_ativo, :boolean, default: true, null: false
    add_column :configuracaos, :frete_gratis_meta, :decimal, precision: 10, scale: 2, default: 350, null: false
    add_column :pedidos, :frete_gratis, :boolean, default: false, null: false
  end
end
