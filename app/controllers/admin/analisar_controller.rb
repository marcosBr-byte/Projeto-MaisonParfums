module Admin
  class AnalisarController < ApplicationController
    layout "admin"
    before_action :authenticate_usuario!
    before_action :exigir_admin
    around_action :horario_local

    def index
      data = params[:data].present? ? Date.iso8601(params[:data]) : Date.current
      raise ArgumentError unless data.year.between?(1900, 2100)
      if params[:mes].present?
        raise ArgumentError unless params[:mes].is_a?(String) && params[:mes].match?(/\A\d{4}-\d{2}\z/)
        @mes = Date.strptime(params[:mes], "%Y-%m").beginning_of_month
        raise ArgumentError unless @mes.year.between?(1900, 2100)
        @data_selecionada = data.beginning_of_month == @mes ? data : @mes
      else
        @data_selecionada = data
        @mes = data.beginning_of_month
      end
      @resumo = ResumoVendas.new(inicio: @mes, fim: @mes.end_of_month)
      @comparacao = ResumoVendas.new(inicio: @mes.prev_month, fim: @mes.prev_month.end_of_month)
      @resumo_dia = ResumoVendas.new(inicio: @data_selecionada, fim: @data_selecionada)
      @evolucao = @resumo.evolucao
      @pedidos_por_dia = @evolucao.to_h { |linha| [ linha[:dia], linha[:pedidos] ] }
      @dias_calendario = (@mes.beginning_of_week(:sunday)..@mes.end_of_month.end_of_week(:sunday)).to_a
      @produtos_em_alta = @resumo.produtos_em_alta
      @ultimos_pedidos = @resumo_dia.pedidos.includes(:usuario).order(created_at: :desc).limit(50)
    rescue ArgumentError, TypeError
      redirect_to admin_analisar_path, alert: "Data inválida. Escolha uma data entre 1900 e 2100."
    end

    private

    def horario_local(&acao)
      Time.use_zone(ResumoVendas::FUSO, &acao)
    end
  end
end
