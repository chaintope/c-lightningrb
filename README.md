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

### Using the JSON-RPC client

```ruby
require 'lightning'

# initialize RPC interface using unix socket file.
rpc = Lightning::RPC.new('/home/azuchi/.lightning/lightning-rpc')

puts rpc.getinfo

=> {
  "id": "02a7581f5aafd3ed01a6664ad5108ce1601435d9e9e47c57f1c40cff152cd59307",
  "alias": "GREENPHOTO",
  "color": "02a758",
  "num_peers": 0,
  "num_pending_channels": 0,
  "num_active_channels": 0,
  "num_inactive_channels": 0,
  "address": [

  ],
  "binding": [
    {
      "type": "ipv6",
      "address": "::",
      "port": 9735
    },
    {
      "type": "ipv4",
      "address": "0.0.0.0",
      "port": 9735
    }
  ],
  "version": "v0.7.0",
  "blockheight": 1518441,
  "network": "testnet",
  "msatoshi_fees_collected": 0,
  "fees_collected_msat": "0msat"
}

puts rpc.invoice(1000, 'example', 'test payment')

=> {
     "payment_hash": "76b2f5d6791a2e0be44071543c71d27238e2153fd832ac23d8c027b33e024fb8",
     "expires_at": 1558856940,
     "bolt11": "lntb10n1pww5dkupp5w6e0t4nerghqhezqw92rcuwjwguwy9flmqe2cg7ccqnmx0szf7uqdq5w3jhxapqwpshjmt9de6qcqp2phn9mgplxj2mxg59zjrlhwh2p66h2r3p4f7kyk8w4s3zcma5htn807r8lgfmg75hwcvhse8sqtgcyakgezdzjc0zyd87uahe3wsz3qcp4nv6f0",
     "warning_capacity": "No channels have sufficient incoming capacity"
   }
```

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

