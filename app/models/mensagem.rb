class Mensagem < ApplicationRecord
  has_rich_text :conteudo
  before_validation { self[:conteudo] = conteudo.to_plain_text }
  belongs_to :usuario
  belongs_to :pedido, optional: true
  validates :nome, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :assunto, presence: true, length: { maximum: 200 }
  validates :conteudo, presence: true
  validate { errors.add(:conteudo, "deve ter no máximo 10.000 caracteres") if conteudo.to_plain_text.length > 10_000 }

  scope :nao_lidas, -> { where(lida: false) }
  scope :recentes, -> { order(created_at: :desc) }
end
