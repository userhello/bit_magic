require_relative "../test_helper"
require_relative '../../lib/bit_magic/adapters/base'

module BitMagic
  module Adapters
    module CustomTestAdapter
      
      def self.included(klass)
        klass.extend Base
        klass.extend ClassMethods
      end
      
      module ClassMethods
        ADAPTER_DEFAULTS = {
          :truthy => [true, 1, ':]'],
          :default => (2**10-1),
          :attribute_name => :flaks
          }.freeze
        
        def bit_magic_adapter_defaults(options)
          ADAPTER_DEFAULTS.merge(options)
        end
      end
      
    end
  end
end


class Test5783
  attr_accessor :flaks
  include BitMagic::Adapters::CustomTestAdapter
  
  def initialize(val = nil)
    @flaks = val
  end
end

describe BitMagic::Adapters::CustomTestAdapter do

  before do
    @k = Test5783
  end

  it 'should be extended from Base' do
    @k.must_be_kind_of BitMagic::Adapters::Base
  end
  
  it 'should be able to set custom adapter options' do
    magician = @k.bit_magic :chickens, 0 => :buckle, 11 => :up
    magician.action_options[:attribute_name].must_equal :flaks
    
    test = @k.new
    test.buckle?.must_equal true
    
    test = @k.new(0)
    test.buckle?.must_equal false
  end
  
  
end
