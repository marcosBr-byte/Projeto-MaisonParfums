class HomeController < ApplicationController
  def index
    produtos_vendidos = ItemPedido.joins(:pedido, :produto).where(pedidos: { status: :pago }).group("produtos.id").order(Arel.sql("SUM(itens_pedidos.quantidade) DESC"))
    @mais_vendidos_masculinos = produtos_vendidos.where(produtos: { categoria: "masculino" }).limit(4)
    @mais_vendidos_femininos = produtos_vendidos.where(produtos: { categoria: "feminino" }).limit(4)
  end
end
