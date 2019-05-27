#!/usr/bin/env ruby
require 'lightning'

class HelloPlugin < Lightning::Plugin

  desc '[name]', 'Returns a personalized greeting for {greeting} (set via options).'
  define_rpc :hello, -> (name) do
    log.info "log = #{log}"
    "hello #{name}"
  end

  option 'greeting', 'World', "What name should I call you?"

end

p = HelloPlugin.new
p.run