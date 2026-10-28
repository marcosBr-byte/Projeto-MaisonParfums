class AddPiramideOlfativaToProdutos < ActiveRecord::Migration[8.1]
  def up
    add_column :produtos, :piramide_olfativa, :string
  end
  def down
    remove_column :produtos, :piramide_olfativa, :string
  end
end