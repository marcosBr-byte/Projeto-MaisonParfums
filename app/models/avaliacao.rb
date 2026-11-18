class Avaliacao < ApplicationRecord
  include OtimizaImagens
  self.table_name = "avaliacoes"
  belongs_to :produto
  belongs_to :usuario
  has_many_attached :fotos
  otimizar_anexos :fotos
  scope :publicadas, -> { where(publicada: true) }
  validates :usuario_id, uniqueness: { scope: :produto_id, message: "você já enviou uma avaliação para este perfume" }
  validates :nota, numericality: { only_integer: true, in: 1..5 }
  validates :comentario, presence: true, length: { maximum: 3000 }
  validate :validar_fotos
  before_validation { self.publicada = false if conteudo_ofensivo? }

  def conteudo_ofensivo?
    ConteudoOfensivo.detectado?(comentario)
  end

  private

  def validar_fotos
    errors.add(:fotos, "envie até 4 imagens") if fotos.size > 4
    fotos.each do |foto|
      unless foto.blob.content_type.in?(%w[image/jpeg image/png image/webp]) && foto.blob.byte_size <= 5.megabytes
        errors.add(:fotos, "use JPG, PNG ou WebP de até 5 MB por foto")
      end
    end
  end
end
