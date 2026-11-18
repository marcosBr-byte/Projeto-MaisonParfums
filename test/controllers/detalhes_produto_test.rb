require "test_helper"

class DetalhesProdutoTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @admin = Usuario.create!(nome: "Admin", email: "detalhes-admin@example.com", telefone: "85999999999", password: "senha-teste-123", role: :admin)
    @cliente = Usuario.create!(nome: "Ana Cliente", email: "detalhes-cliente@example.com", telefone: "85999999999", password: "senha-teste-123")
    @produto = Produto.create!(nome: "Fragrância de teste", categoria: :feminino, marca: "Maison", momento: :dia,
      variantes_attributes: [{ tamanho: :tamanho_5ml, preco: 75, estoque: 5 }, { tamanho: :tamanho_10ml, preco: 120, estoque: 0 }])
  end

  test "cliente ve seu CEP e compra a quantidade escolhida respeitando estoque" do
    @cliente.update!(cep: "5820340")
    sign_in @cliente
    get produto_path(@produto)
    assert_response :success
    assert_select ".product-delivery strong", text: "5820340"
    assert_select '.product-delivery a[href="' + perfil_path + '"]', text: "Mudar CEP"
    assert_select 'input[name="quantidade"][type="number"][min="1"][max="5"]'
    assert_select 'input[type="submit"][value="Comprar"]'
    variante = @produto.variantes.find_by!(tamanho: :tamanho_5ml)
    post adicionar_carrinho_path, params: { produto_id: @produto.to_param, variante_id: variante.id, quantidade: 3 }
    assert_redirected_to carrinho_path
    item = @cliente.reload.carrinho.itens_carrinhos.find_by!(variante: variante)
    assert_equal 3, item.quantidade
    post adicionar_carrinho_path, params: { produto_id: @produto.to_param, variante_id: variante.id, quantidade: 3 }
    assert_redirected_to produto_path(@produto)
    assert_equal 3, item.reload.quantidade
  end

  test "mudar CEP salva o endereco e atualiza a informacao no produto" do
    sign_in @cliente
    get produto_path(@produto)
    assert_select ".product-delivery strong", text: "Não informado"
    get perfil_path
    assert_response :success
    assert_select 'input[name="usuario[cep]"]'
    patch perfil_path, params: { usuario: { cep: "58020340", estado: "PB", cidade: "João Pessoa" } }
    assert_redirected_to perfil_path
    assert_equal "58020340", @cliente.reload.cep
    get produto_path(@produto)
    assert_select ".product-delivery strong", text: "58020340"
    sign_out @cliente
    get produto_path(@produto)
    assert_select ".product-delivery strong", text: "Não informado"
    get perfil_path
    assert_redirected_to new_usuario_session_path
  end

  test "visitante volta ao formulario depois do login e publica avaliacao automaticamente" do
    get produto_path(@produto)
    assert_select '.reviews-toolbar a[href=?]', avaliar_produto_path(@produto)
    get avaliar_produto_path(@produto)
    assert_redirected_to new_usuario_session_path
    post usuario_session_path, params: { usuario: { email: @cliente.email, password: "senha-teste-123" } }
    assert_redirected_to avaliar_produto_path(@produto)
    follow_redirect!
    assert_redirected_to produto_path(@produto, anchor: "avaliar-produto")
    follow_redirect!
    assert_select '#avaliar-produto form[action=?]', produto_avaliacoes_path(@produto)
    assert_difference "Avaliacao.count", 1 do
      post produto_avaliacoes_path(@produto), params: { avaliacao: { nota: 5, comentario: "Minha avaliação real de teste" } }
    end
    assert_redirected_to produto_path(@produto, anchor: "avaliar-produto")
    follow_redirect!
    assert_select '#avaliar-produto', text: /está publicada/
    assert_select '.review-count', text: "(1)"
    sign_out @cliente
    sign_in @admin
    avaliacao = @produto.avaliacoes.find_by!(usuario: @cliente)
    patch admin_avaliacao_path(avaliacao), params: { avaliacao: { publicada: true } }
    get produto_path(@produto)
    assert_select '.review-count', text: "(1)"
    assert_select '.reviews-average strong', text: "5,0"
    assert_select '.review-distribution-row meter[value="100"]', count: 1
    assert_select '.review-comment', text: "Minha avaliação real de teste"
    get root_path
    assert_select "[data-avaliacao='#{avaliacao.id}']"
  end

  def imagem
    Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png")
  end

  test "admin cadastra notas fotos e indicacoes que aparecem para visitante" do
    sign_in @admin
    get edit_produto_path(@produto)
    assert_response :success
    assert_select 'input[name="produto[uso_inverno]"]'
    assert_select 'input[name="produto[fotos][]"]'
    patch produto_path(@produto), params: { produto: {
      uso_inverno: 10, uso_primavera: 80, uso_verao: 60, uso_outono: 30, uso_dia: 100, uso_noite: 20,
      fotos: [imagem], notas_olfativas_attributes: [{ nome: "Pera", nivel: "topo", imagem: imagem }, { nome: "Frésia", nivel: "coracao" }, { nome: "Patchouli", nivel: "base" }]
    } }
    assert_redirected_to admin_path
    assert_equal 3, @produto.notas_olfativas.count
    assert_equal 1, @produto.reload.fotos.count
    patch produto_path(@produto), params: { produto: { nome: @produto.nome, fotos: [""] } }
    assert_equal 1, @produto.reload.fotos.count
    sign_out @admin
    get produto_path(@produto)
    assert_response :success
    assert_select '.usage-inverno meter[value="10"]'
    assert_select '.usage-dia meter[value="100"]'
    assert_select '.notes-ingredients figcaption', text: "Pera"
    assert_select '.notes-ingredients img[alt="Pera"]'
    assert_select '.product-main-photo img', count: 1
    assert_select '[data-variante-target="borrifadas"]', text: /50 borrifadas/
    assert_select 'input[name="variante_id"][disabled]', count: 1
    assert_select '.reviews-average strong', text: "—"
    assert_select '#avaliar-produto', text: /Entre na sua conta/
  end

  test "admin envia varias fotos e nomes nos tres grupos de uma vez" do
    sign_in @admin
    get edit_produto_path(@produto)
    assert_select 'fieldset[data-controller="notes-upload"]', count: 3
    assert_select 'input[type="file"][multiple][data-notes-upload-target="picker"]', count: 3
    assert_select 'fieldset[data-notes-upload-level-value="coracao"] legend', text: "Notas de coração"
    patch produto_path(@produto), params: { produto: { notas_olfativas_attributes: {
      "123456789012345678901" => { nivel: "topo", nome: "Pera", imagem: imagem },
      "123456789012345678902" => { nivel: "topo", nome: "Melão", imagem: imagem },
      "123456789012345678903" => { nivel: "coracao", nome: "Frésia", imagem: imagem },
      "123456789012345678904" => { nivel: "base", nome: "Sândalo", imagem: imagem }
    } } }
    assert_redirected_to admin_path
    assert_equal ["Pera", "Melão"], @produto.notas_olfativas.where(nivel: "topo").order(:id).pluck(:nome)
    assert_equal ["Frésia"], @produto.notas_olfativas.where(nivel: "coracao").pluck(:nome)
    assert_equal ["Sândalo"], @produto.notas_olfativas.where(nivel: "base").pluck(:nome)
    assert @produto.notas_olfativas.all? { |nota| nota.imagem.attached? }
    nota = @produto.notas_olfativas.find_by!(nome: "Melão")
    patch produto_path(@produto), params: { produto: { notas_olfativas_attributes: { "0" => { id: nota.id, _destroy: "1" } } } }
    assert_equal 3, @produto.notas_olfativas.count
  end

  test "avaliacao com fotos publica automaticamente e cliente nao altera visibilidade" do
    sign_in @cliente
    assert_difference "Avaliacao.count", 1 do
      post produto_avaliacoes_path(@produto), params: { avaliacao: { nota: 5, comentario: "Gostei da fragrância.", fotos: [imagem], publicada: true, usuario_id: @admin.id } }
    end
    avaliacao = Avaliacao.last
    assert_equal @cliente.id, avaliacao.usuario_id
    assert avaliacao.publicada?
    assert_equal 1, avaliacao.fotos.count
    get produto_path(@produto)
    assert_select '.review-card', count: 1
    assert_select '#avaliar-produto', text: /está publicada/
    patch admin_avaliacao_path(avaliacao), params: { avaliacao: { publicada: true } }
    assert avaliacao.reload.publicada?
    sign_out @cliente
    sign_in @admin
    get admin_avaliacoes_path
    assert_select 'article', text: /Gostei da fragrância/
    patch admin_avaliacao_path(avaliacao), params: { avaliacao: { publicada: true } }
    assert avaliacao.reload.publicada?
    sign_out @admin
    get produto_path(@produto)
    assert_select '.review-card', count: 1
    assert_select '.review-card .review-comment', text: "Gostei da fragrância."
    assert_select '.review-photos img', count: 1
    assert_select '.reviews-average strong', text: "5,0"
    assert_select '.review-distribution-row meter[value="100"]', count: 1
    assert_select '.verified-purchase', count: 0
  end

  test "filtro mostra somente fotos publicadas e calcula media sem pendentes" do
    @produto.avaliacoes.create!(usuario: @cliente, nota: 5, comentario: "Com foto", publicada: true, fotos: [imagem])
    segundo = Usuario.create!(nome: "Bia", email: "bia-detalhes@example.com", telefone: "85999999999", password: "senha-teste-123")
    terceiro = Usuario.create!(nome: "Caio", email: "caio-detalhes@example.com", telefone: "85999999999", password: "senha-teste-123")
    @produto.avaliacoes.create!(usuario: segundo, nota: 3, comentario: "Sem foto", publicada: true)
    @produto.avaliacoes.create!(usuario: terceiro, nota: 1, comentario: "Pendente", publicada: false)
    pedido = @cliente.pedidos.create!(valor_total: 75, status: :pago)
    pedido.itens_pedidos.create!(produto: @produto, quantidade: 1, preco_unitario: 75)
    get produto_path(@produto), params: { avaliacoes: "com_fotos" }
    assert_response :success
    assert_select '.review-card', count: 1
    assert_select '.review-comment', text: "Com foto"
    assert_select '.reviews-average strong', text: "4,0"
    assert_select '.review-count', text: "(2)"
    assert_select '.verified-purchase', count: 1
    assert_select '.review-distribution-row meter[value="50"]', count: 2
  end

  test "rejeita nota invalida duplicata e arquivo que nao e imagem" do
    sign_in @cliente
    assert_no_difference "Avaliacao.count" do
      post produto_avaliacoes_path(@produto), params: { avaliacao: { nota: 6, comentario: "Teste" } }
    end
    assert_response :unprocessable_entity
    assert_select '[role="alert"]'
    @produto.avaliacoes.create!(usuario: @cliente, nota: 4, comentario: "Primeira")
    assert_no_difference "Avaliacao.count" do
      post produto_avaliacoes_path(@produto), params: { avaliacao: { nota: 5, comentario: "Duplicada" } }
    end
    assert_response :unprocessable_entity
    invalida = Avaliacao.new(produto: @produto, usuario: @admin, nota: 5, comentario: "Arquivo")
    invalida.fotos.attach(io: StringIO.new("arquivo de texto"), filename: "texto.txt", content_type: "text/plain")
    assert_not invalida.valid?
    assert invalida.errors[:fotos].any?
    @produto.uso_dia = 101
    assert_not @produto.valid?
  end

  test "visitante nao envia e cliente nao altera notas do perfume" do
    post produto_avaliacoes_path(@produto), params: { avaliacao: { nota: 5, comentario: "Teste" } }
    assert_redirected_to new_usuario_session_path
    sign_in @cliente
    patch produto_path(@produto), params: { produto: { uso_dia: 99, notas_olfativas_attributes: [{ nome: "Falsa", nivel: "base" }] } }
    assert_nil @produto.reload.uso_dia
    assert_equal 0, @produto.notas_olfativas.count
  end
end
