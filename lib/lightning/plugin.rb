require 'json'
require 'pathname'

module Lightning

  class Method

    TYPE = {rpc: 0, hook: 1}

    attr_reader :name
    attr_reader :type
    attr_reader :usage
    attr_reader :desc
    attr_reader :long_desc

    def initialize(name, usage = nil, desc = nil, type: TYPE[:rpc], long_desc: nil)
      @name = name
      @type = type
      @usage = usage
      @desc = desc
      @long_desc = long_desc
    end

    def rpc?
      type == TYPE[:rpc] && ![:init, :getmanifest].include?(name)
    end

    def hook?
      type == TYPE[:hook]
    end

    def to_h
      result = {name: name.to_s, usage: usage, description: desc}
      result[:long_description] = long_desc if long_desc
      result
    end

  end

  class Plugin

    class << self

      # get RPM methods.
      # @return [Hash] the hash of RPC method.
      def methods
        @methods ||= {}
      end

      # get subscriptions
      # @return [Hash] the hash of subscriptions
      def subscriptions
        @subscriptions ||= []
      end

      # get options
      def options
        @options ||= []
      end

      # Define option for lightningd command line.
      # @param [String] name option name.
      # @param [String] default default value.
      # @param [String] description description.
      def option(name, default, description)
        # currently only string options are supported.
        options << {name: name, default: default, description: description, type: 'string'}
      end

      # Define the definition of RPC method
      # @param [String] usage the usage of RPC method.
      # @param [String] desc the description of RPC method.
      # @param [String] long_desc (Optional) the long description of RPC method.
      def desc(usage, desc, long_desc = nil)
        @usage = usage
        @desc = desc
        @long_desc = long_desc
      end

      # Define RPC method.
      # @param [String] name the name of rpc method.
      # @param [Proc] lambda Lambda which is the substance of RPC method.
      def define_rpc(name, lambda)
        m = name.to_sym
        raise ArgumentError, 'method must be implemented using lambda.' unless lambda.is_a?(Proc) && lambda.lambda?
        raise ArgumentError, "#{m} was already defined." if methods[m]
        raise ArgumentError, "usage for #{m} dose not defined." unless @usage
        raise ArgumentError, "description for #{m} dose not defined." unless @desc
        define_method(m, lambda)
        methods[m] = Method.new(m, @usage, @desc, long_desc: @long_desc)
      end

      # Define Event notification handler.
      # @param [Symbol] event the event name.
      # @param [Proc] lambda Lambda which is the event handler.
      def subscribe(event, lambda)
        e = event.to_sym
        raise ArgumentError, 'handler must be implemented using lambda.' unless lambda.is_a?(Proc) && lambda.lambda?
        raise ArgumentError, "Topic #{e} already has a handler." if subscriptions.include?(e)
        define_method(e, lambda)
        subscriptions << e
      end

      # Define hook handler.
      # @param [Symbol] event the event name.
      # @param [Proc] lambda Lambda which is the event handler.
      def hook(event, lambda)
        e = event.to_sym
        raise ArgumentError, 'handler must be implemented using lambda.' unless lambda.is_a?(Proc) && lambda.lambda?
        raise ArgumentError, "Hook #{e} was already registered." if methods[e]
        define_method(e, lambda)
        methods[e] = Method.new(e, type: Method::TYPE[:hook])
      end

    end

    attr_reader :stdout
    attr_reader :stdin
    attr_reader :log
    attr_accessor :lightning_dir
    attr_accessor :rpc_filename
    attr_accessor :rpc

    def initialize
      methods[:init] = Method.new(:init)
      @stdout = STDOUT
      @stdin = STDIN
      methods[:getmanifest] = Method.new(:getmanifest)
      @log = Lightning::Logger.create(:plugin)
    end

    def init(opts, configuration)
      log.info("init")
      @lightning_dir = configuration['lightning-dir']
      @rpc_filename = configuration['rpc-file']
      socket_path = (Pathname.new(lightning_dir) + rpc_filename).to_path
      @rpc = Lightning::RPC.new(socket_path)
      opts.each do |key, value|
        options.find{|o|o[:name] == key}[:value] = value
      end
      nil
    end

    # get manifest information.
    # @return [Hash] the manifest.
    def getmanifest
      log.info("getmanifest")
      {
          options: options,
          rpcmethods: rpc_methods.map(&:to_h),
          subscriptions: subscriptions,
          hooks: hook_methods.map(&:name),
      }
    end

    # shutdown this plugin.
    def shutdown
      log.info "Plugin shutdown"
    end

    # run plugin.
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
      rescue Interrupt
        log.info "Interrupt occur."
        shutdown
      end
      log.info("Plugin end.")
    end

    private

    # get method list
    # @return [Hash] the hash of method.
    def methods
      self.class.methods # delegate to class instance
    end

    # get subscriptions
    def subscriptions
      self.class.subscriptions # delegate to class instance
    end

    # get options
    def options
      self.class.options # delegate to class instance
    end

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
      begin
        method = methods[request.method]
        raise ArgumentError, "No method #{request.method} found." unless method
        result = request.method_args.empty? ? send(method.name) : send(method.name, *request.method_args)
        request.apply_result(result) if result
      rescue Exception => e
        log.error e
        request.write_error(e)
      end
    end

    def dispatch_notification(request)
      begin
        name = request.method
        raise ArgumentError, "No handler #{request.method} found." unless subscriptions.include?(request.method)
        request.method_args.empty? ? send(name) : send(name, *request.method_args)
      rescue Exception => e
        log.error e
      end
    end

    def rpc_methods
      methods.values.select(&:rpc?)
    end

    def hook_methods
      methods.values.select(&:hook?)
    end

  end
end