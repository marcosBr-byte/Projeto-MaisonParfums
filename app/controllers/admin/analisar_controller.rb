module Admin
  class AnalisarController < ApplicationController
    layout "admin"

    before_action :authenticate_usuario!
    before_action :exigir_admin

    def index
      if params[:mes].present?
        @mes = Date.strptime(params[:mes], "%Y-%m").beginning_of_month
        @data_selecionada =
          if params[:data].present?
            Date.iso8601(params[:data])
          else
            @mes
          end
      else
        @data_selecionada =
          params[:data].present? ? Date.iso8601(params[:data]) : Date.current

      @mes = @data_selecionada.beginning_of_month
    end

      inicio = @mes.beginning_of_week(:sunday)
      fim = @mes.end_of_month.end_of_week(:sunday)
      @dias_calendario = (inicio..fim).to_a

      periodo_mes = @mes.beginning_of_month.beginning_of_day..@mes.end_of_month.end_of_day
      @pedidos_por_dia = Pedido.where(created_at: periodo_mes).group("DATE(created_at)").count

      periodo_dia =
      @data_selecionada.beginning_of_day..
      @data_selecionada.end_of_day
      @pedidos_dia = Pedido.where(created_at: periodo_dia)
      @total_pedidos = @pedidos_dia.count
      @pedidos_pendentes = @pedidos_dia.where(status: "pendente").count
      @pedidos_pagos = @pedidos_dia.where(status: "pago").count
      @pedidos_entregues = @pedidos_dia.where(status: "entregue").count
      @pedidos_cancelados = @pedidos_dia.where(status: "cancelado").count
      @faturamento = @pedidos_dia.where(status: %w[pago enviado entregue]).sum(:valor_total)
      @ultimos_pedidos = @pedidos_dia.includes(:usuario).order(created_at: :desc)

    rescue ArgumentError
      redirect_to admin_analisar_path, alert: "Data inválida."
    end
  end
end