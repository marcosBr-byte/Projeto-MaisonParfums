# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
banners_iniciais = [
  {
    chave: "mais_vendidos",
    titulo: "Destaques",
    subtitulo: "Os mais vendidos por categoria",
    ordem: 1
  },
  {
    chave: "frete",
    titulo: "Frete",
    subtitulo: "Para todo o Brasil",
    ordem: 2
  },
  {
    chave: "quiz",
    titulo: "Quiz Gratuito",
    subtitulo: "Descubra o seu perfume ideal",
    ordem: 3
  },
  {
    chave: "masculino",
    titulo: "Masculino",
    subtitulo: "Descubra nossas fragrâncias masculinas",
    ordem: 4
  },
  {
    chave: "feminino",
    titulo: "Feminino",
    subtitulo: "Descubra nossas fragrâncias femininas",
    ordem: 5
  }
]

banners_iniciais.each do |dados|
  Banner.find_or_create_by!(chave: dados[:chave]) do |banner|
    banner.titulo = dados[:titulo]
    banner.subtitulo = dados[:subtitulo]
    banner.ordem = dados[:ordem]
    banner.ativo = true
  end
end
