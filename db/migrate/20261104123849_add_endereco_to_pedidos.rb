class AddEnderecoToPedidos < ActiveRecord::Migration[8.1]
  def change
    add_column :pedidos, :cep, :string
    add_column :pedidos, :estado, :string
    add_column :pedidos, :cidade, :string
    add_column :pedidos, :bairro, :string
    add_column :pedidos, :rua, :string
    add_column :pedidos, :numero_casa, :string
    add_column :pedidos, :complemento, :string
    add_column :pedidos, :ponto_referencia, :string
    add_column :pedidos, :telefone_entrega, :string
  end
end