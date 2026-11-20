class AdminController < ApplicationController
  layout "admin", only: [ :index, :show ]
  before_action :authenticate_usuario!
  before_action :exigir_admin
  around_action :horario_local, only: :index

  def index
    @hoje = Date.current
    @resumo = ResumoVendas.new(inicio: @hoje.beginning_of_month, fim: @hoje)
    anterior = @hoje.prev_month
    @comparacao = ResumoVendas.new(inicio: anterior.beginning_of_month, fim: anterior)
    @evolucao = ResumoVendas.new(inicio: @hoje - 6, fim: @hoje).evolucao
    @total_usuarios = Usuario.count
    @total_produtos = Produto.count
    @pedidos_pendentes = Pedido.where(status: :pendente).count
    @mensagens_nao_lidas = Mensagem.nao_lidas.count
    @estoque_baixo = Variante.where(estoque: 0..4).count
    @ultimos_pedidos = Pedido.includes(:usuario).order(created_at: :desc).limit(5)
    @reposicao = Variante.includes(produto: { imagem_attachment: :blob }).where(estoque: 0..4).order(:estoque, :id).group_by(&:produto)
  end

  def show
    @usuario = current_usuario
  end

  private

  def horario_local(&acao)
    Time.use_zone(ResumoVendas::FUSO, &acao)
  end
end
