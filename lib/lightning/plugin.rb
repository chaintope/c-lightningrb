require 'json'
require 'pathname'

module Lightning

  class Method

    TYPE = {rpc: 0, hook: 1}

    attr_reader :name
    attr_reader :method
    attr_reader :type

    def initialize(name, method, type = TYPE[:rpc])
      @name = name
      @method = method
      @type = type
    end

  end

  class Plugin

    attr_reader :methods
    attr_reader :subscriptions
    attr_reader :options
    attr_reader :stdout
    attr_reader :stdin
    attr_reader :log
    attr_accessor :lightning_dir
    attr_accessor :rpc_filename
    attr_accessor :rpc

    def initialize
      @methods = {init: Method.new(:init, self.method(:init))}
      @subscriptions = {}
      @options = {}
      @stdout = STDOUT
      @stdin = STDIN
      methods[:getmanifest] = Method.new(:getmanifest, self.method(:getmanifest))
      @log = Lightning::Logger.create(:plugin)
    end

    def init(options, configuration, request)
      log.info("init")
      @lightning_dir = configuration['lightning-dir']
      @rpc_filename = configuration['rpc-file']
      socket_path = (Pathname.new(lightning_dir) + rpc_filename).to_path
      @rpc = Lightning::RPC.new(socket_path, log)
      @options.merge!(options)
    end

    def getmanifest(request)
      log.info("getmanifest")
      rpc_methods = []
      hooks = []
      {
          options: options.values,
          rpcmethods: rpc_methods,
          subscriptions: subscriptions.keys,
          hooks: hooks,
      }
    end

    def add_method(name, lambda)
      m = name.to_s
      raise ArgumentError, "lambda: #{m} was already registered." if methods[m]
      methods[m] = lambda
    end

    def run
      log.info("Plugin run.")
      begin
      partial = ''
      stdin.each_line do |l|
        partial << l
        msgs = partial.split("\n\n", -1)
        next if msgs.size < 2
        partial = multi_dispatch(msgs)
      end
      rescue Exception => e
        log.error e
        throw e
      end
      log.info("Plugin end.")
    end

    private

    def multi_dispatch(msgs)
      msgs[0...-1].each do |payload|
        json = JSON.parse(payload)
        log.info("receive payload = #{json}")
        request = Lightning::Request.parse_from_json(self, json)
        if request.id
          dispatch_request(request)
        else
          dispatch_notification(request)
        end
      end
      msgs[-1]
    end

    def dispatch_request(request)
      method = methods[request.method]
      raise ArgumentError, "No method #{name} found." unless method
      log.info "request.method_args = #{request.method_args}"
      result = request.method_args.empty? ? method.method.call(self) : method.method.call(*request.method_args, self)
      log.info "result = #{result}"
      request.apply_result(result)
    end

    def dispatch_notification(request)
    end

  end
end