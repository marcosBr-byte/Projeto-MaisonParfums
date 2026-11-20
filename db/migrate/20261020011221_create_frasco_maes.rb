class CreateFrascoMaes < ActiveRecord::Migration[8.1]
  def change
    create_table :frasco_maes do |t|
      t.string :nome, null: false
      t.integer :estoque_ml, null: false, default: 0
      t.timestamps
    end
  end
end
