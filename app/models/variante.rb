   class Variante < ApplicationRecord
     belongs_to :produto

     enum :tamanho, {
       tamanho_2ml: "2ml",
       tamanho_5ml: "5ml",
       tamanho_10ml: "10ml",
       lacrado: "Lacrado"
     }

     validates :tamanho, presence: true, uniqueness: { scope: :produto_id }
     validates :preco, presence: true, numericality: { greater_than: 0 }

     def volume_ml
       v = self.class.tamanhos[tamanho].to_i
       v.positive? ? v : nil
     end

     def decant?
       produto.frasco_mae.present? && volume_ml.present?
     end

     def disponivel?(qtd = 1)
       decant? ? produto.frasco_mae.estoque_ml >= volume_ml * qtd : estoque.to_i >= qtd
     end

     def quantidade_maxima
       return estoque.to_i unless decant?
       produto.frasco_mae.estoque_ml / volume_ml
     end

     def baixar_estoque!(qtd)
       alvo = decant? ? produto.frasco_mae : self
       alvo.with_lock do
         raise "Estoque insuficiente de #{produto.nome}" unless disponivel?(qtd)
         if decant?
           produto.frasco_mae.update!(estoque_ml: produto.frasco_mae.estoque_ml - volume_ml * qtd)
         else
           update!(estoque: estoque - qtd)
         end
       end
     end
   end