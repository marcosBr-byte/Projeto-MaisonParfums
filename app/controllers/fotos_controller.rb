class FotosController < ApplicationController
  include ActiveStorage::Streaming

  def show
    blob = ActiveStorage::Blob.find_by!(key: params[:chave])
    return head :not_found unless blob.content_type.in?(%w[image/jpeg image/png image/webp image/gif image/avif])
    return head :not_found unless blob.attachments.includes(:record).any? { |anexo| permitido?(anexo.record) }
    tamanho = params[:tamanho].presence
    return head :not_found if tamanho && !ImagemOtimizada::TAMANHOS.key?(tamanho)

    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Cache-Control"] = "private, max-age=0, must-revalidate"
    return unless stale?(etag: [ blob.checksum, tamanho, "webp-v1" ], last_modified: blob.created_at, public: false)

    # A transformação é gerada uma única vez e reaproveitada pelo Active Storage.
    if tamanho
      blob = blob.variant(ImagemOtimizada.transformacoes(tamanho)).processed.image.blob
    end

    if request.headers["Range"].present?
      send_blob_byte_range_data(blob, request.headers["Range"], disposition: "inline")
    else
      send_blob_stream(blob, disposition: "inline")
    end
  rescue ActiveStorage::FileNotFoundError, ActiveStorage::InvariableError, Vips::Error
    head :not_found
  end

  private

  def permitido?(registro)
    return true if current_usuario&.admin?
    case registro
    when Produto, NotaOlfativa
      true
    when Banner
      registro.ativo?
    when Avaliacao
      registro.publicada? || registro.usuario_id == current_usuario&.id
    when Usuario
      registro.id == current_usuario&.id || registro.avaliacoes.publicadas.exists?
    when ActionText::RichText
      registro.record_type.in?(%w[Produto Configuracao])
    else
      false
    end
  end
end
