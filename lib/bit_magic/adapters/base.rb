require_relative '../../bit_magic'
require_relative './magician'
require_relative "../error"

module BitMagic
  module Adapters
    # This module is the core to all adapters. It provides the primary functionality
    # that's the starting point of all adapters: the bit_magic method.
    #
    # This module is intended to be extended into the class scope through an adapter.
    #
    # @example
    #   class X
    #     extend Base
    #   end
    #   X.bit_magic :name, 0 => :is_odd, 1 => :ok
    #
    module Base
      # This is the bit_magic method that will be injected into the target class
      # once this module is extended.
      #
      # @param [Symbol] name the name to use as a namespace for bit magic methods
      # @param [Hash] options any additional options, individual options are
      #   based off the adapter and Magician defaults.
      # 
      # @return [Magician] a Magician object for this invocation
      # @return [Hash] if no name is given, will return a Hash with all magicians
      def bit_magic(name = nil, options = {})
        @bit_magic_fields ||= {}
        return @bit_magic_fields if name == nil
        
        if self.respond_to?(:bit_magic_adapter_defaults)
          options = self.bit_magic_adapter_defaults(options)
        end
        
        name = name.to_sym
        
        @bit_magic_fields[name] = magician = Magician.new(name, options)
        
        @bit_magic_fields[name].define_bit_magic_methods self
        
        self.instance_eval do
          define_method(:"#{name}") do
            ivar = :"@bit_magic_#{name}"
            
            if instance_variable_defined?(ivar)
              instance_variable_get(ivar)
            else
              instance_variable_set(ivar, magician.bits_wrapper.new(self, magician))
            end
          end
        end
        
        self.bit_magic_adapter(name) if self.respond_to?(:bit_magic_adapter)
        
        @bit_magic_fields[name]
      end
    end
    
  end
end
