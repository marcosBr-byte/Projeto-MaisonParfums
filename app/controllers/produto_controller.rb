class ProdutoController < ApplicationController
  layout "admin", only: %i[new create edit update]

  before_action :exigir_admin, only: %i[new create edit update destroy]
  before_action :set_produto, only: %i[show edit update destroy]

  def decants_masculinos
    @produtos = Produto.where("categoria ILIKE ?", "masculino").order(:nome)
  end

  def decants_femininos
    @produtos = Produto.where("categoria ILIKE ?", "feminino").order(:nome)
  end

  def show; end

  def new
    @produto = Produto.new
  end

  def create
    @produto = Produto.new(produto_params)
    if @produto.save
      redirect_to admin_path, notice: "Produto criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @produto.update(produto_params)
      redirect_to admin_path, notice: "Produto atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @produto.destroy
    redirect_to admin_path, notice: "Produto excluído com sucesso."
  end

  private

  def set_produto
    @produto = Produto.find(params[:id])
  end

  def produto_params
    params.require(:produto).permit(:nome, :marca, :descricao, :categoria, :tamanho, :fragancia, :intensidade, :momento, :piramide_olfativa, :concentracao, :preco, :estoque, :frasco_mae_id, :imagem)
  end
end