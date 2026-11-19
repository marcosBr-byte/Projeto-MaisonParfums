class RecomendadorPerfumes
  Resultado = Struct.new(:produto, :variante, :preco, :pontos, :motivos, keyword_init: true)

  def initialize(quiz, produtos: Produto.includes(:variantes, :frasco_mae, imagem_attachment: :blob).order(:nome))
    @configuracao = Configuracao.atual
    @quiz = quiz
    @produtos = produtos
  end

  def resultados
    return [] unless @quiz.valid?

    @produtos.filter_map do |produto|
      next if produto.body_splash? || produto.hidratante?
      next unless @quiz.categoria == "qualquer" || [@quiz.categoria, "unissex"].include?(produto.categoria)
      ofertas = produto.variantes.select { |v| v.preco&.positive? && v.disponivel? }
      variante = ofertas.min_by(&:preco)
      preco = variante&.preco_venda(@configuracao)
      if produto.variantes.empty? && produto.disponivel?
        preco = produto.preco_venda(@configuracao)
      end
      next unless !preco.nil? && preco >= 0 && (@quiz.limite.nil? || preco <= @quiz.limite)

      familias = produto.fragrancias.map { |familia| I18n.transliterate(familia).downcase }
      combinacoes = familias & Array(@quiz.familias)
      # Uma sugestão deve corresponder a pelo menos uma família escolhida.
      next if combinacoes.empty?
      motivos = combinacoes.map { |familia| "Família #{PerfumeQuiz::PERGUNTAS[:familias][:opcoes][familia].split(' · ').first.downcase}" }
      pontos = combinacoes.size * 6
      if produto.momento == @quiz.momento || produto.momento == "ambos"
        pontos += 2
        motivos << "Combina com o momento escolhido"
      end
      if produto.intensidade == @quiz.intensidade
        pontos += 2
        motivos << "Intensidade de sua preferência"
      end
      motivos << "Tamanho dentro do seu orçamento" if @quiz.limite
      Resultado.new(produto: produto, variante: variante, preco: preco, pontos: pontos, motivos: motivos)
    end.sort_by { |r| [-r.pontos, r.preco, r.produto.nome.to_s] }.first(3)
  end
end
