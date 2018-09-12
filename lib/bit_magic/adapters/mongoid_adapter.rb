require_relative './base'

module BitMagic
  module Adapters
    # This is the adapter for Mongoid. It's implemented as a concern to be
    # included inside Mongoid::Document models.
    #
    # It's expected that you have an integer column (default name 'flags',
    # override using the attribute_name option). It's suggested, though not
    # required, that you set the default value same as the bit_magic default.
    # 
    # If you have more than one model that you want to use BitMagic in, it's
    # recommended that you just include this adapter globally:
    #   require 'bit_magic/adapters/mongoid_adapter'
    #   Mongoid::Document.include BitMagic::Adapters::MongoidAdapter
    #
    # Otherwise, you can include it on a per model basis before calling bit_magic
    #
    #   class Example
    #     include Mongoid::Document
    #     # this line below can be excluded if you included the adapter globally
    #     include BitMagic::Adapters::MongoidAdapter 
    #
    #     bit_magic :settings, 0 => :is_odd, [1, 2, 3] => :amount, 4 => :is_cool
    #     field :flags, type: Integer, default: 0
    #   end
    #   
    # After that, you can start using query helpers and instance helpers.
    # Query helpers return a standard Mongoid::Criteria, so you can do everything
    # you normally would in a query (like chaining additional conditions).
    # Instance helpers are wrapped around by a Bits object, in this case, 'settings'
    # but also have helper methods added based on the name of the fields.
    #
    module MongoidAdapter
      VERSION = "0.1.0".freeze
      extend ActiveSupport::Concern
      
      included do
        self.extend Base
      end
      
      module ClassMethods
        # Cast the given value into a Boolean, follows Mongoid::Boolean rules
        BIT_MAGIC_BOOLEAN_CASTER = lambda do |val|
          !!Mongoid::Boolean.mongoize(val)
        end
        
        # Adapter options specific to this adapter
        # 
        # :named_scopes Enables (true) or disables (false) individual scopes to
        # query fields
        # 
        # :query_by_value whether to use bitwise operations or IN (?) when querying
        # by default will use IN (?) if the total bits defined by bit_magic is
        # less than or equal to 8. true to always query by value, false to always
        # query using bitwise operations
        BIT_MAGIC_ADAPTER_DEFAULTS = {
          :bool_caster => BIT_MAGIC_BOOLEAN_CASTER,
          :named_scopes => true,
          :query_by_value => 8
        }.freeze
        
        # Method used to set adapter defaults as options to Magician,
        # Used by the bit_magic definition to add custom options to the magician
        #
        # @param [Hash] options some options list
        #
        # @return new options list including our custom defaults
        def bit_magic_adapter_defaults(options)
          BIT_MAGIC_ADAPTER_DEFAULTS.merge(options)
        end
        
        # This method is called by Base#bit_magic after setting up the magician
        # Here, we inject query helpers, scopes, and other useful methods
        #
        # Query helpers: (NAMESPACE is the name given to bit_magic)
        # All the methods that generate where queries take an optional options
        # hash as the last value. Can be used to alter options given to bit_magic.
        # eg: passing '{query_by_value: false}' as the last argument will force
        # the query to generate bitwise operations instead of '$in => []' queries
        # 
        #   NAMESPACE_query_helper(field_names = nil)
        #     an internal method used by other query helpers
        #   NAMESPACE_where_in(array, column_name = nil)
        #     generates a 'column_name => {:$in => [...]}' query for the array numbers
        #     column_name defaults to attribute_name in the options
        #   NAMESPACE_with_all(*field_names, options = {})
        #     takes one or more field names, and queries for values where ALL of
        #     them are enabled. For fields with multiple bits, they must be max value
        #     This is the equivalent of: field[0] and field[1] and field[2] ...
        #   NAMESPACE_with_any(*field_names, options = {})
        #     takes one or more field names, and queries for values where any of
        #     them are enabled
        #     This is the equivalent of: field[0] or field[1] or field[2] ...
        #   NAMESPACE_without_any(*field_names, options = {})
        #     takes one or more field names, and queries for values where at least
        #     one of them is disabled. For fields with multiple bits, any value
        #     other than maximum number
        #     This is the equivalent of "!field[0] or !field[1] or !field[2] ..."
        #   NAMESPACE_without_all(*field_names, options = {})
        #     takes one or more field names and queries for values where none of
        #     them are enabled (all disabled). For fields with multiple bits,
        #     value must be zero.
        #     This is the equivalent of: !field[0] and !field[1] and !field[2] ...
        #   NAMESPACE_equals(field_value_list, options = {})
        #     * this will truncate values to match the number of bits available
        #     field_value_list is a Hash with field_name => value key-pairs.
        #     generates a query that matches the bits to the value, exactly
        #     This is the equivalent of: field[0] = val and field[1] = value ...
        #
        # Additional named scopes
        # These can be disabled by passing 'named_scopes: false' as an option
        # FIELD is the field name for the bit/bit range
        #
        #   NAMESPACE_FIELD
        #     queries for values where FIELD has been enabled
        #   NAMESPACE_not_FIELD
        #     queries for values where FIELD has been disabled (not enabled)
        #   NAMESPACE_FIELD_equals(value)
        #     * only exists for fields with more than one bit
        #     queries for values where FIELD is exactly equal to value
        #
        # @param [Symbol] name the namespace (prefix) for our query helpers
        # 
        # @return nothing important
        def bit_magic_adapter(name)
          query_prep = :"#{name}_query_helper"
          query_in = :"#{name}_where_in"
          
          self.class_eval do
            define_singleton_method(query_prep) do |field_names = nil|
              magician = @bit_magic_fields[name]
              bit_gen = magician.bits_generator
              
              options = (field_names.is_a?(Array) and field_names.last.is_a?(Hash)) ? field_names.pop : {}
              
              by_value = options.key?(:query_by_value) ? options[:query_by_value] : magician.action_options[:query_by_value]
              
              by_value = (magician.bits_length <= by_value) if by_value.is_a?(Integer)
              column_name = options[:column_name] || magician.action_options[:column_name] || magician.action_options[:attribute_name]
              
              [magician, bit_gen, by_value, column_name]
            end
            
            define_singleton_method(query_in) do |column_name, arr|
              where(column_name => {:$in => arr})
            end
            
            define_singleton_method(:"#{name}_with_all") do |*field_names|
              magician, bit_gen, by_value, column_name = self.send(query_prep, field_names)
              
              if by_value === true
                self.send(query_in, column_name, bit_gen.all_of(*field_names))
              else
                where(column_name => {:$bitsAllSet => bit_gen.all_of_number(*field_names)})
              end
            end
            
            define_singleton_method(:"#{name}_without_any") do |*field_names|
              magician, bit_gen, by_value, column_name = self.send(query_prep, field_names)
              
              if by_value === true
                self.send(query_in, column_name, bit_gen.instead_of(*field_names))
              else
                where(column_name => {:$bitsAnyClear => bit_gen.any_of_number(*field_names)})
              end
            end
          
            define_singleton_method(:"#{name}_without_all") do |*field_names|
              magician, bit_gen, by_value, column_name = self.send(query_prep, field_names)
              
              if by_value === true
                self.send(query_in, column_name, bit_gen.none_of(*field_names))
              else
                where(column_name => {:$bitsAllClear => bit_gen.any_of_number(*field_names)})
              end
            end
            
            # Query for if any of these bits are set.
            define_singleton_method(:"#{name}_with_any") do |*field_names|
              magician, bit_gen, by_value, column_name = self.send(query_prep, field_names)
              
              if by_value === true
                self.send(query_in, column_name, bit_gen.any_of(*field_names))
              else
                where(column_name => {:$bitsAnySet => bit_gen.any_of_number(*field_names)})
              end
            end
            
            define_singleton_method(:"#{name}_equals") do |field_value, options = {}|
              magician, bit_gen, by_value, column_name = self.send(query_prep, [options])
              
              if by_value === true
                self.send(query_in, column_name, bit_gen.equal_to(field_value))
              else
                all_num, none_num = bit_gen.equal_to_numbers(field_value)
                where(column_name => {:$bitsAllSet => all_num, :$bitsAllClear => none_num})
              end
            end
            
          end
          
          
          if @bit_magic_fields and @bit_magic_fields[name] and @bit_magic_fields[name].action_options[:named_scopes]
            fields = @bit_magic_fields[name].field_list
            
            self.class_eval do
              fields.each_pair do |field, value|
                define_singleton_method(:"#{name}_#{field}") do
                  self.send(:"#{name}_with_all", field)
                end
                
                define_singleton_method(:"#{name}_not_#{field}") do
                  self.send(:"#{name}_without_all", field)
                end
                
                if value.is_a?(Array) and value.length > 1
                  define_singleton_method(:"#{name}_#{field}_equals") do |val|
                    self.send(:"#{name}_equals", field => val)
                  end
                end

              end

            end
          end
          
        end
      end
      
    end
  end
end
