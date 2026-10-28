class CriarPiramideOlfativaEmProdutos < ActiveRecord::Migration[8.1]
  def up
    add_column :produtos, :piramide_olfativa, :string unless column_exists?(:produtos, :piramide_olfativa)
  end
  def down
    remove_column :produtos, :piramide_olfativa if unless column_exists?(:produtos, :piramide_olfativa)
  end
end
end