class AddComercialSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :configuracaos, :desconto_ativo, :boolean, default: false, null: false
    add_column :configuracaos, :desconto_percentual, :decimal, precision: 5, scale: 2, default: 0, null: false
    add_column :configuracaos, :brinde_ativo, :boolean, default: true, null: false
    add_column :configuracaos, :brinde_meta, :decimal, precision: 10, scale: 2, default: 199, null: false
    add_column :configuracaos, :brinde_descricao, :string, default: "Um brinde especial da Maison Parfum", null: false
    add_column :configuracaos, :borrifadas_por_ml, :integer, default: 10, null: false
    add_column :configuracaos, :whatsapp_notificacoes_ativas, :boolean, default: false, null: false
    add_column :configuracaos, :whatsapp_notificacao, :string
    add_column :pedidos, :subtotal, :decimal, precision: 12, scale: 2
    add_column :pedidos, :desconto_percentual, :decimal, precision: 5, scale: 2, default: 0, null: false
    add_column :pedidos, :desconto_valor, :decimal, precision: 12, scale: 2, default: 0, null: false
    add_column :pedidos, :brinde_incluso, :boolean, default: false, null: false
    add_column :pedidos, :brinde_descricao, :string
    add_column :pedidos, :whatsapp_notificado_em, :datetime
    add_column :pedidos, :whatsapp_mensagem_id, :string
    add_column :variantes, :volume_lacrado_ml, :integer
    add_check_constraint :configuracaos, "desconto_percentual >= 0 AND desconto_percentual <= 100", name: "desconto_valido"
    add_check_constraint :variantes, "estoque >= 0", name: "estoque_variante_nao_negativo", validate: false
  end
end
