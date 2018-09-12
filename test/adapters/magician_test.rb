require_relative '../test_helper'
require_relative '../../lib/bit_magic/adapters/base'

class Test4628
  extend BitMagic::Adapters::Base
  attr_accessor :flags
end

describe BitMagic::Adapters::Magician do
  before do
    @k = Test4628
  end
  
  it 'should allocate field names to their bits' do
    magician = @k.bit_magic :uthe, 0 => :zero, 1 => :one, 2 => :two, 3 => :three
    magician.field_list.keys.must_equal [:zero, :one, :two, :three]
    magician.field_list[:zero].must_equal 0
    magician.field_list[:three].must_equal 3
    magician.bits_length.must_equal 4
  end
  
  it 'should be inspectable' do
    magician = @k.bit_magic :balloon, 0 => :animals, 1 => :bomb, 2 => :boy
    ['Magician', 'animals', 'bomb', 'boy'].each { |i| magician.inspect.must_include i }
  end
  
  it 'should have a bits wrapper' do
    magician = @k.bit_magic :equines, 0 => :zebra, 1 => :horse, 2 => :pony
    bits = magician.bits_wrapper.new(@k.new, magician)
    bits.must_be_kind_of BitMagic::Bits
    ['equines', '0'].each {|i| bits.inspect.must_include i }
  end
  
  it 'should filter out (and raise errors on) invalid field options' do
    lambda {
      @k.bit_magic :bad, 0 => :ok, 'a'..'z' => :alphabet
    }.must_raise BitMagic::FieldError
  end
  
  it 'should not raise on field errors if explicitly told not to' do
    @k.bit_magic :baddy, 0 => :ok, 'a'..'z' => :alphabet, [] => :empty, 9..0 => :nothing, :allow_failed_fields => true
    
    action_opts = @k.bit_magic[:baddy].action_options
    action_opts['a'..'z'].must_equal :alphabet
    action_opts[[]].must_equal :empty
    action_opts[9..0].must_equal :nothing
  end

end
