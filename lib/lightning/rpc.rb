module Lightning

  # RPC client for the `lightningd` daemon.
  class RPC

    attr_reader :socket_path
    attr_reader :log

    def initialize(socket_path, log)
      @socket_path = socket_path
      @log = log
    end

  end

end