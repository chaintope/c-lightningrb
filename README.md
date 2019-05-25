# c-lightningrb: A ruby client library for lightningd [![Build Status](https://travis-ci.org/chaintope/c-lightningrb.svg?branch=master)](https://travis-ci.org/chaintope/c-lightningrb) [![Gem Version](https://badge.fury.io/rb/c-lightningrb.svg)](https://badge.fury.io/rb/c-lightningrb) [![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

This library is for writing c-lightning plugins in Ruby.
You can write your own RPC, event notifications, and Hooks in DSL.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'c-lightningrb', require: 'lightning'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install c-lightningrb

## Examples

### Writing a plugin

You can write your own Plugin by inheriting `Lightning::Plugin`.

```ruby
#!/usr/bin/env ruby
require 'lightning'

class HelloPlugin < Lightning::Plugin

  # define new rpc. Usage and description are required only for the definition of RPC.
  desc '[name]', 'Returns a personalized greeting for {greeting} (set via options).'
  define_rpc :hello, -> (name) do
    log.info "log = #{log}"
    "hello #{name}"
  end

  # add subscription for event notification
  subscribe :connect, ->(id, address) do
    log.info "received connect notification. id = #{id}, address = #{address}"
  end

  subscribe :disconnect, ->(id) do
    log.info "received disconnect notification. id = #{id}"
  end

  # add Hook
  hook :peer_connected, ->(peer) do
    log.info "peer_connected. peer = #{peer}"
    {result: 'continue'}
  end

end

p = HelloPlugin.new
p.run
```

Write all RPC, notification, and hook handlers in Lambda. 
These Lambdas are implemented as methods, so you can access any of the fields and methods of the Plugin.

And it works if you specify Plugin as the parameter when c-lightning launches.

```
$ lightningd --plugin=<above file path>
```

Note: Plugin file needs execute permission.

Note: If you write logs to stdout with puts etc., it will be sent as a response to lightningd. 
Therefore, if you want to output the log, please use Plugin#log logger. 
This log is output to under /tmp/ruby-lightnig directory.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

