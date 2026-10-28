class AddConcentracaoToProdutos < ActiveRecord::Migration[8.1]
  def change
    add_column :produtos, :concentracao, :string
  end
end
