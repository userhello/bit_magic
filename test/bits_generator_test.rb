require_relative "./test_helper"
require_relative "../lib/bit_magic/adapters/base"

class Test1374
  extend BitMagic::Adapters::Base
  bit_magic :genten, 0 => :og, [1, 2] => :hai, 3 => :bae, [4, 5, 6] => :bai
end

describe BitMagic::BitsGenerator do

  before do
    @generator = Test1374.bit_magic[:genten].bits_generator
  end

  it 'should be retrievable from a magician' do
    @generator.must_be_kind_of BitMagic::BitsGenerator
  end
  
  it 'should read bits length' do
    @generator.length.must_equal 7
  end
  
  it 'should read bits' do
    @generator.bits.must_equal (0..6).to_a
  end
  
  it 'should read bits for positions and field names' do
    @generator.bits_for(0).must_equal [0]
    @generator.bits_for(:og, :hai).must_equal [0, 1, 2]
    @generator.bits_for(:hai, 0, 9).must_equal [1, 2, 0, 9]
    @generator.bits_for(:hai).must_equal [1, 2]
  end
  
  it 'should return empty array when reading without field names' do
    @generator.bits_for.must_equal []
    list = []
    @generator.bits_for(*list).must_equal []
  end
  
  it 'should be able to iterate all values' do
    all_values = []
    @generator.each_value { |num| all_values << num }
    all_values.sort.must_equal (0..127).to_a
  end
  
  it 'should be able to iterate over specified bits' do
    all_values = []
    @generator.each_value([1, 2, 4]) { |num| all_values << num }
    all_values.sort.must_equal [0, 2, 4, 6, 16, 18, 20, 22]
  end
  
  it 'should be able to get number for none of' do
    @generator.none_of_number(:og).must_equal -2
  end
  
  it 'should be able to get number for all of and any of' do
    @generator.all_of_number(:hai).must_equal 6
    @generator.any_of_number(:og).must_equal 1
  end
  
  it 'should get array for any of specified bits' do
    @generator.any_of(:hai).sort.must_equal [2, 3, 4, 5, 6, 7, 10, 11, 12, 13, 14, 15, 18, 19, 20, 21, 22, 23, 26, 27, 28, 29, 30, 31, 34, 35, 36, 37, 38, 39, 42, 43, 44, 45, 46, 47, 50, 51, 52, 53, 54, 55, 58, 59, 60, 61, 62, 63, 66, 67, 68, 69, 70, 71, 74, 75, 76, 77, 78, 79, 82, 83, 84, 85, 86, 87, 90, 91, 92, 93, 94, 95, 98, 99, 100, 101, 102, 103, 106, 107, 108, 109, 110, 111, 114, 115, 116, 117, 118, 119, 122, 123, 124, 125, 126, 127]
    @generator.any_of(:og).sort.must_equal (1..127).collect {|i| i % 2 == 0 ? nil : i }.compact
    @generator.any_of(:hai, :bae).sort.must_equal [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127]
  end
  
  it 'should get array for none of specified bits' do
    @generator.none_of(:og).sort.must_equal (0..127).collect {|i| i % 2 == 0 ? i : nil }.compact
    @generator.none_of(:hai).sort.must_equal [0, 1, 8, 9, 16, 17, 24, 25, 32, 33, 40, 41, 48, 49, 56, 57, 64, 65, 72, 73, 80, 81, 88, 89, 96, 97, 104, 105, 112, 113, 120, 121]
  
    @generator.none_of(:hai, :bae).must_equal [0, 1, 16, 32, 64, 17, 33, 65, 48, 80, 96, 49, 81, 97, 112, 113]
    @generator.none_of(:og, :hai, :bae, :bai).must_equal [0]
  end
  
  it 'should get array for all of specified bits' do
    @generator.all_of(:bae).sort.must_equal [8, 9, 10, 11, 12, 13, 14, 15, 24, 25, 26, 27, 28, 29, 30, 31, 40, 41, 42, 43, 44, 45, 46, 47, 56, 57, 58, 59, 60, 61, 62, 63, 72, 73, 74, 75, 76, 77, 78, 79, 88, 89, 90, 91, 92, 93, 94, 95, 104, 105, 106, 107, 108, 109, 110, 111, 120, 121, 122, 123, 124, 125, 126, 127]
    @generator.all_of(:og).sort.must_equal (1..127).collect {|i| i % 2 == 0 ? nil : i }.compact
    
    @generator.all_of(:hai, :bae).must_equal [14, 15, 30, 46, 78, 31, 47, 79, 62, 94, 110, 63, 95, 111, 126, 127]
  end
  
  it 'should get array for instead of specified bits' do
    @generator.instead_of(:bai).sort.must_equal (0..111).to_a
    @generator.instead_of(:bai, :og).sort.must_equal (0..126).to_a - [113, 115, 117, 119, 121, 123, 125]
    @generator.instead_of(:hai).sort.must_equal [0, 1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 13, 16, 17, 18, 19, 20, 21, 24, 25, 26, 27, 28, 29, 32, 33, 34, 35, 36, 37, 40, 41, 42, 43, 44, 45, 48, 49, 50, 51, 52, 53, 56, 57, 58, 59, 60, 61, 64, 65, 66, 67, 68, 69, 72, 73, 74, 75, 76, 77, 80, 81, 82, 83, 84, 85, 88, 89, 90, 91, 92, 93, 96, 97, 98, 99, 100, 101, 104, 105, 106, 107, 108, 109, 112, 113, 114, 115, 116, 117, 120, 121, 122, 123, 124, 125]
    @generator.instead_of(:og, :hai, :bae, :bai).sort.must_equal (0..126).to_a
  end
  
  it 'should include all values on merging any of and none of' do
    all = (0..127).to_a
    
    any_of_bai = @generator.any_of(:bai)
    none_of_bai = @generator.none_of(:bai)
    (any_of_bai + none_of_bai).sort.must_equal all
    
    any_of_og = @generator.any_of(:og)
    none_of_og = @generator.none_of(:og)
    (any_of_og + none_of_og).sort.must_equal all
  end
  
  it 'should include all_of in any_of values' do
    any_of_bae = @generator.any_of(:bae)
    all_of_bae = @generator.all_of(:bae)
    (any_of_bae & all_of_bae).sort.must_equal all_of_bae.sort
    
    any_of_bai = @generator.any_of(:bai)
    all_of_bai = @generator.all_of(:bai)
    (any_of_bai & all_of_bai).sort.must_equal all_of_bai.sort
  end
  
  it 'should not include none_of in all_of or any_of values' do
    any_of_hai = @generator.any_of(:hai)
    all_of_hai = @generator.all_of(:hai)
    none_of_hai = @generator.none_of(:hai)
    (any_of_hai & none_of_hai).must_equal []
    (all_of_hai & none_of_hai).must_equal []
    
    any_of_og = @generator.any_of(:og)
    all_of_og = @generator.all_of(:og)
    none_of_og = @generator.none_of(:og)
    (any_of_og & none_of_og).must_equal []
    (all_of_og & none_of_og).must_equal []
  end
  
  it 'should always include 0 as part of instead_of and none_of' do
    none_of = @generator.none_of(@generator.field_list.keys.sample)
    instead_of = @generator.instead_of(@generator.field_list.keys.sample)
    
    none_of.must_include 0
    instead_of.must_include 0
  end
  
  it 'should never include 0 as part of any_of and all_of' do
    any_of = @generator.any_of(@generator.field_list.keys.sample)
    all_of = @generator.all_of(@generator.field_list.keys.sample)
    
    any_of.wont_include 0
    all_of.wont_include 0
  end
  
  it 'should not share any bits in any_of_number and none_of_number' do
    any_of_bai = @generator.any_of_number(:bai)
    none_of_bai = @generator.none_of_number(:bai)
    (any_of_bai & none_of_bai).must_equal 0
    
    all_of_bae = @generator.all_of_number(:bae)
    none_of_bae = @generator.none_of_number(:bae)
    (all_of_bae & none_of_bae).must_equal 0
  end
  
  it 'should get array for equal_to' do
    @generator.equal_to(:hai => 1).sort.must_equal [2, 3, 10, 11, 18, 19, 26, 27, 34, 35, 42, 43, 50, 51, 58, 59, 66, 67, 74, 75, 82, 83, 90, 91, 98, 99, 106, 107, 114, 115, 122, 123]
    @generator.equal_to(:bai => 7).sort.must_equal (112..127).to_a
    @generator.equal_to(:bai => 7, :hai => 3).sort.must_equal [118, 119, 126, 127]
  end
  
  it 'should get numbers for equal_to_numbers' do
    @generator.equal_to_numbers(:hai => 1).must_equal [2, 4]
  end
  
  it 'should always yield 0 and default number as part of each_value' do
    test_default = rand(2**10)
    gen = BitMagic::BitsGenerator.new({}, {default: test_default})
    
    list = []
    gen.each_value { |i| list << i }
    
    list.must_include 0
    list.must_include test_default
    
    list.sort.must_equal gen.all_values.sort
  end
  
  it 'should be able to get an array of all possible values' do
    @generator.all_values.sort.must_equal (0..127).to_a
  end
  
  it 'should be able to initialize without a magician' do
    gen = BitMagic::BitsGenerator.new({:is_odd => 0, :count => [1, 2, 3], :is_cool => 4})
    gen.bits_for(:is_cool, :count).must_equal [4, 1, 2, 3]
    gen.any_of(:is_odd, :is_cool).sort.must_equal [1, 3, 5, 7, 9, 11, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]
    gen.all_of(:is_odd, :count).sort.must_equal [15, 31]
  end
  
  it 'should warn when you have too many bits' do
    gen = BitMagic::BitsGenerator.new(:a => (0..5).to_a, :b => (6..13).to_a)
    out, err = capture_io do
      gen.all_values
    end
    
    err.must_include (2**14).to_s
  end
  
  it 'should skip the warning if we ask it to' do
    gen = BitMagic::BitsGenerator.new(:a => (0..5).to_a, :b => (6..13).to_a)
    out, err = capture_io do
      gen.all_values(:warn_threshold => false)
    end
    
    err.wont_include (2**14).to_s
  end
  
  
  
end
