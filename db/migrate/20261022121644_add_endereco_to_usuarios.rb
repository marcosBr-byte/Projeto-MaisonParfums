class AddEnderecoToUsuarios < ActiveRecord::Migration[8.1]
  def change
    add_column :usuarios, :estado, :string
    add_column :usuarios, :cidade, :string
    add_column :usuarios, :bairro, :string
  end
end
