class CarrinhoController < ApplicationController
  before_action :authenticate_usuario!
  before_action :bloquear_admin

  def show
    @carrinho = current_usuario.carrinho || current_usuario.create_carrinho
    @itens = @carrinho.itens_carrinhos.includes(:produto, :variante)
  end

  def limpar
    carrinho = current_usuario.carrinho
    if carrinho
      carrinho.itens_carrinhos.destroy_all
      redirect_to carrinho_path, notice: "Todos os itens foram removidos!"
    else
      redirect_to carrinho_path, alert: "Seu carrinho já está vazio."
    end
  end

  def finalizar
    carrinho = current_usuario.carrinho

    if carrinho.nil? || carrinho.itens_carrinhos.empty?
      redirect_to carrinho_path, alert: "Seu carrinho está vazio."
      return
    end

    unless current_usuario.perfil_completo?
      redirect_to perfil_path, alert: "Complete seus dados de entrega antes de finalizar o pedido."
      return
    end

    Pedido.transaction do
      pedido = current_usuario.pedidos.create!(status: :pendente, valor_total: 0, cep: current_usuario.cep, estado: current_usuario.estado, cidade: current_usuario.cidade, bairro: current_usuario.bairro, rua: current_usuario.rua, numero_casa: current_usuario.numero_casa, complemento: current_usuario.complemento, ponto_referencia: current_usuario.ponto_referencia, telefone_entrega: current_usuario.telefone)
      total = 0
      carrinho.itens_carrinhos.includes(:produto, :variante).each do |item|
        item.valid?

        raise ActiveRecord::RecordInvalid, item unless item.errors.empty?

        preco = item.preco_unitario
        subtotal = preco * item.quantidade
        pedido.itens_pedidos.create!(produto: item.produto, variante: item.variante, quantidade: item.quantidade, preco_unitario: preco)
        total += subtotal
      end

      pedido.update!(valor_total: total)
    end

    carrinho.itens_carrinhos.destroy_all

    redirect_to root_path, notice: "Pedido realizado com sucesso! Aguarde a confirmação."

  rescue ActiveRecord::RecordInvalid => e
    redirect_to carrinho_path, alert: "Não foi possível finalizar: #{e.message}"
  end

  private

  def bloquear_admin
    if current_usuario.admin?
      redirect_to root_path, alert: "Administradores não podem acessar o carrinho de compras."
    end
  end
end