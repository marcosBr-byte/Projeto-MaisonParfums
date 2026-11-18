class VideoHome < ApplicationRecord
  self.table_name = "videos_home"

  has_one_attached :arquivo

  ARQUIVOS_PADRAO = %w[video1.mp4 video2.mp4 video3.mp4 video4.mp4 video_parfum.mp4].freeze
  validates :titulo, presence: true, length: { maximum: 100 }
  validates :ordem, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :arquivo_padrao, inclusion: { in: ARQUIVOS_PADRAO }, allow_nil: true
  after_commit :agendar_otimizacao, on: %i[create update]
  validate :validar_arquivo

  scope :ordenados, -> { order(:ordem, :id) }
  scope :ativos, -> { where(ativo: true).ordenados }

  def pronto_para_exibir?
    arquivo.attached? ? arquivo.blob.metadata["maison_video_otimizado"] == true : arquivo_padrao.present?
  end

  private

  def agendar_otimizacao
    OtimizarVideoJob.perform_later(id, arquivo.blob_id) if arquivo.attached? && !pronto_para_exibir?
  end

  def validar_arquivo
    unless arquivo.attached? || arquivo_padrao.present?
      errors.add(:arquivo, "deve ser enviado")
      return
    end
    return unless arquivo.attached?

    unless %w[video/mp4 video/webm].include?(arquivo.blob.content_type)
      errors.add(:arquivo, "deve ser um vídeo MP4 ou WebM")
    end
    errors.add(:arquivo, "deve ter no máximo 100 MB") if arquivo.blob.byte_size > 100.megabytes
  end
end
