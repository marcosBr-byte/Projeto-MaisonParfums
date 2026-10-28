   class ItemPedido < ApplicationRecord
     self.table_name = "itens_pedidos"

     belongs_to :pedido
     belongs_to :produto
     belongs_to :variante, optional: true

     validates :quantidade, presence: true, numericality: { greater_than: 0 }
   end