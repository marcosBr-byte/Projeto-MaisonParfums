class ConfigurarAmostraPromocional < ActiveRecord::Migration[8.1]
  def up
    change_column_default :configuracaos, :brinde_meta, from: 199, to: 200
    change_column_default :configuracaos, :brinde_descricao,
      from: "Um brinde especial da Maison Parfum", to: "1 amostra exclusiva da Maison Parfum"
    execute <<~SQL
      UPDATE configuracaos
      SET brinde_ativo = TRUE, brinde_meta = 200,
          brinde_descricao = '1 amostra exclusiva da Maison Parfum'
    SQL
  end

  def down
    change_column_default :configuracaos, :brinde_meta, from: 200, to: 199
    change_column_default :configuracaos, :brinde_descricao,
      from: "1 amostra exclusiva da Maison Parfum", to: "Um brinde especial da Maison Parfum"
  end
end
