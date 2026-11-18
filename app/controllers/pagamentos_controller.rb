class PagamentosController < ApplicationController
  before_action :authenticate_usuario!
  before_action :carregar_pedido

  def show
  end

  def create
    url = MercadoPagoCheckout.new.criar(@pedido)
    uri = URI.parse(url)
    if uri.host == "sandbox.mercadopago.com.br"
      redirect_to "https://sandbox.mercadopago.com.br#{uri.request_uri}", allow_other_host: true, status: :see_other
    else
      redirect_to "https://www.mercadopago.com.br#{uri.request_uri}", allow_other_host: true, status: :see_other
    end
  rescue MercadoPagoCheckout::Erro => erro
    redirect_to pagamento_pedido_path(@pedido), alert: erro.message
  end

  private

  def carregar_pedido
    @pedido = current_usuario.pedidos.find(params[:pedido_id])
  end
end
