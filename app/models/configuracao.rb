class Configuracao < ApplicationRecord
  def self.atual
    first_or_create!
  end
end