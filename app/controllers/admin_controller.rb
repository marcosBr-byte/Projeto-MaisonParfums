class AdminController < ApplicationController
  before_action :authenticate_usuario!, only: [:index] # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets
  before_action :exigir_admin, only: [:index] # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets
  def index
    @produtos = Produto.order(:nome)
    @pedidos = Pedido.includes(:usuario).order(created_at: :desc)
    @total_pedidos = Pedido.count
    @total_usuarios = Usuario.count
    @total_produtos = Produto.count
    @ultimos_pedidos = Pedido.includes(:usuario).order(created_at: :desc).limit(4)
  end

   def show
    @usuario = current_usuario
  end
end
