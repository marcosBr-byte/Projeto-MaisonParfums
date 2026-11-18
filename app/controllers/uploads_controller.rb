class UploadsController < ApplicationController
  include ActiveStorage::SetCurrent
  before_action :authenticate_usuario!
  before_action :exigir_admin
  rate_limit store: SecurityRateLimitStore, to: 30, within: 10.minutes, only: :create

  def create
    dados = params.require(:blob).permit(:filename, :byte_size, :checksum, :content_type)
    tamanho = Integer(dados[:byte_size].to_s, 10, exception: false)
    unless tamanho && tamanho.positive? && tamanho <= ImagemOtimizada::LIMITE_UPLOAD && dados[:content_type].in?(ImagemOtimizada::TIPOS)
      return head :unprocessable_entity
    end
    blob = ActiveStorage::Blob.create_before_direct_upload!(**dados.to_h.symbolize_keys)
    render json: blob.as_json(root: false, methods: :signed_id).merge(direct_upload: {
      url: blob.service_url_for_direct_upload, headers: blob.service_headers_for_direct_upload
    })
  end
end
