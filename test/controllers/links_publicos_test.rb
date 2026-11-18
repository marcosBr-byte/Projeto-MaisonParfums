require "test_helper"

class LinksPublicosTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @produto = Produto.create!(nome: "Fragrância Especial", categoria: :unissex,
      variantes_attributes: [{ tamanho: :tamanho_5ml, preco: 50, estoque: 5 }])
    @produto.imagem.attach(io: File.open(Rails.root.join("public/icon.png")), filename: "produto.png", content_type: "image/png")
    @cliente = Usuario.create!(nome: "Cliente", email: "links-cliente@example.com", telefone: "85999999999", password: "senha-teste-123")
  end

  def foto_url(foto)
    foto_path(chave: foto.blob.key)
  end

  test "produto usa nome no endereco e redireciona link numerico antigo" do
    assert_equal "/produtos/fragrancia-especial", produto_path(@produto)
    get "/produtos/#{@produto.id}"
    assert_response :moved_permanently
    assert_redirected_to produto_path(@produto)
    get produto_path(@produto)
    assert_response :success
    assert_select '.product-main-photo img[src=?]', foto_path(chave: @produto.imagem.blob.key, tamanho: :detalhe)
    assert_select '.product-main-photo a[href=?]', foto_path(chave: @produto.imagem.blob.key, tamanho: :detalhe)
    assert_select 'input[name="produto_id"][value=?]', @produto.slug
    assert_no_match %r{/rails/active_storage/}, response.body
    antigo = produto_path(@produto)
    @produto.update!(nome: "Nome atualizado")
    assert_equal antigo, produto_path(@produto)
  end

  test "nomes iguais e nomes reservados geram links diferentes e sem ids" do
    outro = Produto.create!(nome: @produto.nome, preco: 100)
    assert_not_equal @produto.slug, outro.slug
    assert_match /\Afragrancia-especial-[a-f0-9]{8}\z/, outro.slug
    %w[new edit 123].each do |nome|
      produto = Produto.create!(nome: nome, preco: 100)
      assert_match /\Aperfume-/, produto.slug
    end
  end

  test "edicao e avaliacao usam o novo link" do
    @cliente.update!(role: :admin)
    sign_in @cliente
    get "/produtos/#{@produto.id}/edit"
    assert_response :moved_permanently
    assert_redirected_to edit_produto_path(@produto)
    get edit_produto_path(@produto)
    assert_response :success
    assert_select 'form[action=?]', produto_path(@produto)
    assert_select 'a[aria-current="page"]', text: /Produtos/
    @cliente.update!(role: :cliente)
    post produto_avaliacoes_path(@produto), params: { avaliacao: { nota: 5, comentario: "Gostei" } }
    assert_redirected_to produto_path(@produto, anchor: "avaliar-produto")
  end

  test "carrinho recebe link do produto e preserva o tamanho escolhido" do
    sign_in @cliente
    post adicionar_carrinho_path, params: { produto_id: @produto.slug, variante_id: @produto.variantes.first.id, quantidade: 1 }
    assert_redirected_to carrinho_path
    assert_equal @produto, @cliente.carrinho.itens_carrinhos.first.produto
  end

  test "foto publica usa chave opaca e serve imagem sem redirecionar ao armazenamento" do
    caminho = foto_url(@produto.imagem)
    assert_match %r{\A/fotos/[a-z0-9]+\z}, caminho
    get caminho
    assert_response :success
    assert_equal "image/webp", response.media_type
    assert_nil response.headers["Location"]
    assert_equal @produto.imagem.blob.download, response.body
    get foto_path(chave: "inexistente")
    assert_response :not_found
  end

  test "miniaturas sao limitadas e armazenadas uma unica vez com cache separado por tamanho" do
    miniatura = foto_path(chave: @produto.imagem.blob.key, tamanho: :miniatura)
    get miniatura
    assert_response :success
    assert_equal "image/webp", response.media_type
    imagem = Vips::Image.new_from_buffer(response.body, "")
    assert_operator imagem.width, :<=, 160
    assert_operator imagem.height, :<=, 160
    etag = response.headers["ETag"]
    assert_no_difference "ActiveStorage::VariantRecord.count" do
      get miniatura
      assert_response :success
      get miniatura, headers: { "If-None-Match" => etag }
      assert_response :not_modified
    end
    get foto_path(chave: @produto.imagem.blob.key, tamanho: :detalhe)
    assert_response :success
    assert_not_equal etag, response.headers["ETag"]
    get foto_path(chave: @produto.imagem.blob.key, tamanho: "99999")
    assert_response :not_found
  end

  test "foto de perfil pertence ao dono ou administrador" do
    @cliente.imagem.attach(io: File.open(Rails.root.join("public/icon.png")), filename: "perfil.png", content_type: "image/png")
    caminho = foto_url(@cliente.imagem)
    get caminho
    assert_response :not_found
    sign_in @cliente
    get caminho
    assert_response :success
    sign_out @cliente
    outro = Usuario.create!(nome: "Outro", email: "links-outro@example.com", telefone: "85999999999", password: "senha-teste-123")
    sign_in outro
    get caminho
    assert_response :not_found
    outro.update!(role: :admin)
    sign_in outro
    get caminho
    assert_response :success
  end

  test "foto de avaliacao pendente nao e publica e publicar e ocultar respeitam acesso" do
    avaliacao = @produto.avaliacoes.create!(usuario: @cliente, nota: 5, comentario: "Gostei")
    avaliacao.fotos.attach(io: File.open(Rails.root.join("public/icon.png")), filename: "avaliacao.png", content_type: "image/png")
    caminho = foto_path(chave: avaliacao.fotos.first.blob.key, tamanho: :miniatura)
    get caminho
    assert_response :not_found
    avaliacao.update!(publicada: true)
    get caminho
    assert_response :success
    avaliacao.update!(publicada: false)
    get caminho, headers: { "If-None-Match" => response.headers["ETag"] }
    assert_response :not_found
  end
end
