class OtimizarVideoJob < ApplicationJob
  queue_as :videos
  limits_concurrency to: 1, key: ->(*) { "otimizacao-videos" }, duration: 10.minutes
  retry_on StandardError, wait: 1.minute, attempts: 3 do |job, error|
    video = VideoHome.find_by(id: job.arguments.first)
    if video&.arquivo&.attached? && video.arquivo.blob_id == job.arguments.second
      blob = video.arquivo.blob
      blob.update!(metadata: blob.metadata.merge("maison_video_falhou" => true))
    end
    Rails.logger.error("Falha na otimização do vídeo #{job.arguments.first}: #{error.class}")
  end
  discard_on ActiveRecord::RecordNotFound

  def perform(video_id, blob_id)
    video = VideoHome.find(video_id)
    return if video.arquivo.blob_id != blob_id || video.pronto_para_exibir?

    VideoOtimizado.processar(video.arquivo.blob) do |saida|
      video.with_lock do
        # Uma substituição ou outro job pode ter ocorrido durante a conversão.
        video.arquivo.reload
        return if video.arquivo.blob_id != blob_id || video.pronto_para_exibir?

        video.arquivo.attach(io: saida, filename: "video-#{video.id}.mp4", content_type: "video/mp4",
          metadata: { maison_video_otimizado: true })
      end
    end
  end
end
