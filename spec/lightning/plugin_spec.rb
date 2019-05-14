require 'spec_helper'

RSpec.describe Lightning::Plugin do

  describe '#add_method' do
    it 'should be added to handle targets' do
      plugin = Lightning::Plugin.new
      hello = -> {puts "hello"}
      plugin.add_method(:hello, hello)
      # expect{plugin.}.to output("hello").to_stdout

      # can not register same name method.
      expect{plugin.add_method(:hello, hello)}.to raise_error(ArgumentError, "lambda: hello was already registered.")
    end
  end

end