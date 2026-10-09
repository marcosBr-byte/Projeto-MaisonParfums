class AddPerfumeForeignKeys < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :itens_carrinhos, :perfumes
    add_foreign_key :itens_pedidos, :perfumes
  end
end
