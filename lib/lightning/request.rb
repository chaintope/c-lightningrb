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
      params.values
    end

    def apply_result(result)
      @result = result
      json = {
          jsonrpc: '2.0',
          id: id,
          result: result
      }.to_json
      log.info "write response: #{json.to_s}"
      plugin.stdout.write(json.to_s + "\n\n")
      plugin.stdout.flush
    end

  end
end