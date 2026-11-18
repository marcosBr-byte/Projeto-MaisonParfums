require "test_helper"

class OtimizarVideoJobTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "upload fica oculto ate converter e o resultado nao e recomprimido" do
    video = VideoHome.create!(titulo: "Otimização", arquivo: upload)
    original = video.arquivo.blob_id
    assert_not video.pronto_para_exibir?
    OtimizarVideoJob.perform_now(video.id, original)
    video.reload
    assert video.pronto_para_exibir?
    assert_equal "video/mp4", video.arquivo.content_type
    assert_operator video.arquivo.byte_size, :<, 25.megabytes
    convertido = video.arquivo.blob_id
    assert_not_equal original, convertido
    OtimizarVideoJob.perform_now(video.id, original)
    OtimizarVideoJob.perform_now(video.id, convertido)
    assert_equal convertido, video.reload.arquivo.blob_id
  end

  test "arquivo corrompido nao e publicado" do
    video = VideoHome.create!(titulo: "Corrompido", arquivo: {
      io: StringIO.new("isto nao e um video"), filename: "video.mp4", content_type: "video/mp4"
    })
    assert_raises(VideoOtimizado::Invalido) do
      VideoOtimizado.processar(video.arquivo.blob) { flunk "Não deve aceitar arquivo inválido" }
    end
    assert_not video.reload.pronto_para_exibir?
  end

  private

  def upload
    { io: File.open(Rails.root.join("app/assets/videos/video1.mp4")), filename: "video.mp4", content_type: "video/mp4" }
  end
end
