require_relative "./test_helper"

class BmBitsTest
  attr_accessor :flagz
  def initialize(flags = nil)
    @flagz = flags || rand(2**12)
  end
end


class BmBitsSubclassTest < BitMagic::Bits
  DEFAULT_OPTIONS = BitMagic::Bits::DEFAULT_OPTIONS.merge({default: 99, attribute_name: 'object_id'})
end

describe BitMagic::Bits do
  
  it 'should be able to initialize without a magician' do
    tester = BmBitsTest.new
    bits = BitMagic::Bits.new(tester, {:is_odd => 0, :count => [1, 2, 3], :is_cool => 4}, {attribute_name: 'flagz'})
    bits.attribute_name.must_equal 'flagz'
    bits.field_list.keys.must_equal [:is_odd, :count, :is_cool]
    bits.value.must_equal tester.flagz
  end
  
  it 'should be able to subclass to override defaults' do
    instance = Object.new
    tester = BmBitsSubclassTest.new(instance)
    tester.options[:default].must_equal 99
    tester.options[:attribute_name].must_equal 'object_id'
    tester.value.must_equal instance.object_id
  end
  
  
end
