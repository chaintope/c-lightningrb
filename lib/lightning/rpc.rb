require 'socket'
require 'json'

module Lightning

  class RPCError < StandardError

    INVALID_REQUEST = -32600
    METHOD_NOT_FOUND = -32601
    INVALID_PARAMS = -32602

    attr_reader :code
    attr_reader :message

    def initialize(code, message)
      @code = code
      @message = message
    end

  end

  # RPC client for the `lightningd` daemon.
  class RPC

    attr_reader :socket_path
    attr_accessor :next_id

    def initialize(socket_path)
      @socket_path = socket_path
      @next_id = 0
    end

    private

    def call(method, *kargs)
      UNIXSocket.open(socket_path) do |socket|
        msg = {
            method: method.to_s,
            params: kargs,
            id: next_id
        }
        socket.write(msg.to_json)
        self.next_id += 1
        response = ''
        loop do
          response << socket.gets
          break if response.include?("\n\n")
        end
        json = JSON.parse(response)
        raise RPCError.new(json['error']['code'], json['error']['message']) if json['error']
        json['result']
      end
    end

    def method_missing(method, *args)
      call(method, *args)
    end

  end

end