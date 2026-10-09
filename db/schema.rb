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

ActiveRecord::Schema[8.1].define(version: 2026_10_09_131749) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "carrinhos", force: :cascade do |t|
    t.bigint "usuario_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["usuario_id"], name: "index_carrinhos_on_usuario_id"
  end

  create_table "itens_carrinhos", force: :cascade do |t|
    t.bigint "carrinho_id", null: false
    t.bigint "perfume_id", null: false
    t.integer "quantidade"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["carrinho_id"], name: "index_itens_carrinhos_on_carrinho_id"
    t.index ["perfume_id"], name: "index_itens_carrinhos_on_perfume_id"
  end

  create_table "itens_pedidos", force: :cascade do |t|
    t.bigint "pedido_id", null: false
    t.bigint "perfume_id", null: false
    t.integer "quantidade"
    t.decimal "preco_unitario"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pedido_id"], name: "index_itens_pedidos_on_pedido_id"
    t.index ["perfume_id"], name: "index_itens_pedidos_on_perfume_id"
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

  add_foreign_key "carrinhos", "usuarios"
  add_foreign_key "itens_carrinhos", "carrinhos"
  add_foreign_key "itens_carrinhos", "perfumes"
  add_foreign_key "itens_pedidos", "pedidos"
  add_foreign_key "itens_pedidos", "perfumes"
  add_foreign_key "pedidos", "usuarios"
end
