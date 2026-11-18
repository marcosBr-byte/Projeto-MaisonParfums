class IdentidadeSocial < ApplicationRecord
  self.table_name = "identidades_sociais"
  belongs_to :usuario, inverse_of: :identidades_sociais
  validates :provider, inclusion: { in: %w[google_oauth2 facebook] }
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :provider, uniqueness: { scope: :usuario_id }
end
