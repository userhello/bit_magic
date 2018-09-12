require_relative "./test_helper"

describe BitMagic::BitField do
  
  it 'should not initialize with values that are not integers' do
    Proc.new { BitMagic::BitField.new '' }.must_raise BitMagic::InputError
    Proc.new { BitMagic::BitField.new '3857' }.must_raise BitMagic::InputError
    Proc.new { BitMagic::BitField.new 98.88 }.must_raise BitMagic::InputError
    Proc.new { BitMagic::BitField.new({}) }.must_raise BitMagic::InputError
    Proc.new { BitMagic::BitField.new({:hi => 5}) }.must_raise BitMagic::InputError
    Proc.new { BitMagic::BitField.new nil }.must_raise BitMagic::InputError
  end
  
  it 'should default to 0' do
    field = BitMagic::BitField.new
    field.value.must_equal 0
  end
  
  it 'should be able to initialize with an integer value' do
    field = BitMagic::BitField.new 874
    field.value.must_equal 874
    
    bigfield = BitMagic::BitField.new 2**65
    bigfield.value.must_equal 2**65
  end
  
  it 'should be able to read individual bits' do
    field = BitMagic::BitField.new 157 # 10011101
    field.read_bits(0, 1, 2, 3, 7).must_equal({0=>1, 1=>0, 2=>1, 3=>1, 7=>1})
  end
  
  it 'should be able to read individual fields' do
    field = BitMagic::BitField.new 39 # 100111
    field.read_field(0, 1, 2).must_equal 7
    field.read_field(0, 1, 2, 3).must_equal 7
    field.read_field(0).must_equal 1
    field.read_field(3).must_equal 0
    field.read_field((0..5).to_a).must_equal 39
    field.read_field(0, 0, 0).must_equal 7
    field[5].must_equal 1
    field[4, 5].must_equal 2
  end
  
  it 'should be able to write values' do
    field = BitMagic::BitField.new 5 # 101
    field.write_bits(1 => true).must_equal 7
    field.value.must_equal 7
    field.write_bits(3 => true, 2 => false, 1 => false).must_equal 9
  end
  
  it 'should not be able to write non-integer bit positions' do
    field = BitMagic::BitField.new 5
    Proc.new { field.write_bits(8.8 => true) }.must_raise BitMagic::InputError
    Proc.new { field.write_bits('0' => false) }.must_raise BitMagic::InputError
    Proc.new { field.write_bits([0, 5] => true) }.must_raise BitMagic::InputError
    Proc.new { field.write_bits({} => true) }.must_raise BitMagic::InputError
  end
  
  it 'should not write to negative indices' do
    field = BitMagic::BitField.new 2**7-1
    Proc.new { field.write_bits(-8 => false) }.must_raise BitMagic::InputError
  end
  
  
  
  it 'should only accept boolean or 1 or 0 as values' do
    field = BitMagic::BitField.new 25
    field.write_bits(2 => true, 1 => 1).must_equal 31
    field.write_bits(2 => false, 1 => 0).must_equal 25
    
    Proc.new { field.write_bits(2 => -1) }.must_raise BitMagic::InputError
    Proc.new { field.write_bits(1 => '') }.must_raise BitMagic::InputError
    Proc.new { field.write_bits(3 => '0') }.must_raise BitMagic::InputError
    Proc.new { field.write_bits(2 => []) }.must_raise BitMagic::InputError
    Proc.new { field.write_bits(7 => {}) }.must_raise BitMagic::InputError
  end
  
  it 'should work with negative values' do
    # assuming 2s-complement
    # There's a caveat here, we can't change the sign bit! Will Ruby overflow it?
    field = BitMagic::BitField.new -1
    field.write_bits(0 => false).must_equal -2
    field.write_bits(1 => false).must_equal -4
    field.write_bits(0 => true, 1 => true).must_equal -1
    field = BitMagic::BitField.new -1
    field.write_bits(63 => false).must_equal -1*(2**63+1)
    field.write_bits(63 => true).must_equal -1
  end
  
  
  
  
  
end
