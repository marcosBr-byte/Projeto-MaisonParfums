class NotaOlfativa < ApplicationRecord
  include OtimizaImagens
  self.table_name = "notas_olfativas"
  belongs_to :produto
  has_one_attached :imagem
  otimizar_anexos :imagem, limite: 800
  enum :nivel, { topo: "topo", coracao: "coracao", base: "base" }, validate: true
  validates :nome, presence: true, length: { maximum: 80 }
  validates :nivel, presence: true
  validate :validar_imagem

  private

  def validar_imagem
    return unless imagem.attached?
    errors.add(:imagem, "use JPG, PNG ou WebP de até 5 MB") unless
      imagem.blob.content_type.in?(%w[image/jpeg image/png image/webp]) && imagem.blob.byte_size <= 5.megabytes
  end
end
