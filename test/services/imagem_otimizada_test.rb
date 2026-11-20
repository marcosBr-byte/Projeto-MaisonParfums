require "test_helper"

class ImagemOtimizadaTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  def arquivo_grande
    coordenadas = Vips::Image.xyz(3200, 2400)
    x, y = coordenadas.bandsplit
    imagem = (x % 256).bandjoin([ y % 256, (x + y) % 256 ]).cast(:uchar)
    imagem.pngsave_buffer
  end

  test "upload principal e galeria sao armazenados menores em WebP sem original pesado" do
    bytes = arquivo_grande
    produto = Produto.new(nome: "Perfume otimizado", preco: 100)
    upload = -> { { io: StringIO.new(bytes), filename: "perfume.png", content_type: "image/png" } }
    assert_difference "ActiveStorage::Blob.count", 2 do
      produto.imagem = upload.call
      produto.fotos = [ upload.call ]
      produto.save!
    end
    [ produto.imagem, produto.fotos.first ].each do |anexo|
      blob = anexo.blob
      assert_equal "image/webp", blob.content_type
      assert_equal "perfume.webp", blob.filename.to_s
      assert blob.metadata["maison_otimizada"]
      imagem = Vips::Image.new_from_buffer(blob.download, "")
      assert_equal [ 1600, 1200 ], [ imagem.width, imagem.height ]
      assert_operator blob.byte_size, :<, bytes.bytesize
      assert_operator blob.byte_size, :<=, ImagemOtimizada::LIMITE_SALVO
    end
    assert_no_difference "ActiveStorage::Blob.count" do
      produto.update!(nome: "Nome atualizado")
    end
  end

  test "preserva transparencia e nao aumenta imagem pequena" do
    original = Vips::Image.black(40, 20).new_from_image([ 255, 0, 0, 0 ])
    dados = ImagemOtimizada.preparar({ io: StringIO.new(original.pngsave_buffer), filename: "transparente.png" })
    imagem = Vips::Image.new_from_buffer(dados[:io].read, "")
    assert_equal [ 40, 20 ], [ imagem.width, imagem.height ]
    assert imagem.has_alpha?
    assert_equal 0, imagem[3].max
  end

  test "corrige orientacao do celular e remove metadados" do
    original = Vips::Image.black(80, 40).new_from_image([ 255, 0, 0 ]).copy
    original.set_type(GObject::GINT_TYPE, "orientation", 6)
    dados = ImagemOtimizada.preparar({ io: StringIO.new(original.jpegsave_buffer), filename: "celular.jpg", content_type: "image/jpeg" })
    imagem = Vips::Image.new_from_buffer(dados[:io].read, "")
    assert_equal [ 40, 80 ], [ imagem.width, imagem.height ]
    assert_equal 0, imagem.get_typeof("exif-data")
  end

  test "upload invalido nao substitui imagem existente nem grava blob" do
    produto = Produto.create!(nome: "Perfume seguro", preco: 100,
      imagem: { io: File.open(Rails.root.join("public/icon.png")), filename: "foto.png", content_type: "image/png" })
    anterior = produto.imagem.blob.id
    assert_no_difference "ActiveStorage::Blob.count" do
      assert_not produto.update(imagem: { io: StringIO.new("nao e imagem"), filename: "falsa.png", content_type: "image/png" })
    end
    assert produto.errors[:imagem].any?
    assert_equal anterior, produto.reload.imagem.blob.id
  end

  test "recusa upload acima de 5 MB e imagem com excesso de pixels" do
    assert_raises(ImagemOtimizada::Invalida) do
      ImagemOtimizada.preparar({ io: StringIO.new("x" * (5.megabytes + 1)), filename: "grande.jpg", content_type: "image/jpeg" })
    end
    enorme = Vips::Image.black(10_000, 5_000).pngsave_buffer
    assert_raises(ImagemOtimizada::Invalida) do
      ImagemOtimizada.preparar({ io: StringIO.new(enorme), filename: "enorme.png", content_type: "image/png" })
    end
  end
end
