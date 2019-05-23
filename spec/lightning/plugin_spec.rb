require 'spec_helper'

RSpec.describe Lightning::Plugin do

  describe '#define rpc method' do
    it 'should be added to handle targets' do
      cls = Lightning::Plugin
      cls.desc 'name', 'say hello method.'
      cls.define_rpc(:hello, ->() {})
      cls.desc 'name', 'say hello2 method.'
      cls.define_rpc(:hello2, ->() {})

      # can not define same name method.
      expect{cls.define_rpc(:hello, ->() {})}.to raise_error(ArgumentError, "hello was already defined.")

      # define using proc
      expect{cls.define_rpc(:proc, Proc.new{})}.to raise_error(ArgumentError, "method must be implemented using lambda.")

      # define using hash
      expect{cls.define_rpc(:block, {})}.to raise_error(ArgumentError, "method must be implemented using lambda.")
    end
  end

end