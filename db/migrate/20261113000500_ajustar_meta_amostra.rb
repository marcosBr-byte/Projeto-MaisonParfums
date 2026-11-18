class AjustarMetaAmostra < ActiveRecord::Migration[8.1]
  def up
    change_column_default :configuracaos, :brinde_meta, from: 200, to: 199.99
    execute "UPDATE configuracaos SET brinde_meta = 199.99 WHERE brinde_meta = 200"
  end

  def down
    change_column_default :configuracaos, :brinde_meta, from: 199.99, to: 200
    execute "UPDATE configuracaos SET brinde_meta = 200 WHERE brinde_meta = 199.99"
  end
end
