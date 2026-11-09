class CreateConfiguracaos < ActiveRecord::Migration[8.1]
  def change
    create_table :configuracaos do |t|
      t.text :descricao
      t.string :whatsapp
      t.string :email_contato
      t.string :instagram_url

      t.timestamps
    end
  end
end
