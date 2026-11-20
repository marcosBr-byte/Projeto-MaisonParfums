require "test_helper"

class ProdutoFragranciasTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    usuario = Usuario.create!(nome: "Admin", email: "fragrancias@example.com", telefone: "85999999999", password: "senha-teste-123", role: :admin)
    sign_in usuario
    @produto = Produto.create!(nome: "Perfume", categoria: :masculino, fragancia: :floral,
      variantes_attributes: [ { tamanho: :lacrado, preco: 100, estoque: 5 } ])
  end

  test "atualiza varias fragrancias e exibe na pagina publica" do
    patch produto_path(@produto), params: { produto: { fragancia: "Cítrica, Amadeirada" } }
    assert_redirected_to admin_path
    assert_equal [ "Cítrica", "Amadeirada" ], @produto.reload.fragrancias
    get produto_path(@produto)
    assert_response :success
    assert_select "dd", text: "Cítrica, Amadeirada"
  end

  test "mantem leitura de fragrancia unica antiga" do
    @produto.update_column(:fragancia, "Floral")
    assert_equal "Floral", @produto.reload.rotulo(:fragancia)
  end

  test "normaliza nomes conhecidos evita duplicatas e aceita personalizada" do
    @produto.update!(fragancia: " citrica, Cítrica, amadeirada; Chá branco ")
    assert_equal [ "Cítrica", "Amadeirada", "Chá branco" ], @produto.reload.fragrancias
  end

  test "quiz recomenda perfume pela segunda familia cadastrada" do
    @produto.update!(fragancia: "Cítrica, Amadeirada")
    quiz = PerfumeQuiz.new(categoria: "masculino", familias: [ "amadeirada" ], momento: "dia", intensidade: "qualquer", orcamento: "100")
    assert_equal [ @produto.id ], RecomendadorPerfumes.new(quiz).resultados.map { |r| r.produto.id }
  end
end
