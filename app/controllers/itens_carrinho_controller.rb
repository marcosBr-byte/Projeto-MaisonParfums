class ItensCarrinhoController < ApplicationController
  before_action :authenticate_usuario!
  before_action :bloquear_admin

  def create
    @carrinho = current_usuario.carrinho || current_usuario.create_carrinho

    produto = Produto.find(params[:produto_id])
    variante = produto.variantes.find(params[:variante_id])

    item = @carrinho.itens_carrinhos.find_or_initialize_by(produto: produto, variante: variante)

    quantidade = Integer(params[:quantidade], 10)
    item.quantidade = item.quantidade.to_i + quantidade

    if item.save
      redirect_to carrinho_path, notice: "Produto adicionado ao carrinho!"
    else
      redirect_to produto_path(produto), alert: item.errors.full_messages.to_sentence
    end

  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Produto ou tamanho não encontrado."
  rescue ArgumentError, TypeError
    redirect_to root_path, alert: "Quantidade inválida."
  end

  def update
      item = current_usuario.carrinho&.itens_carrinhos&.find(params[:id])

      if item.nil?
        redirect_to carrinho_path, alert: "Item não encontrado."
        return
      end

      quantidade = Integer(params[:quantidade], 10)

      if quantidade <= 0
        redirect_to carrinho_path, alert: "A quantidade deve ser maior que zero."
        return
      end

      item.quantidade = quantidade

      if item.save
        redirect_to carrinho_path, notice: "Quantidade atualizada!"
      else
        redirect_to carrinho_path, alert: item.errors.full_messages.to_sentence
      end

    rescue ArgumentError, TypeError
      redirect_to carrinho_path, alert: "Quantidade inválida."
  end

  def destroy
    item = current_usuario.carrinho&.itens_carrinhos&.find(params[:id])

    if item
      item.destroy
      redirect_to carrinho_path, notice: "Produto removido do carrinho."
    else
      redirect_to carrinho_path, alert: "Item não encontrado."
    end
  end

  private

  def bloquear_admin
    if current_usuario.admin?
      redirect_to root_path, alert: "Administradores não podem realizar compras."
    end
  end
end