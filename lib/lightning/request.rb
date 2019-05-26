module Lightning

  # c-lightning request
  class Request

    attr_reader :plugin
    attr_reader :id
    attr_reader :method
    attr_reader :params
    attr_accessor :result
    attr_reader :log

    def initialize(plugin, id, method, params)
      @plugin = plugin
      @id = id
      @method = method
      @params = params
      @log = plugin.log
    end

    def self.parse_from_json(plugin, json)
      self.new(plugin, json['id'], json['method']&.to_sym, json['params'])
    end

    def method_args
      if params.is_a?(Array)
        params
      elsif params.is_a?(Hash)
        params.values
      else
        raise ArgumentError, "params does not support format. #{params}"
      end
    end

    # write response
    # @param [Hash] result the content of response
    def apply_result(result)
      @result = result
      json = {
          jsonrpc: '2.0',
          id: id,
          result: result
      }.to_json
      write(json.to_s)
    end

    # write error
    # @param [Exception] e an error.
    def write_error(e)
      error = {message: e.message}
      error[:code] = e.code if e.is_a?(Lightning::RPCError)
      json = {
          jsonrpc: '2.0',
          id: id,
          error: error
      }.to_json
      write(json.to_s)
    end

    private

    def write(content)
      log.info "write response: #{content}"
      plugin.stdout.write(content + "\n\n")
      plugin.stdout.flush
    end

  end
end