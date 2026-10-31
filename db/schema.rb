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

ActiveRecord::Schema[8.1].define(version: 2026_10_29_121611) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "carrinhos", force: :cascade do |t|
    t.bigint "usuario_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["usuario_id"], name: "index_carrinhos_on_usuario_id"
  end

  create_table "frasco_maes", force: :cascade do |t|
    t.string "nome", null: false
    t.integer "estoque_ml", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "item_pedidos", force: :cascade do |t|
    t.bigint "pedido_id", null: false
    t.bigint "perfume_id", null: false
    t.integer "quantidade"
    t.decimal "preco_unitario"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pedido_id"], name: "index_item_pedidos_on_pedido_id"
    t.index ["perfume_id"], name: "index_item_pedidos_on_perfume_id"
  end

  create_table "itens_carrinhos", force: :cascade do |t|
    t.bigint "carrinho_id", null: false
    t.bigint "produto_id", null: false
    t.integer "quantidade"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["carrinho_id"], name: "index_itens_carrinhos_on_carrinho_id"
    t.index ["produto_id"], name: "index_itens_carrinhos_on_produto_id"
  end

  create_table "itens_pedidos", force: :cascade do |t|
    t.bigint "pedido_id", null: false
    t.bigint "produto_id", null: false
    t.integer "quantidade"
    t.decimal "preco_unitario"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pedido_id"], name: "index_itens_pedidos_on_pedido_id"
    t.index ["produto_id"], name: "index_itens_pedidos_on_produto_id"
  end

  create_table "pedidos", force: :cascade do |t|
    t.bigint "usuario_id", null: false
    t.decimal "valor_total"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["usuario_id"], name: "index_pedidos_on_usuario_id"
  end

  create_table "perfumes", force: :cascade do |t|
    t.string "model"
    t.string "nome"
    t.string "marca"
    t.string "descricao"
    t.string "categoria"
    t.decimal "preco"
    t.integer "estoque"
    t.string "tipo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "piramide"
    t.string "piramide_olfativa"
    t.string "concentracao"
    t.index ["frasco_mae_id"], name: "index_produtos_on_frasco_mae_id"
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
    t.index ["email"], name: "index_usuarios_on_email", unique: true
    t.index ["reset_password_token"], name: "index_usuarios_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "carrinhos", "usuarios"
  add_foreign_key "item_pedidos", "perfumes"
  add_foreign_key "itens_carrinhos", "carrinhos"
  add_foreign_key "itens_carrinhos", "produtos"
  add_foreign_key "itens_pedidos", "pedidos"
  add_foreign_key "itens_pedidos", "produtos"
  add_foreign_key "pedidos", "usuarios"
  add_foreign_key "produtos", "frasco_maes"
end
