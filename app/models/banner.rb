class Banner < ApplicationRecord
  include OtimizaImagens
  has_one_attached :imagem
  otimizar_anexos :imagem, limite: 2400

  ATALHOS = {
    "atalho_masculino" => [ "Decantes Masculinos", "male" ],
    "atalho_feminino" => [ "Decantes Femininos", "female" ],
    "atalho_nicho" => [ "Decantes Nicho", "diamond" ]
  }.freeze

  validates :chave, presence: true, uniqueness: true
  before_validation { self.titulo = "" if titulo.nil? }
  validates :ordem, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  ROTULOS = {
    "mais_vendidos" => "Destaques da loja", "frete" => "Envio para o Brasil",
    "amostra" => "Amostra de presente — carrossel principal",
    "quiz" => "Descubra seu perfume", "masculino" => "Decantes masculinos",
    "feminino" => "Decantes femininos", "nicho" => "Decantes de nicho",
    "experiencia" => "Foto da seção Uma experiência em cada fragrância"
  }.freeze

  def rotulo
    return "Atalho circular · #{ATALHOS[chave].first}" if ATALHOS.key?(chave)
    ROTULOS.fetch(chave, "Banner da loja")
  end

  IMAGENS_PADRAO = {
    "mais_vendidos" => "slide-mais-vendidos.jpeg",
    "frete" => "slide-frete.jpeg",
    "quiz" => "slide-quiz.jpeg",
    "masculino" => "destaques-masculino.jpeg",
    "feminino" => "destaque-feminino.jpeg"
  }.freeze

  def imagem_exibicao
    return imagem if imagem.attached? && imagem.blob.persisted?

    # Uma validação recusada pode deixar um upload ainda sem signed_id.
    anterior = persisted? && ActiveStorage::Attachment.find_by(record: self, name: "imagem")
    anterior ? anterior : IMAGENS_PADRAO[chave]
  end

  scope :ativos, -> { where(ativo: true).order(:ordem) }
end
