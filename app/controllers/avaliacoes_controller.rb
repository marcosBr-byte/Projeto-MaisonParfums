class AvaliacoesController < ApplicationController
  include DetalhesProduto
  before_action :authenticate_usuario!
  rate_limit store: SecurityRateLimitStore, to: 20, within: 10.minutes, only: %i[create update], by: -> { current_usuario.id }

  def new
    produto = Produto.por_link!(params[:produto_id])
    redirect_to(current_usuario.admin? ? admin_avaliacoes_path : produto_path(produto, anchor: "avaliar-produto"))
  end

  def create
    @produto = Produto.por_link!(params[:produto_id])
    return redirect_to produto_path(@produto), alert: "Avaliações são enviadas pela conta do cliente." if current_usuario.admin?
    @nova_avaliacao = @produto.avaliacoes.build(params.require(:avaliacao).permit(:nota, :comentario, fotos: []))
    @nova_avaliacao.usuario = current_usuario
    salvar_avaliacao
  rescue ActiveRecord::RecordNotUnique
    redirect_to produto_path(@produto, anchor: "avaliacoes"), alert: "Você já enviou uma avaliação para este perfume."
  end

  def update
    @produto = Produto.por_link!(params[:produto_id])
    @nova_avaliacao = @produto.avaliacoes.find_by!(usuario: current_usuario)
    if @nova_avaliacao.publicada?
      return redirect_to produto_path(@produto, anchor: "avaliacoes"), alert: "Sua avaliação já está publicada."
    end
    @nova_avaliacao.assign_attributes(params.require(:avaliacao).permit(:nota, :comentario, fotos: []))
    salvar_avaliacao
  end

  private

  def salvar_avaliacao
    @nova_avaliacao.publicada = !@nova_avaliacao.conteudo_ofensivo?
    if @nova_avaliacao.save
      mensagem = @nova_avaliacao.publicada? ? "Sua avaliação foi publicada!" : "Sua avaliação ficou oculta por conter linguagem ofensiva. Revise o comentário e envie novamente."
      redirect_to produto_path(@produto, anchor: "avaliar-produto"), notice: mensagem
    else
      carregar_avaliacoes
      render "produto/show", status: :unprocessable_entity
    end
  end
end
