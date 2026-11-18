class PaginasController < ApplicationController
  def perguntas_frequentes; end
  def trocas; end
  def privacidade; end
  def sobre; end

  def atendimento
    @configuracao = Configuracao.atual
  end

  def grupo_vip
    @configuracao = Configuracao.atual
  end
end
