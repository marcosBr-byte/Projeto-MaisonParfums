class AddPerfilCompletoToUsuarios < ActiveRecord::Migration[8.1]
  def change
    add_column :usuarios, :cpf, :string, if_not_exists: true
    add_column :usuarios, :cep, :string, if_not_exists: true
    add_column :usuarios, :rua, :string, if_not_exists: true
    add_column :usuarios, :numero_casa, :string, if_not_exists: true
    add_column :usuarios, :complemento, :string, if_not_exists: true
    add_column :usuarios, :ponto_referencia, :string, if_not_exists: true
  end
end