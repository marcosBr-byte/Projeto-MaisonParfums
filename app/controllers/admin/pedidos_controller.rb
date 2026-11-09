module Admin
  class PedidosController < ApplicationController
    layout "admin"

    before_action :authenticate_usuario!
    before_action :exigir_admin

    def index
      @status = params[:status].presence_in(Pedido.defined_enums["status"].keys)

      @pedidos = Pedido.includes(:usuario).order(created_at: :desc)
      @pedidos = @pedidos.where(status: @status) if @status
    end

    def show
      @pedido = Pedido.includes(:usuario, itens_pedidos: [:produto, :variante]).find(params[:id])
    end
  end
end