class AtualizarBorrifadasPorMl < ActiveRecord::Migration[8.1]
  def change
    change_column_default :configuracaos, :borrifadas_por_ml, from: 10, to: 16

    reversible do |direction|
      direction.up do
        execute "UPDATE configuracaos SET borrifadas_por_ml = 16 WHERE borrifadas_por_ml = 10"
      end
    end
  end
end
