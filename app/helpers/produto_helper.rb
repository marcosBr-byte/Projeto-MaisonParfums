module ProdutoHelper
  def caminho_categoria_produto(produto)
    rotas = {
      "masculino" => :decants_masculinos_path,
      "feminino" => :decants_femininos_path,
      "unissex" => :decants_unissex_path,
      "nicho" => :decants_nicho_path,
      "body_splash" => :body_splash_path,
      "hidratante" => :hidratantes_path
    }
    public_send(rotas.fetch(produto.categoria, :produtos_todos_path))
  end

  def rotulo_tamanho_variante(variante)
    if variante.produto.cuidados_corporais? && variante.lacrado? && variante.volume_ml.present?
      return "#{variante.volume_ml} ml"
    end

    Variante.tamanhos.fetch(variante.tamanho, variante.tamanho)
  end

  def estrelas_avaliacao(nota)
    preenchidas = nota.to_f.round.clamp(0, 5)
    tag.span(class: "product-stars", role: "img", aria: { label: "#{nota.to_f.round(1)} de 5 estrelas" }) do
      safe_join((1..5).map { |indice| tag.span("★", class: indice <= preenchidas ? "" : "star-empty", aria: { hidden: true }) })
    end
  end

  def ilustracao_nota(nome)
    normalizado = I18n.transliterate(nome.to_s).downcase
    { "pera" => "🍐", "melao" => "🍈", "rosa" => "🌹", "fresia" => "🌼", "jasmim" => "🌼",
      "laranja" => "🍊", "bergamota" => "🍊", "limao" => "🍋", "baunilha" => "🌿",
      "patchouli" => "🌿", "sandalo" => "🪵", "cedro" => "🪵", "ambar" => "🟠", "lavanda" => "🪻" }.find { |ingrediente, _| normalizado.include?(ingrediente) }&.last || "🌿"
  end
end
