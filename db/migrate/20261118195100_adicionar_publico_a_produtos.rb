class AdicionarPublicoAProdutos < ActiveRecord::Migration[8.1]
  def change
    add_column :produtos, :publico, :string
  end
end
