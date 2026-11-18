class PermitirOrigemNicho < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :produtos, name: "produto_origem_valida"
    add_check_constraint :produtos, "origem IS NULL OR origem IN ('', 'arabe', 'importado', 'nicho')", name: "produto_origem_valida"
  end

  def down
    execute "UPDATE produtos SET origem = NULL WHERE origem = 'nicho'"
    remove_check_constraint :produtos, name: "produto_origem_valida"
    add_check_constraint :produtos, "origem IS NULL OR origem IN ('', 'arabe', 'importado')", name: "produto_origem_valida"
  end
end
