require "test_helper"

class VideosHomeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    VideoHome.delete_all
    @admin = Usuario.create!(nome: "Admin", email: "videos@example.com", telefone: "85999999999", password: "senha-teste-123", role: :admin)
  end

  test "admin adiciona substitui ordena desativa e remove videos" do
    sign_in @admin
    get admin_customizar_path
    assert_response :success
    assert_select '#videos-home input[type="file"]'
    assert_match "600 × 600", response.body
    assert_match "1200 × 600", response.body
    post admin_videos_home_index_path, params: { video_home: { titulo: "Novo vídeo", ordem: 1, ativo: "1", arquivo: upload } }
    assert_redirected_to admin_customizar_path(anchor: "videos-home")
    perform_enqueued_jobs(only: OtimizarVideoJob)
    video = VideoHome.find_by!(titulo: "Novo vídeo")
    assert video.arquivo.attached?
    get root_path
    assert_select '#video video', count: 1
    assert_select '#video video[aria-label="Novo vídeo"]'
    anterior = video.arquivo.blob_id
    patch admin_videos_home_path(video), params: { video_home: { titulo: "Substituído", ordem: 3, arquivo: upload } }
    assert_redirected_to admin_customizar_path(anchor: "videos-home")
    assert_not_equal anterior, video.reload.arquivo.blob_id
    assert_equal 3, video.ordem
    patch admin_videos_home_path(video), params: { video_home: { ativo: "0" } }
    get root_path
    assert_select '.home-story-carousel', count: 0
    delete admin_videos_home_path(video)
    assert_not VideoHome.exists?(video.id)
  end

  test "arquivos invalidos e ordem invalida nao sao salvos" do
    sign_in @admin
    assert_no_difference 'VideoHome.count' do
      post admin_videos_home_index_path, params: { video_home: { titulo: "Imagem", ordem: 0, arquivo: fixture_file_upload(Rails.root.join("app/assets/images/slide-frete.jpeg"), "image/jpeg") } }
      post admin_videos_home_index_path, params: { video_home: { titulo: "Sem arquivo", ordem: 0 } }
    end
    video = VideoHome.create!(titulo: "Original", ordem: 0, arquivo_padrao: "video1.mp4")
    patch admin_videos_home_path(video), params: { video_home: { ordem: -1 } }
    assert_equal 0, video.reload.ordem
  end

  test "visitante nao pode gerenciar videos" do
    video = VideoHome.create!(titulo: "Original", arquivo_padrao: "video1.mp4")
    post admin_videos_home_index_path, params: { video_home: { titulo: "Intruso", arquivo: upload } }
    assert_redirected_to new_usuario_session_path
    patch admin_videos_home_path(video), params: { video_home: { ativo: "0" } }
    assert_redirected_to new_usuario_session_path
    delete admin_videos_home_path(video)
    assert_redirected_to new_usuario_session_path
    assert video.reload.ativo?
  end

  test "cliente comum nao pode remover videos" do
    cliente = Usuario.create!(nome: "Cliente", email: "cliente-videos@example.com", telefone: "85999999999", password: "senha-teste-123")
    video = VideoHome.create!(titulo: "Original", arquivo_padrao: "video1.mp4")
    sign_in cliente
    assert_no_difference "VideoHome.count" do
      delete admin_videos_home_path(video)
    end
    assert_redirected_to root_path
  end

  test "arquivo acima de 100 MB e rejeitado" do
    video = VideoHome.new(titulo: "Grande")
    video.arquivo.attach(io: StringIO.new("video"), filename: "grande.mp4", content_type: "video/mp4")
    video.arquivo.blob.byte_size = 100.megabytes + 1
    assert_not video.valid?
    assert_includes video.errors[:arquivo], "deve ter no máximo 100 MB"
  end

  test "home respeita ordem e exclusao dos videos originais" do
    segundo = VideoHome.create!(titulo: "Segundo", ordem: 2, arquivo_padrao: "video2.mp4")
    primeiro = VideoHome.create!(titulo: "Primeiro", ordem: 1, arquivo_padrao: "video1.mp4")
    get root_path
    assert_select '#video video' do |videos|
      assert_equal ["Primeiro", "Segundo"], videos.map { |v| v['aria-label'] }
    end
    primeiro.destroy!
    segundo.destroy!
    get root_path
    assert_select '#video video', count: 0
  end

  private

  def upload
    fixture_file_upload(Rails.root.join("app/assets/videos/video1.mp4"), "video/mp4")
  end
end
