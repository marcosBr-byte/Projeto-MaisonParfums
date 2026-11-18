class RegionalizarFreteGratis < ActiveRecord::Migration[8.1]
  def up
    add_column :configuracaos, :frete_gratis_meta_nordeste, :decimal, precision: 10, scale: 2, default: 300, null: false
    change_column_default :configuracaos, :frete_gratis_meta, from: 350, to: 400
    execute "UPDATE configuracaos SET frete_gratis_meta = 400"
  end

  def down
    remove_column :configuracaos, :frete_gratis_meta_nordeste
    change_column_default :configuracaos, :frete_gratis_meta, from: 400, to: 350
  end
end
