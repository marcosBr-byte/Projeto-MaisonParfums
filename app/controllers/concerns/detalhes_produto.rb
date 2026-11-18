module DetalhesProduto
  extend ActiveSupport::Concern

  private

  def carregar_avaliacoes
    publicadas = @produto.avaliacoes.publicadas
    @distribuicao_avaliacoes = publicadas.group(:nota).count
    @total_avaliacoes = @distribuicao_avaliacoes.values.sum
    @media_avaliacoes = @total_avaliacoes.positive? ? @distribuicao_avaliacoes.sum { |nota, quantidade| nota * quantidade }.to_f / @total_avaliacoes : nil
    @com_fotos = params[:avaliacoes] == "com_fotos"
    lista = @com_fotos ? publicadas.where(id: ActiveStorage::Attachment.where(record_type: "Avaliacao", name: "fotos").select(:record_id)) : publicadas
    @pagina_avaliacoes = params[:pagina].to_i.clamp(1, 10_000)
    @quantidade_filtrada = lista.count
    @avaliacoes = lista.includes(usuario: { imagem_attachment: :blob }).with_attached_fotos.order(created_at: :desc, id: :desc).limit(9).offset((@pagina_avaliacoes - 1) * 9)
    @compradores_verificados = @produto.itens_pedidos.joins(:pedido)
      .where(pedidos: { status: %w[pago enviado entregue] }).where("pedidos.pagamento_teste IS NOT TRUE").distinct.pluck("pedidos.usuario_id")
    @minha_avaliacao = current_usuario && @produto.avaliacoes.find_by(usuario_id: current_usuario.id)
    @nova_avaliacao ||= (@minha_avaliacao unless @minha_avaliacao&.publicada?) || Avaliacao.new
  end
end
