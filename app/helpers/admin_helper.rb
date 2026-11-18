module AdminHelper
  ESTOQUE_BAIXO_ML = 5

  BADGES = {
    "pendente"  => "bg-amber-100 text-amber-800",
    "pago"      => "bg-blue-100 text-blue-800",
    "enviado"   => "bg-indigo-100 text-indigo-800",
    "entregue"  => "bg-emerald-100 text-emerald-800",
    "cancelado" => "bg-red-100 text-red-800"
  }.freeze

  def comparacao_vendas(atual, anterior)
    return "Sem movimentação nos dois períodos" if atual.zero? && anterior.zero?
    return "Sem base de comparação no período anterior" if anterior.zero?
    percentual = ((atual - anterior) * 100 / anterior.to_d).round(1)
    "#{percentual.positive? ? '+' : ''}#{number_to_percentage(percentual, precision: 1)} em relação ao período anterior"
  end

  def moeda(valor)
    number_to_currency(valor, unit: "R$ ", separator: ",", delimiter: ".")
  end

  def badge_status(status)
    chave = status.to_s.downcase
    classes = BADGES.fetch(chave, "bg-gray-100 text-gray-700")
    tag.span((chave.presence || "sem status").titleize,
             class: "inline-flex rounded-full px-3 py-1 text-xs font-semibold #{classes}")
  end

  def badge_estoque(ml)
    texto, classes =
      if ml <= 0 then ["Esgotado", "bg-red-100 text-red-800"]
      elsif ml < ESTOQUE_BAIXO_ML then ["Baixo", "bg-amber-100 text-amber-800"]
      else ["Ok", "bg-emerald-100 text-emerald-800"]
      end
    tag.span(texto, class: "inline-flex rounded-full px-3 py-1 text-xs font-semibold #{classes}")
  end
end
