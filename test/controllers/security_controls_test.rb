require "test_helper"

class SecurityControlsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @cache_anterior = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    @cliente = Usuario.create!(nome: "Cliente", email: "security@example.com", telefone: "85999999999", password: "senha-segura-123")
  end

  teardown { Rails.cache = @cache_anterior }

  test "upload direto exige administrador e restringe tipo tamanho e metadados" do
    dados = { filename: "foto.png", byte_size: 10, checksum: "checksum", content_type: "image/png" }
    assert_no_difference "ActiveStorage::Blob.count" do
      post "/rails/active_storage/direct_uploads", params: { blob: dados }
      assert_redirected_to new_usuario_session_path
      sign_in @cliente
      post "/rails/active_storage/direct_uploads", params: { blob: dados }
      assert_redirected_to root_path
    end
    @cliente.update!(role: :admin)
    assert_no_difference "ActiveStorage::Blob.count" do
      post "/rails/active_storage/direct_uploads", params: { blob: dados.merge(content_type: "text/html") }
      assert_response :unprocessable_entity
      post "/rails/active_storage/direct_uploads", params: { blob: dados.merge(byte_size: 6.megabytes) }
      assert_response :unprocessable_entity
    end
    assert_difference "ActiveStorage::Blob.count", 1 do
      post "/rails/active_storage/direct_uploads", params: { blob: dados.merge(metadata: { maison_video_otimizado: true }) }
      assert_response :success
    end
    assert_not ActiveStorage::Blob.last.metadata["maison_video_otimizado"]
  end

  test "limite de login bloqueia tentativas repetidas por IP" do
    20.times { post usuario_session_path, params: { usuario: { email: @cliente.email, password: "incorreta" } } }
    post usuario_session_path, params: { usuario: { email: @cliente.email, password: "incorreta" } }
    assert_response :too_many_requests
  end

  test "recuperacao nao revela se email existe e limita repeticao" do
    post usuario_password_path, params: { usuario: { email: @cliente.email } }
    mensagem = flash[:notice]
    post usuario_password_path, params: { usuario: { email: "nao-existe@example.com" } }
    assert_equal mensagem, flash[:notice]
    4.times { post usuario_password_path, params: { usuario: { email: "nao-existe@example.com" } } }
    assert_response :too_many_requests
  end

  test "cadastro nao permite criar administrador por parametros" do
    post usuario_registration_path, params: { usuario: { nome: "Novo", email: "novo-security@example.com", telefone: "85999999999", password: "senha-segura-123", password_confirmation: "senha-segura-123", role: "admin" } }
    assert Usuario.find_by!(email: "novo-security@example.com").cliente?
  end

  test "requisicao sem token CSRF nao cria conta" do
    anterior = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    assert_no_difference "Usuario.count" do
      post usuario_registration_path, params: { usuario: { nome: "Ataque", email: "csrf@example.com", telefone: "85999999999", password: "senha-segura-123" } }
    end
    assert_response :unprocessable_entity
  ensure
    ActionController::Base.allow_forgery_protection = anterior
  end

  test "foto de avaliador e publica somente enquanto existe avaliacao publicada" do
    @cliente.imagem.attach(io: File.open(Rails.root.join("public/icon.png")), filename: "avatar.png", content_type: "image/png")
    produto = Produto.create!(nome: "Foto pública", preco: 50)
    avaliacao = produto.avaliacoes.create!(usuario: @cliente, nota: 4, comentario: "Gostei", publicada: true)
    caminho = foto_path(chave: @cliente.imagem.blob.key, tamanho: :miniatura)
    get caminho
    assert_response :success
    assert_includes response.headers["Cache-Control"], "private"
    avaliacao.update!(publicada: false)
    get caminho
    assert_response :not_found
  end

  test "cabecalhos bloqueiam scripts externos e incorporacao em outros sites" do
    get root_path
    politica = response.headers["Content-Security-Policy"]
    assert_includes politica, "object-src 'none'"
    assert_includes politica, "frame-ancestors 'none'"
    assert_match(/script-src 'self' 'nonce-[^']+'/, politica)
    assert_no_match(/script-src[^;]*unsafe-inline/, politica)
  end

  test "cliente nao acessa pedidos ou itens de carrinho de outra conta" do
    outro = Usuario.create!(nome: "Outro", email: "outro-security@example.com", telefone: "85999999999", password: "senha-segura-123")
    pedido = outro.pedidos.create!(valor_total: 10)
    produto = Produto.create!(nome: "Produto privado", preco: 10, estoque: 5)
    item = outro.create_carrinho.itens_carrinhos.create!(produto: produto, quantidade: 1)
    sign_in @cliente
    get pagamento_pedido_path(pedido)
    assert_response :not_found
    @cliente.create_carrinho
    sign_in @cliente
    delete itens_carrinho_path(item)
    assert_response :not_found
    assert item.reload.persisted?
  end
end
