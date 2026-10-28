class Usuario < ApplicationRecord
  has_one_attached :imagem
   
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  encrypts :telefone, :cpf, :cep, :rua, :numero_casa, :complemento, :ponto_referencia, :bairro, :cidade, :estado

  enum :role, {
     cliente: "cliente",
     admin: "admin"
    }

  ESTADOS = %w[AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI RJ RN RS RO RR SC SP SE TO].freeze

  validates :estado, inclusion: { in: ESTADOS }, allow_blank: true
  validates :nome, presence: true
  validates :telefone, presence: true

  
end
