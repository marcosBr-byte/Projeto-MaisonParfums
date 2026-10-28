class AdminController < ApplicationController
  before_action :authenticate_usuario!, only: [:index] # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets
  before_action :exigir_admin, only: [:index] # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets
  def index
     @produtos = Produto.order(:nome)
  end

   def show
    @usuario = current_usuario
  end
end
