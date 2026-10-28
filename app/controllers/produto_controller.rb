class ProdutoController < ApplicationController
  before_action :exigir_admin, only: %i[new create edit update destroy]
  before_action :set_produto, only: %i[show edit update destroy]

  def index
    @produtos = Produto.all
  end

  def pag_todos_prod
    @produtos = Produto.all
    render "produto/produtos_todos"
  end

  def decants_masculinos
    @produtos = Produto.where("categoria ILIKE ?", "masculino").order(:nome)
  end

  def decants_femininos
    @produtos = Produto.where("categoria ILIKE ?", "feminino").order(:nome)
  end

  def busca
    @termo = params[:q].to_s.strip
    @produtos = produtos_da_busca(@termo)
  end

  def sugestoes
    termo = params[:q].to_s.strip
    render partial: "produto/sugestoes", locals: { produtos: produtos_da_busca(termo).limit(4), termo: termo }
  end

  def show; end

  def new
    @produto = Produto.new
    @produto.montar_variantes
  end

  def create
    @produto = Produto.new(produto_params)
    if @produto.save
      redirect_to admin_path, notice: "Produto criado com sucesso."
    else
      @produto.montar_variantes
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @produto.montar_variantes
  end

  def update
    if @produto.update(produto_params)
      redirect_to admin_path, notice: "Produto atualizado com sucesso."
    else
      @produto.montar_variantes
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @produto.destroy
    redirect_to admin_path, notice: "Produto excluído com sucesso."
  end

  private
     
  def produtos_da_busca(termo)
    return Produto.none if termo.blank?

    padrao = "%#{Produto.sanitize_sql_like(termo)}%"
    Produto.where("nome ILIKE :t OR marca ILIKE :t OR descricao ILIKE :t", t: padrao).order(:nome)
  end

  def set_produto
    @produto = Produto.find(params[:id])
  end

  def produto_params
    params.require(:produto).permit(
      :nome, :marca, :descricao, :categoria, :fragancia, :intensidade,
      :momento, :frasco_mae_id, :imagem,
      variantes_attributes: [:id, :tamanho, :preco, :estoque]
    )
  end
end