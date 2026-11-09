class Produto < ApplicationRecord
  has_many :itens_carrinho, dependent: :destroy
  has_many :carrinhos, through: :itens_carrinho
  has_many :itens_pedidos, class_name: "ItemPedido", dependent: :destroy
  has_many :pedidos, through: :itens_pedidos
  has_many :variantes, dependent: :destroy
  belongs_to :frasco_mae, optional: true
  has_one_attached :imagem

  accepts_nested_attributes_for :variantes,
    reject_if: ->(a) { a["id"].blank? && a["preco"].blank? }

  validates :nome, presence: true
  validates :preco, presence: true, numericality: { greater_than: 0 }
  validate :decants_exigem_frasco_mae

  before_validation :sincronizar_preco

  after_create_commit do
    broadcast_prepend_to "produtos_#{categoria}", target: "produtos", partial: "produto/produto", locals: { produto: self }
  end

  enum :categoria, {
    feminino: "Feminino",
    masculino: "Masculino",
    unissex: "Unissex"
  }

  enum :tamanho, {
    tamanho_2ml: "2ml",
    tamanho_5ml: "5ml",
    tamanho_10ml: "10ml",
    lacrado: "Lacrado"
  }

  enum :fragancia, {
    floral: "Floral",
    cítrica: "Cítrica",
    amadeirada: "Amadeirada",
    oriental: "Oriental",
    fougère: "Fougère",
    chipre: "Chipre",
    gourmand: "Gourmand",
    aromática: "Aromática",
    aquática: "Aquática"
  }

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

  def decant?
    frasco_mae.present? && volume_ml.present?
  end

  def disponivel?(qtd = 1)
    decant? ? frasco_mae.estoque_ml >= volume_ml * qtd : estoque.to_i >= qtd
  end

  def quantidade_maxima
    return estoque.to_i unless decant?
    frasco_mae.estoque_ml / volume_ml
  end

  def baixar_estoque!(qtd)
    alvo = decant? ? frasco_mae : self
    alvo.with_lock do
      raise "Estoque insuficiente de #{nome}" unless disponivel?(qtd)
      if decant?
        frasco_mae.update!(estoque_ml: frasco_mae.estoque_ml - volume_ml * qtd)
      else
        update!(estoque: estoque - qtd)
      end
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
       self.class.defined_enums[campo.to_s][public_send(campo)]
  end
  
  private

  def decants_exigem_frasco_mae
    tamanhos_decant = %w[tamanho_2ml tamanho_5ml tamanho_10ml]

    possui_decant = variantes.any? do |variante|
      tamanhos_decant.include?(variante.tamanho) && variante.preco.present?
    end

    if possui_decant && frasco_mae.blank?
      errors.add(:frasco_mae, "deve ser selecionado para vender decants")
    end
  end

  def sincronizar_preco
    menor = preco_minimo
    self.preco = menor if menor
  end

end
