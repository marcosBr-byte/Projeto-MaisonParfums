class CreatePerfumes < ActiveRecord::Migration[8.1]
  def change
    create_table :perfumes do |t|
      t.string :nome
      t.string :marca
      t.string :descricao
      t.string :categoria
      t.string :tamanho
      t.string :fragancia
      t.string :intensidade
      t.string :momento
      t.decimal :preco, precision: 10, scale: 2
      t.integer :estoque

      t.timestamps
    end
  end
end
