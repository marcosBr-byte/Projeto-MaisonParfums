# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_18_195100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "avaliacoes", force: :cascade do |t|
    t.bigint "produto_id", null: false
    t.bigint "usuario_id", null: false
    t.integer "nota", null: false
    t.text "comentario", null: false
    t.boolean "publicada", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["produto_id", "usuario_id"], name: "index_avaliacoes_on_produto_id_and_usuario_id", unique: true
    t.index ["produto_id"], name: "index_avaliacoes_on_produto_id"
    t.index ["usuario_id"], name: "index_avaliacoes_on_usuario_id"
    t.check_constraint "nota >= 1 AND nota <= 5", name: "avaliacao_nota_valida"
  end

  create_table "banners", force: :cascade do |t|
    t.string "chave", null: false
    t.string "titulo", null: false
    t.string "subtitulo"
    t.boolean "ativo", default: true, null: false
    t.integer "ordem", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chave"], name: "index_banners_on_chave", unique: true
  end

  create_table "carrinhos", force: :cascade do |t|
    t.bigint "usuario_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["usuario_id"], name: "index_carrinhos_on_usuario_id"
  end

  create_table "configuracaos", force: :cascade do |t|
    t.text "descricao"
    t.string "whatsapp"
    t.string "email_contato"
    t.string "instagram_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "desconto_ativo", default: false, null: false
    t.decimal "desconto_percentual", precision: 5, scale: 2, default: "0.0", null: false
    t.boolean "brinde_ativo", default: true, null: false
    t.decimal "brinde_meta", precision: 10, scale: 2, default: "199.99", null: false
    t.string "brinde_descricao", default: "1 amostra exclusiva da Maison Parfum", null: false
    t.integer "borrifadas_por_ml", default: 10, null: false
    t.boolean "whatsapp_notificacoes_ativas", default: false, null: false
    t.string "whatsapp_notificacao"
    t.boolean "frete_gratis_ativo", default: true, null: false
    t.decimal "frete_gratis_meta", precision: 10, scale: 2, default: "400.0", null: false
    t.decimal "frete_gratis_meta_nordeste", precision: 10, scale: 2, default: "300.0", null: false
    t.boolean "pagamento_ativo", default: false, null: false
    t.boolean "pagamento_teste", default: true, null: false
    t.text "pagamento_token"
    t.text "pagamento_webhook_secret"
    t.string "pagamento_site_url"
    t.decimal "frete_pago_valor", precision: 10, scale: 2
    t.check_constraint "desconto_percentual >= 0::numeric AND desconto_percentual <= 100::numeric", name: "desconto_valido"
  end

  create_table "frasco_maes", force: :cascade do |t|
    t.string "nome", null: false
    t.integer "estoque_ml", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "identidades_sociais", force: :cascade do |t|
    t.bigint "usuario_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_identidades_sociais_on_provider_and_uid", unique: true
    t.index ["usuario_id", "provider"], name: "index_identidades_sociais_on_usuario_id_and_provider", unique: true
    t.index ["usuario_id"], name: "index_identidades_sociais_on_usuario_id"
  end

  create_table "itens_carrinhos", force: :cascade do |t|
    t.bigint "carrinho_id", null: false
    t.bigint "produto_id", null: false
    t.integer "quantidade"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "variante_id"
    t.index ["carrinho_id"], name: "index_itens_carrinhos_on_carrinho_id"
    t.index ["produto_id"], name: "index_itens_carrinhos_on_produto_id"
    t.index ["variante_id"], name: "index_itens_carrinhos_on_variante_id"
  end

  create_table "itens_pedidos", force: :cascade do |t|
    t.bigint "pedido_id", null: false
    t.bigint "produto_id", null: false
    t.integer "quantidade"
    t.decimal "preco_unitario"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "variante_id"
    t.index ["pedido_id"], name: "index_itens_pedidos_on_pedido_id"
    t.index ["produto_id"], name: "index_itens_pedidos_on_produto_id"
    t.index ["variante_id"], name: "index_itens_pedidos_on_variante_id"
  end

  create_table "mensagems", force: :cascade do |t|
    t.string "nome", null: false
    t.string "email", null: false
    t.string "assunto", null: false
    t.text "conteudo", null: false
    t.boolean "lida", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "usuario_id", null: false
    t.bigint "pedido_id"
    t.index ["pedido_id"], name: "index_mensagems_on_pedido_id"
    t.index ["usuario_id"], name: "index_mensagems_on_usuario_id"
  end

  create_table "notas_olfativas", force: :cascade do |t|
    t.bigint "produto_id", null: false
    t.string "nome", null: false
    t.string "nivel", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["produto_id"], name: "index_notas_olfativas_on_produto_id"
  end

  create_table "pedidos", force: :cascade do |t|
    t.bigint "usuario_id", null: false
    t.decimal "valor_total"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cep"
    t.string "estado"
    t.string "cidade"
    t.string "bairro"
    t.string "rua"
    t.string "numero_casa"
    t.string "complemento"
    t.string "ponto_referencia"
    t.string "telefone_entrega"
    t.decimal "subtotal", precision: 12, scale: 2
    t.decimal "desconto_percentual", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "desconto_valor", precision: 12, scale: 2, default: "0.0", null: false
    t.boolean "brinde_incluso", default: false, null: false
    t.string "brinde_descricao"
    t.datetime "whatsapp_notificado_em"
    t.string "whatsapp_mensagem_id"
    t.boolean "frete_gratis", default: false, null: false
    t.string "pagamento_referencia"
    t.string "pagamento_id"
    t.string "pagamento_preferencia"
    t.text "pagamento_url"
    t.boolean "pagamento_teste"
    t.string "pagamento_status"
    t.string "pagamento_metodo"
    t.datetime "pago_em"
    t.decimal "valor_frete", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "reserva_expira_em"
    t.datetime "estoque_devolvido_em"
    t.string "cancelamento_motivo"
    t.string "transportadora"
    t.string "codigo_rastreio"
    t.date "prazo_entrega"
    t.datetime "enviado_em"
    t.datetime "entregue_em"
    t.boolean "pagamento_requer_atencao", default: false, null: false
    t.string "pagamento_order_id"
    t.index ["pagamento_id"], name: "index_pedidos_on_pagamento_id", unique: true
    t.index ["pagamento_order_id"], name: "index_pedidos_on_pagamento_order_id", unique: true
    t.index ["pagamento_referencia"], name: "index_pedidos_on_pagamento_referencia", unique: true
    t.index ["status", "reserva_expira_em"], name: "index_pedidos_on_status_and_reserva_expira_em"
    t.index ["usuario_id"], name: "index_pedidos_on_usuario_id"
  end

  create_table "produtos", force: :cascade do |t|
    t.string "nome"
    t.string "marca"
    t.string "descricao"
    t.string "categoria"
    t.string "tamanho"
    t.string "fragancia"
    t.string "intensidade"
    t.string "momento"
    t.decimal "preco", precision: 10, scale: 2
    t.integer "estoque"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "frasco_mae_id"
    t.string "piramide_olfativa"
    t.string "concentracao"
    t.boolean "destaque", default: false, null: false
    t.integer "uso_inverno"
    t.integer "uso_primavera"
    t.integer "uso_verao"
    t.integer "uso_outono"
    t.integer "uso_dia"
    t.integer "uso_noite"
    t.string "slug", null: false
    t.string "origem"
    t.string "publico"
    t.index ["frasco_mae_id"], name: "index_produtos_on_frasco_mae_id"
    t.index ["slug"], name: "index_produtos_on_slug", unique: true
    t.check_constraint "origem IS NULL OR (origem::text = ANY (ARRAY[''::character varying, 'arabe'::character varying, 'importado'::character varying, 'xerjoff'::character varying, 'nishane'::character varying, 'sospiro'::character varying]::text[]))", name: "produto_origem_valida"
    t.check_constraint "uso_dia >= 0 AND uso_dia <= 100", name: "produto_uso_dia_valido"
    t.check_constraint "uso_inverno >= 0 AND uso_inverno <= 100", name: "produto_uso_inverno_valido"
    t.check_constraint "uso_noite >= 0 AND uso_noite <= 100", name: "produto_uso_noite_valido"
    t.check_constraint "uso_outono >= 0 AND uso_outono <= 100", name: "produto_uso_outono_valido"
    t.check_constraint "uso_primavera >= 0 AND uso_primavera <= 100", name: "produto_uso_primavera_valido"
    t.check_constraint "uso_verao >= 0 AND uso_verao <= 100", name: "produto_uso_verao_valido"
  end

  create_table "usuarios", force: :cascade do |t|
    t.string "nome"
    t.string "email"
    t.string "role", default: "cliente"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "telefone"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "estado"
    t.string "cidade"
    t.string "bairro"
    t.string "cpf"
    t.string "cep"
    t.string "rua"
    t.string "numero_casa"
    t.string "complemento"
    t.string "ponto_referencia"
    t.index ["email"], name: "index_usuarios_on_email", unique: true
    t.index ["reset_password_token"], name: "index_usuarios_on_reset_password_token", unique: true
  end

  create_table "variantes", force: :cascade do |t|
    t.bigint "produto_id", null: false
    t.string "tamanho", null: false
    t.decimal "preco", precision: 10, scale: 2, null: false
    t.integer "estoque", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "volume_lacrado_ml"
    t.index ["produto_id", "tamanho"], name: "index_variantes_on_produto_id_and_tamanho", unique: true
    t.index ["produto_id"], name: "index_variantes_on_produto_id"
  end

  add_check_constraint "variantes", "estoque >= 0", name: "estoque_variante_nao_negativo", validate: false

  create_table "videos_home", force: :cascade do |t|
    t.string "titulo", null: false
    t.string "arquivo_padrao"
    t.integer "ordem", default: 0, null: false
    t.boolean "ativo", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "avaliacoes", "produtos"
  add_foreign_key "avaliacoes", "usuarios"
  add_foreign_key "carrinhos", "usuarios"
  add_foreign_key "identidades_sociais", "usuarios"
  add_foreign_key "itens_carrinhos", "carrinhos"
  add_foreign_key "itens_carrinhos", "produtos"
  add_foreign_key "itens_carrinhos", "variantes"
  add_foreign_key "itens_pedidos", "pedidos"
  add_foreign_key "itens_pedidos", "produtos"
  add_foreign_key "itens_pedidos", "variantes"
  add_foreign_key "mensagems", "pedidos"
  add_foreign_key "mensagems", "usuarios"
  add_foreign_key "notas_olfativas", "produtos"
  add_foreign_key "pedidos", "usuarios"
  add_foreign_key "produtos", "frasco_maes"
  add_foreign_key "variantes", "produtos"
end
