class Mensagem < ApplicationRecord
  belongs_to :usuario
  belongs_to :pedido, optional: true
  validates :nome, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :assunto, presence: true
  validates :conteudo, presence: true

  scope :nao_lidas, -> { where(lida: false) }
  scope :recentes, -> { order(created_at: :desc) }
end