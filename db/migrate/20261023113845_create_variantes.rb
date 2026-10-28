   class CreateVariantes < ActiveRecord::Migration[8.1]
     def up
       create_table :variantes do |t|
         t.references :produto, null: false, foreign_key: true
         t.string :tamanho, null: false
         t.decimal :preco, precision: 10, scale: 2, null: false
         t.integer :estoque, null: false, default: 0
         t.timestamps
       end
       add_index :variantes, [:produto_id, :tamanho], unique: true

       execute <<~SQL
         INSERT INTO variantes (produto_id, tamanho, preco, estoque, created_at, updated_at)
         SELECT id, tamanho, preco, COALESCE(estoque, 0), NOW(), NOW()
         FROM produtos
         WHERE tamanho IS NOT NULL AND preco IS NOT NULL
       SQL
     end

     def down
       drop_table :variantes
     end
   end