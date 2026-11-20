class HomeController < ApplicationController
  def index
    @videos_experiencia = VideoHome.ativos.with_attached_arquivo.to_a.select(&:pronto_para_exibir?)
    @avaliacoes_home = Avaliacao.publicadas.includes(:produto, usuario: { imagem_attachment: :blob }).order(created_at: :desc, id: :desc).limit(6)
    @produtos_destaque = Produto.em_destaque.with_attached_imagem.includes(:variantes)
    @banners = Banner.ativos.with_attached_imagem.to_a
    @atalhos = Banner.where(chave: Banner::ATALHOS.keys).with_attached_imagem.order(:ordem, :id).index_by(&:chave)
    @banners_carrossel = @banners.reject { |banner| %w[masculino feminino nicho experiencia atalho_mais_vendidos].include?(banner.chave) || Banner::ATALHOS.key?(banner.chave) }
    @banners_colecoes = @banners.select { |banner| %w[masculino feminino nicho].include?(banner.chave) && banner.imagem_exibicao.present? }
    @foto_experiencia = @banners.find { |banner| banner.chave == "experiencia" && banner.imagem.attached? }
  end
end
