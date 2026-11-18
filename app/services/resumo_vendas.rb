class ResumoVendas
  FUSO = "America/Fortaleza".freeze
  CONFIRMADOS = %w[pago enviado entregue].freeze
  DIA_LOCAL = Arel.sql("DATE(pedidos.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'America/Fortaleza')")
  attr_reader :inicio, :fim, :pedidos

  def initialize(inicio:, fim:)
    @inicio, @fim = inicio, fim
    @pedidos = Pedido.where("pagamento_teste IS NOT TRUE").where(created_at: inicio.in_time_zone(FUSO)...(fim + 1).in_time_zone(FUSO))
  end

  def por_status
    @por_status ||= pedidos.group(:status).count
  end

  def total
    por_status.values.sum
  end

  def confirmados
    pedidos.where(status: CONFIRMADOS)
  end

  def quantidade_confirmada
    CONFIRMADOS.sum { |status| por_status.fetch(status, 0) }
  end

  def faturamento
    @faturamento ||= confirmados.sum(:valor_total)
  end

  def ticket_medio
    quantidade_confirmada.positive? ? faturamento / quantidade_confirmada : 0.to_d
  end

  def pendentes
    por_status.fetch("pendente", 0)
  end

  def valor_pendente
    @valor_pendente ||= pedidos.where(status: :pendente).sum(:valor_total)
  end

  def descontos
    @descontos ||= confirmados.sum(:desconto_valor)
  end

  def brindes
    @brindes ||= confirmados.where(brinde_incluso: true).count
  end

  def evolucao
    @evolucao ||= begin
      quantidades = pedidos.group(DIA_LOCAL).count
      valores = confirmados.group(DIA_LOCAL).sum(:valor_total)
      (inicio..fim).map { |dia| { dia: dia, pedidos: quantidades.fetch(dia, 0), receita: valores.fetch(dia, 0).to_d } }
    end
  end

  def produtos_em_alta
    Produto.joins(itens_pedidos: :pedido)
      .where(pedidos: { id: confirmados.select(:id) })
      .select("produtos.*, SUM(itens_pedidos.quantidade) AS unidades_vendidas")
      .group("produtos.id").order(Arel.sql("SUM(itens_pedidos.quantidade) DESC, produtos.nome ASC")).limit(5)
  end
end
