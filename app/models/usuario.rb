class Usuario < ApplicationRecord
  include OtimizaImagens
  has_many :identidades_sociais, class_name: "IdentidadeSocial", dependent: :destroy, inverse_of: :usuario
  has_many :avaliacoes, class_name: "Avaliacao", dependent: :destroy
  has_many :mensagens, class_name: "Mensagem", dependent: :destroy
  has_one :carrinho, dependent: :destroy
  has_many :pedidos, dependent: :destroy
  has_one_attached :imagem
  otimizar_anexos :imagem, limite: 800
   
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable,
         omniauth_providers: Devise.omniauth_configs.keys

  encrypts :telefone, :cpf, :cep, :rua, :numero_casa, :complemento, :ponto_referencia, :bairro, :cidade, :estado

  enum :role, {
     cliente: "cliente",
     admin: "admin"
    }

  ESTADOS = %w[AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI RJ RN RS RO RR SC SP SE TO].freeze

  validates :estado, inclusion: { in: ESTADOS }, allow_blank: true
  validates :nome, presence: true
  validates :telefone, presence: true, unless: -> { admin? || identidades_sociais.any? }

  def perfil_completo?
    [telefone, cep, estado, cidade, bairro, rua, numero_casa].all?(&:present?)
  end
  
end
