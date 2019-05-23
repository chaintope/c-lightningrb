require 'spec_helper'

RSpec.describe Lightning::Plugin do

  describe '#add_method' do
    it 'should be added to handle targets' do
      cls = Lightning::Plugin
      cls.desc 'name', 'say hello method.'
      cls.define_rpc(:hello) do
      end
      cls.desc 'name', 'say hello2 method.'
      cls.define_rpc(:hello2) do
      end

      # can not define same name method.
      expect{cls.define_rpc(:hello){}}.to raise_error(ArgumentError, "hello was already defined.")
    end
  end

end