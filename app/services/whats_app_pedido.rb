require "net/http"
require "json"

class WhatsAppPedido
  class Erro < StandardError; end
  CHAVES = %w[WHATSAPP_ACCESS_TOKEN WHATSAPP_PHONE_NUMBER_ID WHATSAPP_API_VERSION WHATSAPP_TEMPLATE_NAME].freeze

  def self.configurado?
    CHAVES.all? { |chave| ENV[chave].present? } &&
      ENV["WHATSAPP_API_VERSION"].match?(/\Av\d+\.\d+\z/) &&
      ENV["WHATSAPP_PHONE_NUMBER_ID"].match?(/\A\d+\z/)
  end

  def self.enviar(pedido, configuracao, http: Net::HTTP)
    raise Erro, "Integração não configurada" unless configurado?
    uri = URI("https://graph.facebook.com/#{ENV.fetch('WHATSAPP_API_VERSION')}/#{ENV.fetch('WHATSAPP_PHONE_NUMBER_ID')}/messages")
    requisicao = Net::HTTP::Post.new(uri)
    requisicao["Authorization"] = "Bearer #{ENV.fetch('WHATSAPP_ACCESS_TOKEN')}"
    requisicao["Content-Type"] = "application/json"
    requisicao.body = {
      messaging_product: "whatsapp", to: configuracao.whatsapp_notificacao, type: "template",
      template: {
        name: ENV.fetch("WHATSAPP_TEMPLATE_NAME"), language: { code: ENV.fetch("WHATSAPP_TEMPLATE_LANGUAGE", "pt_BR") },
        components: [ { type: "body", parameters: [
          { type: "text", text: pedido.id.to_s },
          { type: "text", text: format("R$ %.2f", pedido.valor_total).tr(".", ",") }
        ] } ]
      }
    }.to_json
    resposta = http.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) { |cliente| cliente.request(requisicao) }
    raise Erro, "WhatsApp retornou HTTP #{resposta.code}" unless resposta.code.to_i.between?(200, 299)
    mensagem_id = JSON.parse(resposta.body).dig("messages", 0, "id")
    raise Erro, "WhatsApp não confirmou o recebimento" if mensagem_id.blank?
    mensagem_id
  rescue JSON::ParserError
    raise Erro, "Resposta inválida do WhatsApp"
  end
end
