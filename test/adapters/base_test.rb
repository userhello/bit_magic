require_relative '../test_helper'
require_relative '../../lib/bit_magic/adapters/base'

class Test1893
  extend BitMagic::Adapters::Base
end

describe BitMagic::Adapters::Base do
  before do
    @klass = Test1893
  end
  
  it 'should be able to extend onto a class' do
    @klass.must_be_kind_of BitMagic::Adapters::Base
  end
  
  it 'should be able to call bit_magic' do
    @klass.bit_magic(:pookums).must_be_kind_of BitMagic::Adapters::Magician
  end
  
end
