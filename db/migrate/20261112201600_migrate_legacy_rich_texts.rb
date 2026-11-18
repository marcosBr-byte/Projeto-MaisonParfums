class MigrateLegacyRichTexts < ActiveRecord::Migration[8.1]
  def up
    { "produtos" => ["Produto", "descricao"], "configuracaos" => ["Configuracao", "descricao"], "mensagems" => ["Mensagem", "conteudo"] }.each do |tabela, (tipo, campo)|
      execute <<~SQL
        INSERT INTO action_text_rich_texts (record_type, record_id, name, body, created_at, updated_at)
        SELECT #{connection.quote(tipo)}, id, #{connection.quote(campo)},
          '<div>' || replace(replace(replace(replace(#{campo}, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), E'\n', '<br>') || '</div>',
          CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        FROM #{tabela}
        WHERE #{campo} IS NOT NULL AND #{campo} <> ''
        AND NOT EXISTS (SELECT 1 FROM action_text_rich_texts r WHERE r.record_type = #{connection.quote(tipo)} AND r.record_id = #{tabela}.id AND r.name = #{connection.quote(campo)})
      SQL
    end
  end

  def down
    # O conteúdo permanece preservado nas colunas de texto originais.
  end
end
