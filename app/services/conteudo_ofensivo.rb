class ConteudoOfensivo
  TERMOS = %w[porra caralho cacete puta puto foda foder fode fudeu fodase merda bosta cu cuzao arrombado arrombada desgraçado desgraçada vagabundo vagabunda piranha otario otaria imbecil idiota babaca viado viada fdp pqp].freeze
  PADROES = TERMOS.map do |termo|
    letras = I18n.transliterate(termo).chars.map { |letra| Regexp.escape(letra) }.join("[\\W_]*")
    Regexp.new("(?<![[:alnum:]])#{letras}(?![[:alnum:]])", Regexp::IGNORECASE)
  end.freeze

  def self.detectado?(texto)
    normalizado = I18n.transliterate(texto.to_s.unicode_normalize(:nfkc)).downcase
      .gsub(/[\u200B-\u200D\uFEFF]/, "").tr("013457@$", "oieastas")
    PADROES.any? { |padrao| padrao.match?(normalizado) }
  end
end
