require 'logger'
require 'tmpdir'

module Lightning

  module Logger

    Format = "%s, [%s#%d #%d] %5s -- %s: %s\n".freeze

    module_function

    # Create a logger with given +name+.log in $HOME/tmp/ruby-lightning.
    def create(name, level = ::Logger::INFO)
      dir = "#{Dir.tmpdir}/ruby-lightning"
      FileUtils.mkdir_p(dir)
      logger = ::Logger.new(dir + "/#{name}.log", 10)
      logger.level = level
      logger.formatter =  proc do |severity, datetime, progname, msg|
        Format % [severity[0..0], format_datetime(datetime), $$,
                  Thread.current.object_id, severity, progname, msg2str(msg)]
      end
      logger
    end

    def msg2str(msg)
      case msg
      when ::String
        msg
      when ::Exception
        "#{ msg.message } (#{ msg.class })\n" << (msg.backtrace || []).join("\n")
      else
        msg.inspect
      end
    end

    def format_datetime(time)
      time.strftime(@datetime_format || "%Y-%m-%dT%H:%M:%S.%6N ".freeze)
    end

  end

end