class PerfumeQuiz
  include ActiveModel::Model
  include ActiveModel::Attributes

  PERGUNTAS = {
    categoria: { titulo: "Qual perfil você procura?", ajuda: "Escolha como prefere explorar o catálogo.", opcoes: { "masculino" => "Masculino", "feminino" => "Feminino", "unissex" => "Unissex", "qualquer" => "Quero explorar todos" } },
    familias: { titulo: "Quais aromas mais combinam com você?", ajuda: "Escolha de uma a três famílias. Você pode misturar preferências.", opcoes: { "floral" => "Floral · flores e delicadeza", "citrica" => "Cítrica · frescor e energia", "amadeirada" => "Amadeirada · madeira e elegância", "oriental" => "Oriental · calor e especiarias", "fougere" => "Fougère · verde e clássico", "chipre" => "Chipre · terroso e sofisticado", "gourmand" => "Gourmand · doce e aconchegante", "aromatica" => "Aromática · ervas e frescor", "aquatica" => "Aquática · leveza e frescor" } },
    momento: { titulo: "Quando você pretende usar?", ajuda: "Pense na ocasião mais comum da sua rotina.", opcoes: { "dia" => "Durante o dia", "noite" => "À noite", "ambos" => "Quero versatilidade" } },
    intensidade: { titulo: "Que presença você prefere?", ajuda: "A intensidade é a classificação cadastrada pela loja, não uma promessa de duração.", opcoes: { "baixa" => "Discreta e suave", "media" => "Equilibrada", "alta" => "Marcante e intensa", "qualquer" => "Sem preferência" } }
  }.freeze

  attribute :categoria, :string
  attribute :momento, :string
  attribute :intensidade, :string
  attr_accessor :familias

  validates :categoria, inclusion: { in: PERGUNTAS[:categoria][:opcoes].keys }
  validates :momento, inclusion: { in: PERGUNTAS[:momento][:opcoes].keys }
  validates :intensidade, inclusion: { in: PERGUNTAS[:intensidade][:opcoes].keys }
  validate :familias_validas

  def respostas
    attributes.merge("familias" => Array(familias).reject(&:blank?).uniq)
  end

  private

  def familias_validas
    escolhidas = Array(familias).reject(&:blank?)
    unless escolhidas.size.between?(1, 3) && (escolhidas - PERGUNTAS[:familias][:opcoes].keys).empty?
      errors.add(:familias, "selecione de uma a três opções da lista")
    end
  end
end
