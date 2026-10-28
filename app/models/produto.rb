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

  # "tamanho_5ml" -> "5ml" -> 5 | "Lacrado" -> nil
  def volume_ml
    v = self.class.tamanhos[tamanho].to_i
    v.positive? ? v : nil
  end

  def decant?
    frasco_mae.present? && volume_ml.present?
  end

  # RN02: tem líquido suficiente para essa quantidade?
  def disponivel?(qtd = 1)
    decant? ? frasco_mae.estoque_ml >= volume_ml * qtd : estoque.to_i >= qtd
  end

  # RN02: quantidade máxima que o estoque permite
  def quantidade_maxima
    return estoque.to_i unless decant?
    frasco_mae.estoque_ml / volume_ml
  end

  # RN01: baixa o estoque (chame quando o pedido for pago)
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

  # Menor preço entre os tamanhos (usado em "a partir de")
  def preco_minimo
    variantes.map(&:preco).compact.min
  end

  # Monta uma linha em branco para cada tamanho que ainda não existe (usado no formulário)
  def montar_variantes
    Variante.tamanhos.each_key do |k|
      variantes.build(tamanho: k) unless variantes.map(&:tamanho).include?(k)
    end
  end

  def rotulo(campo)
       self.class.defined_enums[campo.to_s][public_send(campo)]
  end
  
  private

  # Mantém produtos.preco igual ao menor preço das variantes,
  # assim o site atual (cards, busca, carrinho) continua funcionando
  def sincronizar_preco
    menor = preco_minimo
    self.preco = menor if menor
  end

  
end