class Banner < ApplicationRecord
 has_one_attached :imagem

  validates :chave, presence: true, uniqueness: true
  validates :titulo, presence: true

  scope :ativos, -> { where(ativo: true).order(:ordem) }
end
