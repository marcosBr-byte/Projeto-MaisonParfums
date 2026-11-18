require "test_helper"

class RequestBodyLimitTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "rejeita corpo grande antes de chamar a aplicacao" do
    middleware = RequestBodyLimit.new(->(_env) { flunk "Não deve processar o corpo" })
    assert_equal 413, middleware.call("CONTENT_LENGTH" => (RequestBodyLimit::MAX_BYTES + 1).to_s).first
  end

  test "limita leitura de corpo sem tamanho declarado" do
    fonte = Object.new
    fonte.define_singleton_method(:read) { |limite| "x" * limite }
    input = RequestBodyLimit::LimitedInput.new(fonte)
    assert_raises(RequestBodyLimit::Exceeded) { input.read }
  end
end
