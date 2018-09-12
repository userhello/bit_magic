require_relative "../bit_magic"

module BitMagic
  class Railtie < Rails::Railtie
    
    initializer "my_railtie.configure_rails_initialization" do |app|
      
      # TODO: Consider switching this over to checking for the specific ORM
      # and loading into only that ORM
      
      if defined?(ActiveRecord)
        require_relative "./adapters/active_record_adapter"
        if !ActiveRecord::Base.is_a?(Adapters::ActiveRecordAdapter)
          ActiveRecord::Base.include Adapters::ActiveRecordAdapter
        end
      end
      
      if defined?(Mongoid::Document)
        require_relative "./adapters/mongoid_adapter"
        if !Mongoid::Document.is_a?(Adapters::MongoidAdapter)
          Mongoid::Document.include Adapters::MongoidAdapter
        end
      end
      
    end

  end
end
