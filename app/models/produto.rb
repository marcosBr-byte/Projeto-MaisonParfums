class Produto < ApplicationRecord
  include OtimizaImagens
  ORIGENS = { "arabe" => "Árabes", "importado" => "Importados" }.freeze
  ORIGENS_NICHO = { "xerjoff" => "Xerjoff", "nishane" => "Nishane", "sospiro" => "Sospiro" }.freeze
  validates :origem, inclusion: { in: ->(produto) { produto.origens_disponiveis.keys } }, allow_blank: true

  def origens_disponiveis
    nicho? ? ORIGENS_NICHO : ORIGENS
  end

  before_validation :gerar_slug, on: :create
  validates :slug, presence: true, uniqueness: true

  def to_param
    slug.presence || super
  end

  def self.por_link!(valor)
    texto = valor.to_s
    texto.match?(/\A\d+\z/) ? find(texto) : find_by!(slug: texto)
  end

  def gerar_slug
    return if slug.present?
    base = nome.to_s.parameterize.first(100).sub(/-+\z/, "").presence || "perfume"
    base = "perfume-#{base}" if base.match?(/\A\d+\z/) || %w[new edit].include?(base)
    self.slug = base
    self.slug = "#{base}-#{SecureRandom.hex(4)}" while self.class.where(slug: slug).exists?
  end

  has_many :itens_carrinho, class_name: "ItensCarrinho", dependent: :destroy
  has_many :carrinhos, through: :itens_carrinho
  has_many :itens_pedidos, class_name: "ItemPedido", dependent: :destroy
  has_many :pedidos, through: :itens_pedidos
  has_many :variantes, dependent: :destroy
  belongs_to :frasco_mae, optional: true
  has_rich_text :descricao
  before_validation { self[:descricao] = descricao.to_plain_text }
  has_one_attached :imagem
  has_many_attached :fotos
  otimizar_anexos :imagem, :fotos
  has_many :notas_olfativas, class_name: "NotaOlfativa", dependent: :destroy
  has_many :avaliacoes, class_name: "Avaliacao", dependent: :destroy
  accepts_nested_attributes_for :notas_olfativas, allow_destroy: true,
    reject_if: ->(atributos) { atributos["id"].blank? && atributos["nome"].blank? && atributos["imagem"].blank? }

  USOS = {
    inverno: ["Inverno", "ac_unit"], primavera: ["Primavera", "local_florist"],
    verao: ["Verão", "beach_access"], outono: ["Outono", "eco"],
    dia: ["Dia", "light_mode"], noite: ["Noite", "dark_mode"]
  }.freeze
  USOS.each_key do |campo|
    validates "uso_#{campo}", numericality: { only_integer: true, in: 0..100 }, allow_nil: true
  end
  validate :validar_fotos_produto

  def validar_fotos_produto
    if imagem.attached? && (!imagem.blob.content_type.in?(ImagemOtimizada::TIPOS) || imagem.blob.byte_size > ImagemOtimizada::LIMITE_UPLOAD)
      errors.add(:imagem, "use JPG, PNG ou WebP de até 5 MB")
    end
    errors.add(:fotos, "envie até 8 fotos adicionais") if fotos.size > 8
    fotos.each do |foto|
      unless foto.blob.content_type.in?(%w[image/jpeg image/png image/webp]) && foto.blob.byte_size <= 5.megabytes
        errors.add(:fotos, "use JPG, PNG ou WebP de até 5 MB por foto")
      end
    end
  end
  scope :em_destaque, -> { where(destaque: true).order(:nome, :id) }

  accepts_nested_attributes_for :variantes,
    reject_if: ->(a) { a["id"].blank? && a["preco"].blank? }

  validates :nome, presence: true
  validates :preco, presence: true, numericality: { greater_than: 0 }

  before_validation :sincronizar_preco

  after_create_commit do
    broadcast_prepend_to "produtos_#{categoria}", target: "produtos", partial: "produto/produtos", locals: { produto: self }
  end

  enum :categoria, {
    feminino: "Feminino",
    masculino: "Masculino",
    unissex: "Unissex",
    nicho: "Nicho"
  }

  enum :tamanho, {
    tamanho_5ml: "5ml",
    tamanho_8ml: "8ml",
    tamanho_10ml: "10ml",
    tamanho_15ml: "15ml",
    lacrado: "Lacrado"
  }

  FRAGRANCIAS_SUGERIDAS = %w[Floral Cítrica Amadeirada Oriental Fougère Chipre Gourmand Aromática Aquática].freeze

  def fragrancias
    fragancia.to_s.split(/[,;]+/).map(&:strip).reject(&:blank?)
  end

  def fragancia=(valores)
    nomes = Array(valores).flat_map { |valor| valor.to_s.split(/[,;]+/) }.map(&:strip).reject(&:blank?)
    nomes = nomes.map do |nome|
      FRAGRANCIAS_SUGERIDAS.find { |sugerida| I18n.transliterate(sugerida).casecmp?(I18n.transliterate(nome)) } || nome
    end
    super(nomes.uniq { |nome| I18n.transliterate(nome).downcase }.join(", "))
  end

  enum :momento, {
    dia: "Dia",
    noite: "Noite",
    ambos: "Ambos"
  }

  enum :intensidade, {
    baixa: "Baixa",
    media: "Média",
    alta: "Alta"
  }

  enum :piramide_olfativa, {
    saida: "saida",
    coracao: "coracao",
    base: "base"
  }

  enum :concentracao, {
    parfum: "parfum",
    EDP: "EDP",
    EDT: "EDT",
    EDC: "EDC",
    splash: "splash"
  }

  def volume_ml
    v = self.class.tamanhos[tamanho].to_i
    v.positive? ? v : nil
  end

  def preco_venda(configuracao = Configuracao.atual)
    configuracao.preco_com_desconto(preco)
  end

  def disponivel?(qtd = 1)
    estoque.to_i >= qtd
  end

  def quantidade_maxima
    estoque.to_i
  end

  def baixar_estoque!(qtd)
    with_lock do
      unless qtd.is_a?(Integer) && qtd.positive? && disponivel?(qtd)
        errors.add(:estoque, "insuficiente ou quantidade inválida")
        raise ActiveRecord::RecordInvalid, self
      end
      update!(estoque: estoque - qtd)
    end
  end

  def preco_minimo
    variantes.map(&:preco).compact.min
  end

  def montar_variantes
    Variante.tamanhos.each_key do |k|
      variantes.build(tamanho: k) unless variantes.map(&:tamanho).include?(k)
    end
  end

  def rotulo(campo)
    return fragrancias.join(", ") if campo.to_sym == :fragancia
       self.class.defined_enums[campo.to_s][public_send(campo)]
  end
  
  private

  def sincronizar_preco
    menor = preco_minimo
    self.preco = menor if menor
  end

end
