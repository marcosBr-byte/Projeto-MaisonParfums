   class ItensCarrinho < ApplicationRecord
     belongs_to :carrinho
     belongs_to :produto
     belongs_to :variante, optional: true

     validates :quantidade, presence: true, numericality: { greater_than: 0 }
     validate :dentro_do_estoque

     # Preço unitário: da variante escolhida (ou do produto, nos itens antigos)
     def preco_unitario
       variante ? variante.preco : produto.preco
     end

     private

     def dentro_do_estoque
       item = variante || produto
       return unless item && quantidade
       max = item.quantidade_maxima
       return if quantidade <= max

       errors.add(:quantidade, max.zero? ? "produto esgotado" : "máximo de #{max} unidade(s) disponível(is)")
     end
   end