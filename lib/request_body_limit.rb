class RequestBodyLimit
  MAX_BYTES = 110 * 1024 * 1024
  class Exceeded < StandardError; end

  class LimitedInput
    def initialize(input)
      @input = input
      @bytes = 0
    end

    def read(*args)
      restante = MAX_BYTES - @bytes + 1
      tamanho = args[0].nil? ? restante : [ args[0], restante ].min
      data = args.length > 1 ? @input.read(tamanho, args[1]) : @input.read(tamanho)
      @bytes += data.to_s.bytesize
      raise Exceeded if @bytes > MAX_BYTES
      data
    end

    def gets(*args)
      restante = MAX_BYTES - @bytes + 1
      separador = args.first.is_a?(String) || args.first.nil? ? args.first : $/
      limite = args.first.is_a?(Integer) ? args.first : args[1]
      data = @input.gets(separador, limite ? [ limite, restante ].min : restante)
      @bytes += data.to_s.bytesize
      raise Exceeded if @bytes > MAX_BYTES
      data
    end

    def each
      while (line = gets)
        yield line
      end
    end

    def rewind
      @input.rewind
      @bytes = 0
    end
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    return too_large if env["CONTENT_LENGTH"].to_i > MAX_BYTES
    env["rack.input"] = LimitedInput.new(env["rack.input"]) if env["rack.input"]
    @app.call(env)
  rescue Exceeded
    too_large
  end

  private

  def too_large
    [ 413, { "content-type" => "text/plain; charset=utf-8", "cache-control" => "no-store" }, [ "Arquivo ou requisição muito grande." ] ]
  end
end
