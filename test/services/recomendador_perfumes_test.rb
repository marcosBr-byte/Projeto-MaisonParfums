require "test_helper"

class RecomendadorPerfumesTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  def quiz(**opcoes)
    PerfumeQuiz.new({ categoria: "masculino", familias: ["amadeirada"], momento: "noite", intensidade: "alta", orcamento: "100" }.merge(opcoes))
  end

  def produto(nome, **opcoes)
    Produto.create!({ nome: nome, categoria: :masculino, fragancia: :amadeirada, momento: :noite, intensidade: :alta,
      variantes_attributes: [{ tamanho: :lacrado, preco: 50, estoque: 1 }] }.merge(opcoes))
  end

  test "prioriza momento e intensidade e limita a tres sugestoes" do
    produto("Menos afinidade", momento: :dia, intensidade: :baixa)
    melhores = %w[A B C].map { |nome| produto(nome) }
    resultados = RecomendadorPerfumes.new(quiz).resultados
    assert_equal melhores.map(&:id), resultados.map { |r| r.produto.id }
  end

  test "inclui unissex e respeita limite exato do orçamento" do
    perfume = produto("Unissex", categoria: :unissex, variantes_attributes: [{ tamanho: :lacrado, preco: 100, estoque: 1 }])
    assert_equal [perfume.id], RecomendadorPerfumes.new(quiz).resultados.map { |r| r.produto.id }
    assert_empty RecomendadorPerfumes.new(quiz(orcamento: "50")).resultados
  end

  test "seleciona tamanho disponivel sem usar preco do tamanho esgotado" do
    frasco = FrascoMae.create!(nome: "Frasco", estoque_ml: 0)
    perfume = produto("Varias opcoes", frasco_mae: frasco, variantes_attributes: [
      { tamanho: :tamanho_5ml, preco: 20, estoque: 0 },
      { tamanho: :lacrado, preco: 90, estoque: 1 }
    ])
    resultado = RecomendadorPerfumes.new(quiz).resultados.first
    assert_equal perfume.id, resultado.produto.id
    assert_equal "lacrado", resultado.variante.tamanho
    assert_equal 90, resultado.preco
  end

  test "reconhece familia com acento e permite sem limite e sem perfil" do
    perfume = produto("Citrico", fragancia: :cítrica, categoria: :feminino)
    resultados = RecomendadorPerfumes.new(quiz(categoria: "qualquer", familias: ["citrica"], orcamento: "livre")).resultados
    assert_equal [perfume.id], resultados.map { |r| r.produto.id }
  end

  test "nao cria recomendacao para questionario invalido" do
    assert_empty RecomendadorPerfumes.new(quiz(familias: [])).resultados
  end
end
