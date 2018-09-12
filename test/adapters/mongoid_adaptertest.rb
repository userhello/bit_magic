require_relative '../adapter_helper'

adapter_require('mongoid') do
  require_relative "../../lib/bit_magic/adapters/mongoid_adapter"
  
  class MongoTestCase
    include Mongoid::Document
    include BitMagic::Adapters::MongoidAdapter
    bit_magic :case, 0 => :sherlock, [1, 2] => :watson, 3 => :vance
    
    field :flags, type: Integer
  end
  
  config_path = File.expand_path File.join(File.dirname(__FILE__), 'mongoid.yml')
  if File.exist?(config_path)
    Mongoid.load!(config_path, :test)
    Mongoid.default_client.database.drop()
  else
    warn "mongoid.yml does not exist. Please create one. For an example, see: "
    warn config_path
  end
  
  describe BitMagic::Adapters::MongoidAdapter do
    before do
      begin
        Mongoid.default_client
      rescue Mongoid::Errors::NoClientConfig
        skip
      end
    end
    
    it 'should have a version' do
      BitMagic::Adapters::MongoidAdapter::VERSION.wont_equal nil
    end
    
    it 'should work after being included' do
      MongoTestCase.must_respond_to :bit_magic
    end
    
    it 'should be able to query using with_any by value' do
      query = MongoTestCase.case_with_any(:sherlock)
      count = query.count
      sherlock = MongoTestCase.create(:flags => 1)
      sherwat = MongoTestCase.create(:flags => 3)
      vance = MongoTestCase.create(:flags => 8)
      query.count.must_equal count+2
      ids = query.pluck(:id)
      ids.must_include sherlock.id
      ids.must_include sherwat.id
      ids.wont_include vance.id
    end
    
    it 'should be able to query using with_any by bitwise operator' do
      query = MongoTestCase.case_with_any(:vance, query_by_value: false)
      count = query.count
      vance = MongoTestCase.create(:flags => 8)
      watson = MongoTestCase.create(:flags => 10)
      sherlock = MongoTestCase.create(:flags => 1)
      query.count.must_equal count+2
      ids = query.pluck(:id)
      ids.must_include vance.id
      ids.must_include watson.id
      ids.wont_include sherlock.id
    end
    
    it 'should be able to query using with_all by value' do
      query = MongoTestCase.case_with_all(:watson)
      count = query.count
      watson = MongoTestCase.create(:flags => 6)
      watvance = MongoTestCase.create(:flags => 14)
      sherlock = MongoTestCase.create(:flags => 1)
      query.count.must_equal count+2
      ids = query.pluck(:id)
      ids.must_include watson.id
      ids.must_include watvance.id
      ids.wont_include sherlock.id
    end
    
    it 'should be able to query using with_all by bitwise operator' do
      query = MongoTestCase.case_with_all(:sherlock, query_by_value: false)
      count = query.count
      sherlock = MongoTestCase.create(:flags => 1)
      watson = MongoTestCase.create(:flags => 5)
      vance = MongoTestCase.create(:flags => 8)
      query.count.must_equal count+2
      ids = query.pluck(:id)
      ids.must_include sherlock.id
      ids.must_include watson.id
      ids.wont_include vance.id
    end
    
    it 'should be able to query using without_any by value' do
      vance_query = MongoTestCase.case_without_any(:vance)
      sherlock_query = MongoTestCase.case_without_any(:sherlock, :watson)
      vance_count = vance_query.count
      sherlock_count = sherlock_query.count
      sherlock = MongoTestCase.create(:flags => 1)
      vance = MongoTestCase.create(:flags => 8)
      watson = MongoTestCase.create(:flags => 7)
      
      vance_query.count.must_equal vance_count+2
      vids = vance_query.pluck(:id)
      vids.wont_include vance.id
      vids.must_include sherlock.id
      vids.must_include watson.id
      
      sherlock_query.count.must_equal sherlock_count+2
      sids = sherlock_query.pluck(:id)
      sids.wont_include watson.id
      sids.must_include sherlock.id
      sids.must_include vance.id
    end
    
    it 'should be able to query using without_any by bitwise operator' do
      vance_query = MongoTestCase.case_without_any(:vance, query_by_value: false)
      sherlock_query = MongoTestCase.case_without_any(:sherlock, :watson, query_by_value: false)
      vance_count = vance_query.count
      sherlock_count = sherlock_query.count
      sherlock = MongoTestCase.create(:flags => 1)
      vance = MongoTestCase.create(:flags => 9)
      watson = MongoTestCase.create(:flags => 7)
      
      vance_query.count.must_equal vance_count+2
      vids = vance_query.pluck(:id)
      vids.wont_include vance.id
      vids.must_include sherlock.id
      vids.must_include watson.id
      
      sherlock_query.count.must_equal sherlock_count+2
      sids = sherlock_query.pluck(:id)
      sids.wont_include watson.id
      sids.must_include sherlock.id
      sids.must_include vance.id
    end
    
    it 'should be able to query using without_all by value' do
      sherlock_query = MongoTestCase.case_without_all(:sherlock)
      vance_query = MongoTestCase.case_without_all(:sherlock, :vance)
      sherlock_count = sherlock_query.count
      vance_count = vance_query.count
      sherlock = MongoTestCase.create(:flags => 1)
      vance = MongoTestCase.create(:flags => 8)
      watson = MongoTestCase.create(:flags => 7)
      watson2 = MongoTestCase.create(:flags => 6)
      
      sherlock_query.count.must_equal sherlock_count+2
      ids = sherlock_query.pluck(:id)
      ids.wont_include sherlock.id
      ids.wont_include watson.id
      ids.must_include vance.id
      ids.must_include watson2.id
      
      vance_query.count.must_equal vance_count+1
      ids = vance_query.pluck(:id)
      ids.wont_include sherlock.id
      ids.wont_include vance.id
      ids.wont_include watson.id
      ids.must_include watson2.id
    end
    
    it 'should be able to query using without_all by bitwise operator' do
      sherlock_query = MongoTestCase.case_without_all(:sherlock, query_by_value: false)
      vance_query = MongoTestCase.case_without_all(:sherlock, :vance, query_by_value: false)
      sherlock_count = sherlock_query.count
      vance_count = vance_query.count
      sherlock = MongoTestCase.create(:flags => 1)
      vance = MongoTestCase.create(:flags => 8)
      watson = MongoTestCase.create(:flags => 7)
      watson2 = MongoTestCase.create(:flags => 6)
      
      sherlock_query.count.must_equal sherlock_count+2
      ids = sherlock_query.pluck(:id)
      ids.wont_include sherlock.id
      ids.wont_include watson.id
      ids.must_include vance.id
      ids.must_include watson2.id
      
      vance_query.count.must_equal vance_count+1
      ids = vance_query.pluck(:id)
      ids.wont_include sherlock.id
      ids.wont_include vance.id
      ids.wont_include watson.id
      ids.must_include watson2.id
    end
    
    it 'should be able to query using equal_to by value' do
      query = MongoTestCase.case_equals(watson: 3)
      count = query.count
      watson3 = MongoTestCase.create(:watson => 3)
      vance = MongoTestCase.create(:vance => 1)
      query.count.must_equal count+1
      ids = query.pluck(:id)
      ids.must_include watson3.id
      ids.wont_include vance.id
    end
    
    it 'should be able to query using equal_to by bitwise operator' do
      query = MongoTestCase.case_equals({watson: 2}, query_by_value: false)
      count = query.count
      watson2 = MongoTestCase.create(:watson => 2)
      sherlock = MongoTestCase.create(:sherlock => 1, :watson => 3)
      query.count.must_equal count+1
      ids = query.pluck(:id)
      ids.must_include watson2.id
      ids.wont_include sherlock.id
    end
    
    it 'should be able to work with bits' do
      target = 11 # 1011
      start = 2 # 10
      
      caze = MongoTestCase.create(flags: start)
      caze.case.must_be_kind_of BitMagic::Bits
      caze.watson.must_equal 1
      caze.watson = 3
      caze.flags.must_equal 6
      caze.sherlock = '1'
      caze.vance = true
      caze.flags.must_equal 15
      caze.watson = 1
      caze.flags.must_equal target
    end
    
    it 'should have a boolean cast fallback' do
      caze = MongoTestCase.new flags: 15
      caze.vance = false
      caze.sherlock = '0'
      caze.watson.must_equal 3
      caze.watson = '1'
      caze.flags.must_equal 2
    end
    
    
    it 'should have named scopes' do
      count = MongoTestCase.case_sherlock.count
      not_count = MongoTestCase.case_not_sherlock.count
      MongoTestCase.create(:sherlock => true)
      MongoTestCase.case_sherlock.count.must_equal count+1
      MongoTestCase.case_not_sherlock.count.must_equal not_count
    end
    
    it 'should have named scope for equality for fields with more than one bit' do
      MongoTestCase.must_respond_to :case_watson_equals
      MongoTestCase.wont_respond_to :case_sherlock_equals
      
      query = MongoTestCase.case_watson_equals(2)
      count = query.count
      watson = MongoTestCase.create(:watson => 2)
      query.count.must_equal count+1
      query.pluck(:id).must_include watson.id
    end
    
  end

end
