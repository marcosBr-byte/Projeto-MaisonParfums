require "test_helper"

class AvaliacoesHomeTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @cliente = Usuario.create!(nome: "Ana Silva", email: "ana-home@example.com", telefone: "85999999999", password: "senha-teste-123")
    @produto = Produto.create!(nome: "Perfume avaliado", variantes_attributes: [{ tamanho: :tamanho_5ml, preco: 50, estoque: 5 }])
    @avaliacao = Avaliacao.create!(usuario: @cliente, produto: @produto, nota: 4, comentario: "Minha experiência com a fragrância.", publicada: true)
  end

  test "home mostra avaliacao publicada com nome estrelas e foto de perfil" do
    @cliente.imagem.attach(io: File.open(Rails.root.join("public/icon.png")), filename: "avatar.png", content_type: "image/png")
    get root_path
    assert_response :success
    assert_select "#avaliacoes-clientes [data-avaliacao='#{@avaliacao.id}']" do
      assert_select 'strong', text: "Ana"
      assert_select 'img[alt="Foto de perfil de Ana"]'
      assert_select '[aria-label="4.0 de 5 estrelas"]'
      assert_select 'p', text: @avaliacao.comentario
      assert_select 'a[href=?]', produto_path(@produto, anchor: "avaliacoes")
    end
    assert_select '#avaliacoes-clientes .home-testimonials-track', count: 1
    assert_select '#avaliacoes-clientes .home-testimonials-group', count: 2
    assert_select '#avaliacoes-clientes .home-testimonials-group[aria-hidden="true"]', count: 1
    assert_select '#avaliacoes-clientes button', count: 0
    assert_not_includes response.body, @cliente.email
  end

  test "sem foto mostra inicial e ao retirar aprovacao avaliacao desaparece" do
    get root_path
    assert_select '#avaliacoes-clientes .home-testimonial-initial', text: "A"
    @avaliacao.update!(publicada: false)
    get root_path
    assert_select '#avaliacoes-clientes .home-testimonial', count: 0
    assert_not_includes response.body, @avaliacao.comentario
    assert_select '.home-testimonials-empty'
  end
end
