class PaginasController < ApplicationController
  content_security_policy(only: :sobre) do |policy|
    policy.frame_src :self, "https://www.google.com/maps/embed"
  end

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
