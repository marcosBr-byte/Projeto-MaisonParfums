require "test_helper"

class ConfiguracaoTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "ambiente tem prioridade e permite desativar pagamentos com segurança" do
    valores = {
      "MERCADO_PAGO_ACCESS_TOKEN" => "token-ficticio",
      "MERCADO_PAGO_WEBHOOK_SECRET" => "assinatura-ficticia",
      "MERCADO_PAGO_SITE_URL" => "https://loja.example",
      "MERCADO_PAGO_ATIVO" => "false",
      "MERCADO_PAGO_TESTE" => "true"
    }
    anteriores = valores.keys.to_h { |chave| [chave, ENV[chave]] }
    valores.each { |chave, valor| ENV[chave] = valor }
    configuracao = Configuracao.new(pagamento_ativo: true, pagamento_teste: false)
    assert_equal "token-ficticio", configuracao.pagamento_token
    assert_equal "assinatura-ficticia", configuracao.pagamento_webhook_secret
    assert configuracao.url_pagamento_valida?
    assert_not configuracao.pagamento_ativo?
    assert configuracao.pagamento_teste?
    ENV["MERCADO_PAGO_TESTE"] = "erro-de-digitacao"
    assert configuracao.pagamento_teste?
    ENV["MERCADO_PAGO_ACCESS_TOKEN"] = ""
    assert_nil configuracao.pagamento_token
  ensure
    anteriores&.each { |chave, valor| valor.nil? ? ENV.delete(chave) : ENV[chave] = valor }
  end
end
