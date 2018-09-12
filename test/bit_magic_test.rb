require_relative "./test_helper"

describe BitMagic do
  it 'has a version number' do
    ::BitMagic::VERSION.wont_equal nil
    BitMagic.version.must_equal BitMagic::VERSION
  end
  
end
