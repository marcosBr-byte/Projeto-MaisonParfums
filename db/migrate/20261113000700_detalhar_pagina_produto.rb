class DetalharPaginaProduto < ActiveRecord::Migration[8.1]
  def change
    %i[inverno primavera verao outono dia noite].each do |campo|
      add_column :produtos, "uso_#{campo}", :integer
      add_check_constraint :produtos, "uso_#{campo} BETWEEN 0 AND 100", name: "produto_uso_#{campo}_valido"
    end
    create_table :notas_olfativas do |t|
      t.references :produto, null: false, foreign_key: true
      t.string :nome, null: false
      t.string :nivel, null: false
      t.timestamps
    end
    create_table :avaliacoes do |t|
      t.references :produto, null: false, foreign_key: true
      t.references :usuario, null: false, foreign_key: true
      t.integer :nota, null: false
      t.text :comentario, null: false
      t.boolean :publicada, default: false, null: false
      t.timestamps
    end
    add_index :avaliacoes, [:produto_id, :usuario_id], unique: true
    add_check_constraint :avaliacoes, "nota BETWEEN 1 AND 5", name: "avaliacao_nota_valida"
  end
end
