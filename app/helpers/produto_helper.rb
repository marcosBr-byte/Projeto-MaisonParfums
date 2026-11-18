module ProdutoHelper
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
