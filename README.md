# c-lightningrb: A ruby client library for lightningd

This package implements the Unix socket based JSON-RPC protocol that 
`lightningd` exposes to the rest of the world. 
It can be used to call arbitrary functions on the RPC interface, 
and serves as a basis for plugins written in ruby.

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

### Writing a plugin

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

