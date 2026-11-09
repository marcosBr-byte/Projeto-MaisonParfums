class CreateBanners < ActiveRecord::Migration[8.1]
  def change
    create_table :banners do |t|
      t.string :chave, null: false
      t.string :titulo, null: false
      t.string :subtitulo
      t.boolean :ativo, default: true, null: false
      t.integer :ordem, default: 0, null: false

      t.timestamps
    end

    add_index :banners, :chave, unique: true
  end
end