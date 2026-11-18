class SepararCategoriaEOrigemNicho < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :produtos, name: "produto_origem_valida"
    execute <<~SQL
      UPDATE produtos SET categoria = 'Nicho', origem = CASE
        WHEN marca ILIKE '%Xerjoff%' THEN 'xerjoff'
        WHEN marca ILIKE '%Nishane%' THEN 'nishane'
        WHEN marca ILIKE '%Sospiro%' THEN 'sospiro'
        ELSE NULL END
      WHERE origem = 'nicho' OR ((origem IS NULL OR origem = '') AND marca ILIKE ANY (ARRAY['%Xerjoff%', '%Nishane%', '%Sospiro%']))
    SQL
    add_check_constraint :produtos, "origem IS NULL OR origem IN ('', 'arabe', 'importado', 'xerjoff', 'nishane', 'sospiro')", name: "produto_origem_valida"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "A categoria anterior dos perfumes de nicho não foi preservada."
  end
end
