require_relative '../adapter_helper'

adapter_require('sqlite3', ['activerecord', nil, 'active_record']) do
  require_relative "../../lib/bit_magic/adapters/active_record_adapter"
  require 'benchmark'
  
  ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: ':memory:',
    dbname: ':memory:' # older versions of active_record uses this
  )
    
  ActiveRecord::Schema.define do
    create_table :ar_test_cases, force: true do |t|
      t.integer :flags, index: true
    end
  end
  
  class ArTestCase < ActiveRecord::Base
    include BitMagic::Adapters::ActiveRecordAdapter
    bit_magic :case, 0 => :sherlock, [1, 2] => :watson, 3 => :vance
  end
  
  describe BitMagic::Adapters::ActiveRecordAdapter do
    it 'has a version number' do
      BitMagic::Adapters::ActiveRecordAdapter::VERSION.wont_equal nil
    end
    
    it 'should work after being included' do
      ArTestCase.must_respond_to :bit_magic
    end
    
    it 'should be able to query using with_any by value' do
      query = ArTestCase.case_with_any(:sherlock)
      count = query.count
      sherlock = ArTestCase.create(:flags => 1)
      sherwat = ArTestCase.create(:flags => 3)
      vance = ArTestCase.create(:flags => 8)
      query.count.must_equal count+2
      ids = query.pluck(:id)
      ids.must_include sherlock.id
      ids.must_include sherwat.id
      ids.wont_include vance.id
    end
    
    it 'should be able to query using with_any by bitwise operator' do
      query = ArTestCase.case_with_any(:vance, query_by_value: false)
      count = query.count
      vance = ArTestCase.create(:flags => 8)
      watson = ArTestCase.create(:flags => 10)
      sherlock = ArTestCase.create(:flags => 1)
      query.count.must_equal count+2
      ids = query.pluck(:id)
      ids.must_include vance.id
      ids.must_include watson.id
      ids.wont_include sherlock.id
    end
    
    it 'should be able to query using with_all by value' do
      query = ArTestCase.case_with_all(:watson)
      count = query.count
      watson = ArTestCase.create(:flags => 6)
      watvance = ArTestCase.create(:flags => 14)
      sherlock = ArTestCase.create(:flags => 1)
      query.count.must_equal count+2
      ids = query.pluck(:id)
      ids.must_include watson.id
      ids.must_include watvance.id
      ids.wont_include sherlock.id
    end
    
    it 'should be able to query using with_all by bitwise operator' do
      query = ArTestCase.case_with_all(:sherlock, query_by_value: false)
      count = query.count
      sherlock = ArTestCase.create(:flags => 1)
      watson = ArTestCase.create(:flags => 5)
      vance = ArTestCase.create(:flags => 8)
      query.count.must_equal count+2
      ids = query.pluck(:id)
      ids.must_include sherlock.id
      ids.must_include watson.id
      ids.wont_include vance.id
    end
    
    it 'should be able to query using without_any by value' do
      vance_query = ArTestCase.case_without_any(:vance)
      sherlock_query = ArTestCase.case_without_any(:sherlock, :watson)
      vance_count = vance_query.count
      sherlock_count = sherlock_query.count
      sherlock = ArTestCase.create(:flags => 1)
      vance = ArTestCase.create(:flags => 8)
      watson = ArTestCase.create(:flags => 7)
      
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
      vance_query = ArTestCase.case_without_any(:vance, query_by_value: false)
      sherlock_query = ArTestCase.case_without_any(:sherlock, :watson, query_by_value: false)
      vance_count = vance_query.count
      sherlock_count = sherlock_query.count
      sherlock = ArTestCase.create(:flags => 1)
      vance = ArTestCase.create(:flags => 9)
      watson = ArTestCase.create(:flags => 7)
      
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
      sherlock_query = ArTestCase.case_without_all(:sherlock)
      vance_query = ArTestCase.case_without_all(:sherlock, :vance)
      sherlock_count = sherlock_query.count
      vance_count = vance_query.count
      sherlock = ArTestCase.create(:flags => 1)
      vance = ArTestCase.create(:flags => 8)
      watson = ArTestCase.create(:flags => 7)
      watson2 = ArTestCase.create(:flags => 6)
      
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
      sherlock_query = ArTestCase.case_without_all(:sherlock, query_by_value: false)
      vance_query = ArTestCase.case_without_all(:sherlock, :vance, query_by_value: false)
      sherlock_count = sherlock_query.count
      vance_count = vance_query.count
      sherlock = ArTestCase.create(:flags => 1)
      vance = ArTestCase.create(:flags => 8)
      watson = ArTestCase.create(:flags => 7)
      watson2 = ArTestCase.create(:flags => 6)
      
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
      query = ArTestCase.case_equals(watson: 3)
      count = query.count
      watson3 = ArTestCase.create(:watson => 3)
      vance = ArTestCase.create(:vance => 1)
      query.count.must_equal count+1
      ids = query.pluck(:id)
      ids.must_include watson3.id
      ids.wont_include vance.id
    end
    
    it 'should be able to query using equal_to by bitwise operator' do
      query = ArTestCase.case_equals({watson: 2}, query_by_value: false)
      count = query.count
      watson2 = ArTestCase.create(:watson => 2)
      sherlock = ArTestCase.create(:sherlock => 1, :watson => 3)
      query.count.must_equal count+1
      ids = query.pluck(:id)
      ids.must_include watson2.id
      ids.wont_include sherlock.id
    end
    
    it 'should be able to work with bits' do
      target = 11 # 1011
      start = 2 # 10
      
      caze = ArTestCase.create(flags: start)
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
      if !defined?(ActiveRecord::Type::Boolean)
        skip # Can't test, nothing to fallback to
      else
        caze = ArTestCase.new flags: 15
        arbool = ActiveRecord::Type::Boolean
        ActiveRecord::Type.send(:remove_const, :Boolean)
        caze.vance = false
        caze.sherlock = '0'
        caze.watson.must_equal 3
        caze.watson = '1'
        caze.flags.must_equal 2
        ActiveRecord::Type::Boolean = arbool
      end
    end
    
    it 'should have named scopes' do
      count = ArTestCase.case_sherlock.count
      not_count = ArTestCase.case_not_sherlock.count
      ArTestCase.create(:sherlock => true)
      ArTestCase.case_sherlock.count.must_equal count+1
      ArTestCase.case_not_sherlock.count.must_equal not_count
    end
    
    it 'should have named scope for equality for fields with more than one bit' do
      ArTestCase.must_respond_to :case_watson_equals
      ArTestCase.wont_respond_to :case_sherlock_equals
      
      query = ArTestCase.case_watson_equals(2)
      count = query.count
      watson = ArTestCase.create(:watson => 2)
      query.count.must_equal count+1
      query.pluck(:id).must_include watson.id
    end
    
    
    
  end

end
