class AdminController < ApplicationController
  layout "admin", only: [:index]
  before_action :authenticate_usuario!
  before_action :exigir_admin

  def index
    @total_pedidos = Pedido.count
    @total_usuarios = Usuario.count
    @total_produtos = Produto.count
    @pedidos_pendentes = Pedido.where(status: "pendente").count
    @ultimos_pedidos = Pedido.includes(:usuario).order(created_at: :desc).limit(5)
    @frascos = FrascoMae.order(:estoque_ml).limit(5)
  end

  def show
    @usuario = current_usuario
  end
end