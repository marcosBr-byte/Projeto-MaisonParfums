class ImportarVitrineDaMaisonNoRender < ActiveRecord::Migration[8.1]
  def up
    return unless Rails.env.production? && ENV["RENDER"] == "true"

    pasta = Rails.root.join("db/data/vitrine_maison")
    vitrine = JSON.parse(pasta.join("vitrine.json").read)
    configuracao = JSON.parse(pasta.join("configuracoes-loja.json").read)
    Configuracao.atual.update!(configuracao)

    vitrine.fetch("banners").each do |dados|
      banner = Banner.find_or_initialize_by(chave: dados.fetch("chave"))
      banner.update!(dados.except("chave", "imagem"))

      if (imagem = dados["imagem"])
        pasta.join(imagem).open("rb") do |arquivo|
          blob = ActiveStorage::Blob.create_and_upload!(io: arquivo, filename: imagem, content_type: "image/png")
          banner.update!(imagem: blob)
        end
      end
    end

    vitrine.fetch("videos").each do |dados|
      video = VideoHome.find_or_initialize_by(arquivo_padrao: dados.fetch("arquivo_padrao"))
      video.update!(dados)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "A vitrine pode ter sido editada no painel após a importação"
  end
end
