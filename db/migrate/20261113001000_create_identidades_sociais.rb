class CreateIdentidadesSociais < ActiveRecord::Migration[8.1]
  def change
    create_table :identidades_sociais do |t|
      t.references :usuario, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.timestamps
    end
    add_index :identidades_sociais, [ :provider, :uid ], unique: true
    add_index :identidades_sociais, [ :usuario_id, :provider ], unique: true
  end
end
