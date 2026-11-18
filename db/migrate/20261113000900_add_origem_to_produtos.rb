class AddOrigemToProdutos < ActiveRecord::Migration[8.1]
  def change
    add_column :produtos, :origem, :string
    add_check_constraint :produtos, "origem IS NULL OR origem IN ('', 'arabe', 'importado')", name: "produto_origem_valida"
  end
end
