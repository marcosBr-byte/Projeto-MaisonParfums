require "test_helper"

class ConteudoOfensivoTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "detecta ofensas com acentos letras separadas e substituicoes comuns" do
    [ "PORRA", "p0rr@", "p.u.t.a", "p o r r a", "desgraçado", "cuZÃO", "você é um idiota" ].each do |texto|
      assert ConteudoOfensivo.detectado?(texto), texto
    end
  end

  test "nao oculta criticas identidades nem palavras que contem trechos parecidos" do
    [ "Perfume ruim, não gostei", "Fixação péssima", "cheiro horrível", "embalagem bonita", "produto particular", "cuidado com o frasco", "Sou negro e gay" ].each do |texto|
      assert_not ConteudoOfensivo.detectado?(texto), texto
    end
  end
end
