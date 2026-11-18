class AddDestaqueToProdutos < ActiveRecord::Migration[8.1]
  def change
    add_column :produtos, :destaque, :boolean, default: false, null: false
  end
end
