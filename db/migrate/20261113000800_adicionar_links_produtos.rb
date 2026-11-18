class AdicionarLinksProdutos < ActiveRecord::Migration[8.1]
  def up
    add_column :produtos, :slug, :string
    produtos = Class.new(ActiveRecord::Base) { self.table_name = "produtos" }
    produtos.reset_column_information
    usados = Set.new
    produtos.order(:id).find_each do |produto|
      base = produto.nome.to_s.parameterize.first(100).sub(/-+\z/, "").presence || "perfume"
      base = "perfume-#{base}" if base.match?(/\A\d+\z/) || %w[new edit].include?(base)
      slug = base
      slug = "#{base}-#{SecureRandom.hex(4)}" while usados.include?(slug)
      produto.update_columns(slug: slug)
      usados.add(slug)
    end
    change_column_null :produtos, :slug, false
    add_index :produtos, :slug, unique: true
  end

  def down
    remove_column :produtos, :slug
  end
end
