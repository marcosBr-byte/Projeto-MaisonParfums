class CreateMensagems < ActiveRecord::Migration[8.1]
  def change
    create_table :mensagems do |t|
      t.string :nome, null: false
      t.string :email, null: false
      t.string :assunto, null: false
      t.text :conteudo, null: false
      t.boolean :lida, default: false, null: false

      t.timestamps
    end
  end
end