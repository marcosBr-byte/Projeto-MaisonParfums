module ApplicationHelper
  def imagem_loja(imagem, tamanho: :detalhe)
    return imagem if imagem.is_a?(String)
    blob = imagem.respond_to?(:blob) ? imagem.blob : imagem
    foto_path(chave: blob.key, tamanho: tamanho)
  end

  def configuracao_loja
    @configuracao_loja ||= Configuracao.atual
  end

  def total_brinde_flutuante
    return @total if controller_name == "carrinho" && action_name == "show" && @total
    return 0.to_d unless usuario_signed_in?

    itens = current_usuario.carrinho&.itens_carrinhos
    return 0.to_d unless itens

    itens.includes(:produto, :variante).sum { |item| item.preco_unitario(configuracao_loja) * item.quantidade }
  end

  def preco_loja(registro)
    registro.preco_venda(configuracao_loja)
  end

  def moeda_loja(valor)
    number_to_currency(valor, unit: "R$ ", separator: ",", delimiter: ".")
  end

  def rotulo_por_ml(variante)
    valor = variante&.preco_por_ml(configuracao_loja)
    valor ? "#{moeda_loja(valor)}/ml" : "Informe o volume para consultar o preço por ml"
  end

  def rotulo_borrifadas(variante)
    quantidade = variante&.borrifadas_estimadas(configuracao_loja)
    quantidade ? "Aproximadamente #{quantidade} borrifadas" : "Volume não informado"
  end
end
