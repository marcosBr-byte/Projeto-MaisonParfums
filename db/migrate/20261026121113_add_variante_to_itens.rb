   class AddVarianteToItens < ActiveRecord::Migration[8.1]
     def up
       add_reference :itens_carrinhos, :variante, foreign_key: true
       add_reference :itens_pedidos, :variante, foreign_key: true

       execute <<~SQL
         UPDATE itens_carrinhos ic SET variante_id = v.id
         FROM variantes v, produtos p
         WHERE ic.produto_id = p.id AND v.produto_id = p.id AND v.tamanho = p.tamanho
       SQL

       execute <<~SQL
         UPDATE itens_pedidos ip SET variante_id = v.id
         FROM variantes v, produtos p
         WHERE ip.produto_id = p.id AND v.produto_id = p.id AND v.tamanho = p.tamanho
       SQL
     end

     def down
       remove_reference :itens_pedidos, :variante, foreign_key: true
       remove_reference :itens_carrinhos, :variante, foreign_key: true
     end
   end