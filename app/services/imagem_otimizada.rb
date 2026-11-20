require "vips"
require "stringio"

class ImagemOtimizada
  class Invalida < StandardError; end

  TIPOS = %w[image/jpeg image/png image/webp].freeze
  LIMITE_UPLOAD = 5.megabytes
  LIMITE_PIXELS = 40_000_000
  LIMITE_SALVO = 700.kilobytes
  TAMANHOS = {
    "miniatura" => [ 160, 160 ],
    "catalogo" => [ 480, 480 ],
    "detalhe" => [ 1200, 1200 ],
    "banner" => [ 1920, 1920 ]
  }.freeze

  def self.preparar(anexo, limite: 1600)
    # Blobs já anexados e signed_ids não são recomprimidos a cada edição.
    return anexo unless anexo.respond_to?(:tempfile) || anexo.is_a?(Hash)

    dados = anexo.is_a?(Hash) ? anexo.symbolize_keys : {
      io: anexo.tempfile, filename: anexo.original_filename, content_type: anexo.content_type
    }
    io = dados.fetch(:io)
    if dados[:content_type].present? && !TIPOS.include?(dados[:content_type])
      raise Invalida, "use JPG, PNG ou WebP de até 5 MB"
    end
    io.rewind
    bytes = io.read(LIMITE_UPLOAD + 1)
    raise Invalida, "envie uma imagem de até 5 MB" if bytes.bytesize > LIMITE_UPLOAD
    raise Invalida, "use um arquivo JPG, PNG ou WebP válido" unless TIPOS.include?(Marcel::MimeType.for(StringIO.new(bytes)))

    imagem = Vips::Image.new_from_buffer(bytes, "", access: :sequential, fail_on: :error)
    raise Invalida, "a imagem excede o limite de 40 megapixels" if imagem.width * imagem.height > LIMITE_PIXELS

    # thumbnail_buffer corrige a orientação EXIF, preserva a proporção e não amplia.
    imagem = Vips::Image.thumbnail_buffer(bytes, limite, height: limite, size: :down)
    saida = imagem.webpsave_buffer(Q: 82, strip: true, effort: 4)
    if saida.bytesize > LIMITE_SALVO
      imagem = Vips::Image.thumbnail_buffer(bytes, [ limite, 1200 ].min, height: [ limite, 1200 ].min, size: :down)
      saida = imagem.webpsave_buffer(Q: 76, strip: true, effort: 4)
    end
    raise Invalida, "a imagem tem detalhes demais; envie uma versão menor" if saida.bytesize > LIMITE_SALVO

    {
      io: StringIO.new(saida), filename: "#{File.basename(dados[:filename].to_s, '.*')}.webp",
      content_type: "image/webp", metadata: { width: imagem.width, height: imagem.height,
        analyzed: true, maison_otimizada: true }
    }
  rescue Vips::Error
    raise Invalida, "não foi possível ler a imagem; envie um JPG, PNG ou WebP válido"
  ensure
    io&.rewind
  end

  def self.transformacoes(tamanho)
    dimensoes = TAMANHOS.fetch(tamanho)
    { resize_to_limit: dimensoes, format: :webp, saver: { quality: 80, strip: true } }
  end
end
