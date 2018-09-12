require_relative '../adapter_helper'

adapter_require('rails') do

  require_relative '../../lib/bit_magic/railtie'

  describe BitMagic::Railtie do
    it 'should inject itself as a railtie' do
      Rails::Railtie.subclasses.must_include BitMagic::Railtie
    end
    
    it 'should be able to run the initializers' do
      BitMagic::Railtie.initializers.each(&:run)
    end
    
  end

end
