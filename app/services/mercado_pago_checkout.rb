require "net/http"
require "json"
require "openssl"

class MercadoPagoCheckout
  class Erro < StandardError; end
  ORDER_ID = /\AORD(?:TST)?[A-Z0-9]{1,64}\z/

  def initialize(configuracao = Configuracao.atual, http: Net::HTTP)
    @configuracao = configuracao
    @http = http
  end

  def criar(pedido)
    raise Erro, "Pagamento online indisponível. Entre em contato com a loja." unless @configuracao.pagamento_configurado?
    pedido.with_lock do
      raise Erro, "Este pedido não está aguardando pagamento." unless pedido.pendente?
      if pedido.reserva_expira_em && pedido.reserva_expira_em <= Time.current
        raise Erro, "O prazo da reserva terminou. Entre em contato com a loja."
      end
      if pedido.pagamento_url.present?
        raise Erro, "Checkout inválido. Entre em contato com a loja." unless self.class.url_segura?(pedido.pagamento_url)
        return pedido.pagamento_url
      end
      base = @configuracao.pagamento_site_url.delete_suffix("/")
      retorno = "#{base}/pedidos/#{pedido.id}/pagamento"
      total = format("%.2f", pedido.valor_total)
      resposta = requisitar(:post, "/v1/orders", {
        type: "online",
        processing_mode: "manual",
        total_amount: total,
        external_reference: pedido.pagamento_referencia,
        items: [{ title: "Pedido Maison Parfum ##{pedido.id}", quantity: 1, unit_price: total }],
        payer: { email: pedido.usuario.email },
        config: { online: { success_url: retorno, pending_url: retorno, failure_url: retorno, auto_return: "approved" } }
      }, chave: pedido.pagamento_referencia)
      url = resposta["checkout_url"]
      id = resposta["id"].to_s
      raise Erro, "O serviço não retornou um checkout válido." unless self.class.url_segura?(url) && id.match?(ORDER_ID)
      raise Erro, "As credenciais não correspondem ao ambiente selecionado." unless id.start_with?("ORDTST") == @configuracao.pagamento_teste?
      pedido.update!(pagamento_url: url, pagamento_order_id: id, pagamento_teste: @configuracao.pagamento_teste?)
      url
    end
  end

  def self.url_segura?(valor)
    uri = URI.parse(valor.to_s)
    uri.is_a?(URI::HTTPS) && %w[www.mercadopago.com.br sandbox.mercadopago.com.br].include?(uri.host) && uri.userinfo.nil? && (uri.port == 443)
  rescue URI::InvalidURIError
    false
  end

  def assinatura_valida?(id:, request_id:, assinatura:)
    return false if @configuracao.pagamento_webhook_secret.blank? || request_id.blank? || !id.to_s.match?(/\A[a-zA-Z0-9]{1,70}\z/)
    partes = assinatura.to_s.split(",").filter_map { |parte| parte.strip.split("=", 2) if parte.include?("=") }.to_h
    return false unless partes["ts"].to_s.match?(/\A\d+\z/) && partes["v1"].to_s.match?(/\A[0-9a-f]{64}\z/)
    # Preserve a caixa do data.id, como no validador oficial atual do SDK Ruby.
    mensagem = "id:#{id};request-id:#{request_id};ts:#{partes['ts']};"
    esperado = OpenSSL::HMAC.hexdigest("SHA256", @configuracao.pagamento_webhook_secret, mensagem)
    ActiveSupport::SecurityUtils.secure_compare(esperado, partes["v1"])
  end

  def atualizar(id)
    return atualizar_order(id) if id.to_s.match?(ORDER_ID)

    atualizar_pagamento_legado(id)
  end

  def atualizar_order(id)
    raise Erro, "Identificador inválido" unless id.to_s.match?(ORDER_ID)
    # Só consultamos cobranças criadas por esta loja; o corpo do webhook não
    # fornece valores nem estados confiáveis para confirmar um pedido.
    pedido = Pedido.find_by(pagamento_order_id: id)
    return unless pedido

    order = requisitar(:get, "/v1/orders/#{id}")
    pedido.with_lock do
      compativel = order["id"] == pedido.pagamento_order_id &&
        order["external_reference"] == pedido.pagamento_referencia &&
        order["currency"] == "BRL" && order["type"] == "online" &&
        valor_monetario(order["total_amount"]) == pedido.valor_total &&
        id.start_with?("ORDTST") == pedido.pagamento_teste?
      raise Erro, "Order incompatível com o pedido" unless compativel

      status = order["status"]
      detalhe = order["status_detail"]
      pagamentos = Array(order.dig("transactions", "payments"))
      pagamento = pagamentos.find { |item| item["status"] == "processed" && item["status_detail"] == "accredited" }
      aprovado = status == "processed" && detalhe == "accredited"
      if aprovado
        raise Erro, "Valor pago incompatível" unless valor_monetario(order["total_paid_amount"]) == pedido.valor_total &&
          pagamento && pagamento["id"].present? && valor_monetario(pagamento["paid_amount"]) == pedido.valor_total
        raise Erro, "O pedido já tem outro pagamento aprovado" if pedido.pagamento_id.present? && pedido.pagamento_id != pagamento["id"]
      end

      dados = { pagamento_status: status }
      if aprovado
        dados.merge!(pagamento_id: pagamento["id"], pagamento_metodo: pagamento.dig("payment_method", "id"))
        if pedido.cancelado?
          dados[:pagamento_requer_atencao] = true
        elsif pedido.pendente?
          dados.merge!(status: :pago, pago_em: Time.current, pagamento_requer_atencao: false)
        end
      end
      if status.in?(%w[refunded charged_back]) || detalhe == "partially_refunded" || Array(order.dig("transactions", "chargebacks")).any?
        dados[:pagamento_requer_atencao] = true
      end
      pedido.update!(dados)
    end
  end

  def atualizar_pagamento_legado(id)
    raise Erro, "Identificador inválido" unless id.to_s.match?(/\A\d+\z/)
    pagamento = requisitar(:get, "/v1/payments/#{id}")
    raise Erro, "Pagamento incompatível" unless pagamento["id"].to_s == id.to_s
    return if pagamento["external_reference"].blank?
    pedido = Pedido.find_by(pagamento_referencia: pagamento["external_reference"])
    return unless pedido && pedido.pagamento_preferencia.present?
    pedido.with_lock do
      raise Erro, "Valor ou ambiente do pagamento incompatível" unless pagamento["currency_id"] == "BRL" &&
        pagamento["transaction_amount"].to_s.to_d == pedido.valor_total &&
        pagamento["live_mode"] == !pedido.pagamento_teste?
      raise Erro, "O pedido já tem outro pagamento aprovado" if pedido.pagamento_id.present? && pedido.pagamento_id != id.to_s
      dados = { pagamento_status: pagamento["status"], pagamento_metodo: pagamento["payment_method_id"] }
      if pedido.cancelado? && pagamento["status"] == "approved"
        dados[:pagamento_requer_atencao] = true
        dados[:pagamento_id] = id.to_s
      elsif pagamento["status"].in?(%w[refunded charged_back])
        dados[:pagamento_requer_atencao] = true
      end
      if pagamento["status"] == "approved" && pedido.pendente?
        dados.merge!(pagamento_requer_atencao: false, status: :pago, pagamento_id: id.to_s, pago_em: Time.current)
      end
      # Recusas e eventos atrasados não cancelam um pedido nem desfazem sua entrega.
      pedido.update!(dados)
    end
  end

  private

  def valor_monetario(valor)
    BigDecimal(valor.to_s, exception: false)
  end

  def requisitar(metodo, caminho, corpo = nil, chave: nil)
    uri = URI("https://api.mercadopago.com#{caminho}")
    req = (metodo == :post ? Net::HTTP::Post : Net::HTTP::Get).new(uri)
    req["Authorization"] = "Bearer #{@configuracao.pagamento_token}"
    req["Content-Type"] = "application/json"
    req["X-Idempotency-Key"] = chave if chave
    req.body = JSON.generate(corpo) if corpo
    res = @http.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 15) { |cliente| cliente.request(req) }
    raise Erro, "O serviço de pagamento está indisponível. Tente novamente." unless res.code.to_i.between?(200, 299)
    dados = JSON.parse(res.body)
    raise Erro, "Resposta inválida do serviço de pagamento" unless dados.is_a?(Hash)
    dados
  rescue JSON::ParserError, IOError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError
    raise Erro, "Não foi possível comunicar com o serviço de pagamento. Tente novamente."
  end
end
