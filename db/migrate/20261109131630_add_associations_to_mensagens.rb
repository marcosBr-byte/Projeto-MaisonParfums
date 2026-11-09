class AddAssociationsToMensagens < ActiveRecord::Migration[8.1]
  def change
    add_reference :mensagems, :usuario, null: false, foreign_key: true
    add_reference :mensagems, :pedido, null: true, foreign_key: true
  end
end