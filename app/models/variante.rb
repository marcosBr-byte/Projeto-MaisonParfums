class Variante < ApplicationRecord
  belongs_to :produto
  enum :tamanho, { tamanho_5ml: "5ml", tamanho_8ml: "8ml", tamanho_10ml: "10ml", tamanho_15ml: "15ml", lacrado: "Lacrado" }
  validates :tamanho, presence: true, uniqueness: { scope: :produto_id }
  validates :preco, numericality: { greater_than: 0 }
  validates :estoque, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :volume_lacrado_ml, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  def volume_ml
    lacrado? ? volume_lacrado_ml : self.class.tamanhos[tamanho].to_i.presence
  end

  def preco_venda(configuracao = Configuracao.atual)
    configuracao.preco_com_desconto(preco)
  end

  def preco_por_ml(configuracao = Configuracao.atual)
    preco_venda(configuracao) / volume_ml if volume_ml.to_i.positive?
  end

  def borrifadas_estimadas(configuracao = Configuracao.atual)
    volume_ml * configuracao.borrifadas_por_ml if volume_ml.to_i.positive?
  end

  def disponivel?(quantidade = 1)
    estoque.to_i >= quantidade
  end

  def quantidade_maxima
    estoque.to_i
  end

  def baixar_estoque!(quantidade)
    with_lock do
      unless quantidade.is_a?(Integer) && quantidade.positive? && disponivel?(quantidade)
        errors.add(:estoque, "insuficiente para #{produto.nome}")
        raise ActiveRecord::RecordInvalid, self
      end
      update!(estoque: estoque - quantidade)
    end
  end
end
