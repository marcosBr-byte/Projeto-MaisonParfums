class AddFrascoMaeToProdutos < ActiveRecord::Migration[8.1]
  def change
    add_reference :produtos, :frasco_mae, null: true, foreign_key: { to_table: :frasco_maes }
  end
end
