require_relative '../test_helper'
require_relative '../../lib/bit_magic/adapters/base'

class Test8624
  attr_accessor :flags
  extend BitMagic::Adapters::Base
  def initialize
    @flags = 0
  end
end

describe BitMagic::Adapters::Base, :bit_magic do
  before do
    @k = Test8624
  end
  
  it 'should ensure field names are symbols' do
    ( proc {
        @k.bit_magic :nooju8, 8 => 98667
      }.must_raise BitMagic::FieldError
    ).message.must_include '98667'
    
    
    ( proc {
        @k.bit_magic :nooju3, 3 => 746.8
      }.must_raise BitMagic::FieldError
    ).message.must_include '746.8'
    
    ( proc {
        @k.bit_magic :nooju2, 2 => Kernel
      }.must_raise BitMagic::FieldError
    ).message.must_include 'Kernel'
    
    
    ( proc {
        @k.bit_magic :nooju9, 9 => [:boom]
      }.must_raise BitMagic::FieldError
    ).message.must_include 'boom'
  end
  
  it 'should ensure there are no duplicate field names' do
    ( proc {
        @k.bit_magic :miik, 0 => :pickle, 1 => :pickle
      }.must_raise BitMagic::FieldError
    ).message.must_include 'pickle'
  end
  
  it 'should define methods for the flag names' do
    @k.bit_magic :toop, 0 => :carrots, 1 => :oranges, 2 => :goldfish
    
    test = @k.new
    test.carrots.must_equal 0
    test.oranges = true
    test.oranges.must_equal 1
    test.oranges?.must_equal true
    test.goldfish?.must_equal false
  end
  
  it 'should define methods for field names' do
    @k.bit_magic :tiip, [0, 1] => :eyes, [2, 3, 4, 5, 6, 7] => :cupcakes
    
    test = @k.new
    test.eyes.must_equal 0
    test.eyes = 2
    test.eyes.must_equal 2
    
    test.cupcakes.must_equal 0
    test.flags = (31 << 2)
    test.cupcakes.must_equal 31
    test.eyes.must_equal 0
    test.cupcakes = 17
    test.cupcakes.must_equal 17
  end
  
  it 'should allow ranges as field bits' do
    @k.bit_magic :riig, 0..5 => :sick
    
    test = @k.new
    test.sick.must_equal 0
    test.sick = 27
    test.flags.must_equal 27
  end
  
  it 'should be able to access the bit field by name' do
    @k.bit_magic :wink, 0 => :t
    
    test = @k.new
    test.wink.must_be_kind_of BitMagic::Bits
    test.t = true
    test.wink[0].must_equal 1
  end
  
  it 'should be able to check if bits are enabled' do
    @k.bit_magic :want, 0 => :me, 1 => :you, 2 => :i
    
    test = @k.new
    test.want_enabled?(:me).must_equal false
    test.want_enabled?(:me, :you, :i).must_equal false
    test.me = true
    test.you = true
    test.want.enabled?(:me).must_equal true
    test.want.enabled?(:me, :you ,:i).must_equal false
    test.i = true
    test.want.enabled?(:me, :you ,:i).must_equal true
  end
  
  it 'should be able to check if bits are disabled' do
    @k.bit_magic :need, 0 => :me, 1 => :you, 2 => :i
    
    test = @k.new
    test.need_disabled?(:me).must_equal true
    test.need_disabled?(:me, :you, :i).must_equal true
    test.me = true
    test.you = true
    test.need.disabled?(:me).must_equal false
    test.need.disabled?(:me, :you ,:i).must_equal false
    test.i = true
    test.need.disabled?(:me, :you ,:i).must_equal false
  end
  
  
end
