class Perfume < ApplicationRecord
  has_many :itens_carrinho, dependent: :destroy
  has_many :carrinhos, through: :itens_carrinho
  has_many :itens_pedidos, dependent: :destroy
  has_many :pedidos, through: :itens_pedidos

  validates :nome, presence: true
  validates :preco, presence: true, numericality: { greater_than: 0 }

  enum :fragancia, {
    floral: "floral",
    amadeirada: "amadeirada",
    citrica: "citrica",
    oriental: "oriental",
    fougere: "fougere",
    chipre: "chipre",
    gourmand: "gourmand",
    aromatica: "aromatica",
    aquatica: "aquatica"
  }
  enum :categoria, {
    feminino: "feminino",
    masculino: "masculino",
    unissex: "unissex"
  }

  enum :tamanho, {
    tamanho_2ml: "tamanho_2ml",
    tamanho_5ml: "tamanho_5ml",
    tamanho_10ml: "tamanho_10ml",
    lacrado: "lacrado"
  }

  enum :momento, {
    dia: "dia",
    noite: "noite",
    ambos: "ambos"
  }

  enum :intensidade, {
    baixa: "baixa",
    media: "media",
    alta: "alta"
  }
end
