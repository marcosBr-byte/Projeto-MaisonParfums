class Configuracao < ApplicationRecord
  encrypts :pagamento_token, :pagamento_webhook_secret
  validates :frete_pago_valor, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :validar_pagamento_online

  # O ambiente do servidor tem prioridade sobre os valores do painel.
  def pagamento_token
    ENV["MERCADO_PAGO_ACCESS_TOKEN"].presence || super
  end

  def pagamento_webhook_secret
    ENV["MERCADO_PAGO_WEBHOOK_SECRET"].presence || super
  end

  def pagamento_site_url
    ENV["MERCADO_PAGO_SITE_URL"].presence || super
  end

  def pagamento_ativo?
    return super unless ENV["MERCADO_PAGO_ATIVO"].present?

    ENV["MERCADO_PAGO_ATIVO"] == "true"
  end

  def pagamento_teste?
    return super unless ENV["MERCADO_PAGO_TESTE"].present?

    ENV["MERCADO_PAGO_TESTE"] != "false"
  end

  def pagamento_configurado?
    pagamento_ativo? && pagamento_token.present? && pagamento_webhook_secret.present? && url_pagamento_valida? && frete_pago_valor.present?
  end

  def url_pagamento_valida?
    uri = URI.parse(pagamento_site_url.to_s)
    uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil? && uri.query.nil? && uri.fragment.nil? && [ "", "/" ].include?(uri.path)
  rescue URI::InvalidURIError
    false
  end

  def validar_pagamento_online
    return unless pagamento_ativo?
    errors.add(:base, "Preencha o Access Token, a chave de assinatura e o endereço HTTPS da loja para ativar pagamentos.") unless pagamento_token.present? && pagamento_webhook_secret.present? && url_pagamento_valida?
    errors.add(:frete_pago_valor, "informe o frete para pedidos fora da campanha de frete grátis (use 0 para isentar)") if frete_pago_valor.nil?
  end

  has_rich_text :descricao
  before_validation { self[:descricao] = descricao.to_plain_text }

  before_validation { self.whatsapp_notificacao = whatsapp_notificacao.to_s.gsub(/\D/, "") }

  validates :desconto_percentual, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :brinde_meta, numericality: { greater_than: 0 }
  validates :frete_gratis_meta, :frete_gratis_meta_nordeste, numericality: { greater_than: 0 }
  validates :brinde_descricao, presence: true, if: :brinde_ativo?
  validates :borrifadas_por_ml, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 1000 }
  validates :whatsapp_notificacao, format: { with: /\A\d{10,15}\z/, message: "use apenas números, com código do país e DDD" }, if: :whatsapp_notificacoes_ativas?
  validate :integracao_whatsapp_disponivel

  def self.atual
    order(:id).first_or_create!
  end

  def percentual_vigente
    desconto_ativo? ? desconto_percentual : 0.to_d
  end

  def preco_com_desconto(preco)
    (preco.to_d * (1 - percentual_vigente / 100)).round(2)
  end

  def brinde_liberado?(total)
    brinde_ativo? && total.to_d >= brinde_meta
  end

  ESTADOS_NORDESTE = %w[AL BA CE MA PB PE PI RN SE].freeze
  FAIXAS_CEP = {
    "SP" => 10..199, "RJ" => 200..289, "ES" => 290..299, "MG" => 300..399,
    "BA" => 400..489, "SE" => 490..499, "PE" => 500..569, "AL" => 570..579,
    "PB" => 580..589, "RN" => 590..599, "CE" => 600..639, "PI" => 640..649,
    "MA" => 650..659, "PA" => 660..688, "AP" => 689..689, "AM" => [ 690..692, 694..698 ],
    "RR" => 693..693, "AC" => 699..699, "DF" => [ 700..727, 730..736 ],
    "GO" => [ 728..729, 737..767 ], "RO" => 768..769, "TO" => 770..779,
    "MT" => 780..788, "MS" => 790..799, "PR" => 800..879, "SC" => 880..899, "RS" => 900..999
  }.freeze

  def meta_frete_gratis(cep: nil, estado: nil)
    codigo = cep.to_s.strip
    return unless codigo.match?(/\A(?:\d{8}|\d{5}-\d{3})\z/)

    uf = estado.to_s.strip.upcase
    faixas = FAIXAS_CEP[uf]
    return unless faixas
    prefixo = codigo.delete("-")[0, 3].to_i
    return unless Array.wrap(faixas).any? { |faixa| faixa.cover?(prefixo) }

    ESTADOS_NORDESTE.include?(uf) ? frete_gratis_meta_nordeste : frete_gratis_meta
  end

  def frete_gratis_liberado?(total, cep: nil, estado: nil)
    meta = meta_frete_gratis(cep: cep, estado: estado)
    frete_gratis_ativo? && meta.present? && total.to_d >= meta
  end

  private

  def integracao_whatsapp_disponivel
    if whatsapp_notificacoes_ativas? && !WhatsAppPedido.configurado?
      errors.add(:base, "Configure as credenciais do WhatsApp no servidor antes de ativar os avisos.")
    end
  end
end
