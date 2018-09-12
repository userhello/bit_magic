require_relative "../bit_magic"

module BitMagic
  class Railtie < Rails::Railtie
    
    initializer "my_railtie.configure_rails_initialization" do |app|
      
      # TODO: Consider switching this over to checking for the specific ORM
      # and loading into only that ORM
      
      if defined?(ActiveRecord) and !ActiveRecord::Base.is_a?(Adapters::ActiveRecordAdapter)
        require_relative "./adapters/active_record_adapter"
        ActiveRecord::Base.include Adapters::ActiveRecordAdapter
      end
      
      if defined?(Mongoid::Document) and !Mongoid::Document.is_a?(Adapters::MongoidAdapter)
        require_relative "./adapters/mongoid_adapter"
        Mongoid::Document.include Adapters::MongoidAdapter
      end
      
    end

  end
end
