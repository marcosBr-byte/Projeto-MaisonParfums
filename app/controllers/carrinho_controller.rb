class CarrinhoController < ApplicationController
  before_action :authenticate_usuario!
  before_action :bloquear_admin

  def show
    @carrinho = current_usuario.carrinho || current_usuario.create_carrinho
    @itens = @carrinho.itens_carrinhos.includes(:produto, :variante)
    @configuracao = Configuracao.atual
    @subtotal = @itens.sum { |item| (item.variante || item.produto).preco * item.quantidade }
    @total = @itens.sum { |item| item.preco_unitario(@configuracao) * item.quantidade }
    @frete = if @configuracao.frete_pago_valor.present? && !@configuracao.frete_gratis_liberado?(@total, cep: current_usuario.cep, estado: current_usuario.estado)
      @configuracao.frete_pago_valor
    else
      0.to_d
    end
    @total_pagamento = @total + @frete
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

    pedido = nil
    carrinho.with_lock do
      if carrinho.itens_carrinhos.empty?
        redirect_to carrinho_path, alert: "Seu carrinho já foi finalizado."
        return
      end
      configuracao = Configuracao.atual
      configuracao.lock!
      pedido = current_usuario.pedidos.create!(status: :pendente, valor_total: 0, cep: current_usuario.cep, estado: current_usuario.estado, cidade: current_usuario.cidade, bairro: current_usuario.bairro, rua: current_usuario.rua, numero_casa: current_usuario.numero_casa, complemento: current_usuario.complemento, ponto_referencia: current_usuario.ponto_referencia, telefone_entrega: current_usuario.telefone)
      total = 0
      subtotal_original = 0
      carrinho.itens_carrinhos.includes(:produto, :variante).order(:variante_id, :id).each do |item|
        (item.variante || item.produto).baixar_estoque!(item.quantidade)
        subtotal_original += (item.variante || item.produto).preco * item.quantidade
        preco = item.preco_unitario(configuracao)
        subtotal = preco * item.quantidade
        pedido.itens_pedidos.create!(produto: item.produto, variante: item.variante, quantidade: item.quantidade, preco_unitario: preco)
        total += subtotal
      end

      gratis = configuracao.frete_gratis_liberado?(total, cep: pedido.cep, estado: pedido.estado)
      frete = configuracao.frete_pago_valor.present? && !gratis ? configuracao.frete_pago_valor : 0.to_d
      pedido.update!(valor_total: total + frete, valor_frete: frete, subtotal: subtotal_original,
        frete_gratis: configuracao.frete_gratis_liberado?(total, cep: pedido.cep, estado: pedido.estado),
        desconto_percentual: configuracao.percentual_vigente, desconto_valor: subtotal_original - total,
        brinde_incluso: configuracao.brinde_liberado?(total),
        brinde_descricao: configuracao.brinde_liberado?(total) ? configuracao.brinde_descricao : nil)
      carrinho.itens_carrinhos.destroy_all
    end

    if Configuracao.atual.pagamento_configurado?
      redirect_to pagamento_pedido_path(pedido), notice: "Pedido registrado. Escolha como pagar."
    else
      redirect_to root_path, notice: "Pedido realizado com sucesso! Aguarde a confirmação."
    end

  rescue ActiveRecord::RecordInvalid => e
    redirect_to carrinho_path, alert: "Não foi possível finalizar: #{e.message}"
  end

  private

  def bloquear_admin
    if current_usuario.admin?
      redirect_to root_path, alert: "Você está usando uma conta de administrador. Para acessar o carrinho e comprar, entre com uma conta de cliente."
    end
  end
end
