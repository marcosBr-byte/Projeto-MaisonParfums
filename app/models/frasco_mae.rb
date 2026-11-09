class FrascoMae < ApplicationRecord
  has_many :produtos, dependent: :restrict_with_error

  validates :nome, presence: true
  validates :estoque_ml, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end