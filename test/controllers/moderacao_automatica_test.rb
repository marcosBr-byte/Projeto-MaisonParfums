require "test_helper"

class ModeracaoAutomaticaTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @cliente = Usuario.create!(nome: "Cliente", email: "moderacao@example.com", telefone: "85999999999", password: "senha-teste-123")
    @produto = Produto.create!(nome: "Perfume", variantes_attributes: [{ tamanho: :tamanho_5ml, preco: 50, estoque: 5 }])
    sign_in @cliente
  end

  test "critica negativa sem ofensa e publicada sem permissao do admin" do
    post produto_avaliacoes_path(@produto), params: { avaliacao: { nota: 1, comentario: "Não gostei, a fixação é ruim e o cheiro é péssimo.", publicada: false } }
    assert @produto.avaliacoes.sole.publicada?
    get produto_path(@produto)
    assert_select '.review-count', text: "(1)"
    assert_select '.reviews-average strong', text: "1,0"
    get root_path
    assert_select '.home-testimonial-comment', text: /fixação é ruim/
  end

  test "ofensa fica oculta mesmo tentando publicar e cliente pode corrigir" do
    post produto_avaliacoes_path(@produto), params: { avaliacao: { nota: 1, comentario: "Isso é uma p0rr@", publicada: true } }
    avaliacao = @produto.avaliacoes.sole
    assert_not avaliacao.publicada?
    get produto_path(@produto)
    assert_select '.review-card', count: 0
    assert_select '#avaliar-produto form[action=?]', produto_avaliacao_path(@produto)
    get root_path
    assert_select '.home-testimonial', count: 0
    patch produto_avaliacao_path(@produto), params: { avaliacao: { nota: 2, comentario: "Não gostei da fragrância." } }
    assert avaliacao.reload.publicada?
    assert_equal 1, @produto.avaliacoes.count
    get produto_path(@produto)
    assert_select '.review-comment', text: "Não gostei da fragrância."
    assert_select '.reviews-average strong', text: "2,0"
  end

  test "outro cliente nao altera avaliacao e admin nao publica conteudo ofensivo" do
    avaliacao = @produto.avaliacoes.create!(usuario: @cliente, nota: 1, comentario: "Seu idiota", publicada: true)
    assert_not avaliacao.publicada?
    outro = Usuario.create!(nome: "Outro", email: "outro-moderacao@example.com", telefone: "85999999999", password: "senha-teste-123")
    sign_in outro
    patch produto_avaliacao_path(@produto), params: { avaliacao: { comentario: "Alterado" } }
    assert_response :not_found
    assert_equal "Seu idiota", avaliacao.reload.comentario
    admin = Usuario.create!(nome: "Admin", email: "admin-moderacao@example.com", role: :admin, password: "senha-teste-123")
    sign_in admin
    patch admin_avaliacao_path(avaliacao), params: { avaliacao: { publicada: true } }
    assert_not avaliacao.reload.publicada?
  end
end
