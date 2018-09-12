module BitMagic
  module Adapters
    # A container for bit_magic settings and fields
    # Meant to be used internally by the Base adapter (and by extension, all adapters).
    #
    # @attr_reader [Hash] field_options bit_magic options that define fields
    # @attr_reader [Hash] action_options bit_magic options that define settings
    # @attr_reader [Hash] field_list name => bits key pairs based off field_options
    # @attr_reader [Integer] bits_length total number of bits defined in field_options
    # @attr_reader [Integer] max_bit the largest bit defined in field_options
    # @attr_reader [Symbol] bit_magic_name the name given to bit_magic
    class Magician
      
      DEFAULT_ACTION_OPTIONS = Bits::DEFAULT_OPTIONS.merge({
        :query_by_value => true, # can be true, false, or a number of bits
        :helpers => true, # TODO: enable deeper access control over injected helper methods
        :bits_wrapper => Bits,
        :bits_generator => BitsGenerator,
        }).freeze
      
      # Checks if the key is a a field key definition (Integer or Range, defining
      # bit or bit ranges in question).
      #
      # @param [Integer, Range<Integer>] checkValue an integer bit or bit range
      #   to check if it is a valid bit index
      #
      # @return [Integer, Array<Integer>] will return an integer or an array of
      #   integers if the checkValue is a valid bit index or bit range
      def self.field_key_value_check(check)
        if check.is_a?(Integer)
          check
        elsif check.is_a?(Range)
          list = check.to_a
          valid = list.reduce(true) {|m, i| m && i.is_a?(Integer) }
          list if valid and list.length > 0
        elsif check.is_a?(Array)
          valid = true
          list = check.collect {|i|
            key = self.field_key_value_check(i)
            key.nil? ? (valid = false; break;) : key
          }.flatten
          list if valid and list.length > 0
        end
      end
      
      # Separate field and action options from the options passed to bit_magic
      #
      # Valid keys for field options are:
      #   Integer - for a specific bit position
      #   Range - for a range of bits
      #   Array<Integer> - an array of bit positions
      # The value of the key-pair should be a Symbol.
      #
      # Action options are everything else that's not a field option
      #
      # @param [Hash] options the options passed to bit_magic
      #
      # @return [Hash, Hash] returns an array of two options [field, actions]
      #   field options and action options, in that order respectively
      def self.options_splitter(options = {})
        field_opts = {}
        action_opts = DEFAULT_ACTION_OPTIONS.dup
        
        options.each_pair do |check_key, value|
          if key = self.field_key_value_check(check_key)
            field_opts[key] = value
          else
            if (!options[:allow_failed_fields]) and (check_key.is_a?(Integer) or check_key.is_a?(Range) or check_key.is_a?(Array))
              raise BitMagic::FieldError.new("key-pair expected to be a valid field option, but it is not: #{check_key.inspect} => #{value.inspect}. If this is an action option, you can disable this error by passing ':allow_failed_fields => true' as an option")
            end
            action_opts[check_key] = value
          end
        end
        
        [field_opts.freeze, action_opts.freeze]
      end
      
      attr_reader :field_options, :action_options
      attr_reader :field_list
      attr_reader :bits_length, :max_bit
      attr_reader :bit_magic_name
      
      # Initialize a new Magician, a container for bit_magic settings and fields
      #
      # @param [Symbol] name the name to be used as a namespace
      # @param [Hash] options the options given to bit_magic. Keys that are
      #   Integer, Arrays or Range objects are treated as bit allocations, their
      #   value should be the name of the bit field. Keys that are anything else
      #   (usually Symbol) are treated as action options or settings.
      #
      # @example Initialize a Magician (usually you would not do this directly)
      #   magician = Magician.new(:example, 0 => :is_odd, [1, 2] => :eyes, 3..6 => :fingers, default: 7)
      #   # here, field names are :is_odd, :eyes, and :fingers
      #   # with bits indices 0, [1, 2], and [3, 4, 5, 6] respectively
      #   # default is an action option, set to 7
      #
      # @return a Magician
      def initialize(name, options = {})
        @bit_magic_name = name
        @field_options, @action_options = self.class.options_splitter(options)
        validate_field_options!
      end
      
      # Define helper methods on the instance, namespaced to the name given in
      # the bit_magic invocation.
      #
      # This is an internal method, only meant to be used by the Base adapter to
      # during its setup phase. Should not be used directly.
      #
      # Methods that are defined is namespaced to the name during initialization.
      # Referred to here as NAMESPACE. These methods are available on instances.
      #
      #   NAMESPACE - defined by Base adapter, returns a Bits wrapper
      #   NAMESPACE_enabled?(*field_names) - checks if all the given field names
      #     or bit indices are enabled (value > 0)
      #   NAMESPACE_disabled?(*field_names) - checks if all the given field names
      #     or bit indices are disabled (value == 0)
      #   
      # The following are helpers, defined based on field names during initialization
      # Refered to here as 'name'.
      #
      #   name - returns the value of the field
      #   name=(new_value) - sets the value of the field to the new value
      #   name? - available only if the field is a single bit, returns true if 
      #     the value of the bit is 1, or false if 0
      #
      # 
      # @param [Class] klass the class to inject methods into.
      #
      # @return nothing useful.
      def define_bit_magic_methods(klass)
        names = @field_list
        bit_magic_name = @bit_magic_name
        
        klass.instance_eval do
        
          define_method(:"#{bit_magic_name}_enabled?") do |*fields|
            self.send(bit_magic_name).enabled?(*fields)
          end
        
          define_method(:"#{bit_magic_name}_disabled?") do |*fields|
            self.send(bit_magic_name).disabled?(*fields)
          end
        end
        
        if @action_options[:helpers]
        
          klass.instance_eval do
            names.each_pair do |name, bits|
              
              define_method(:"#{name}") do
                self.send(bit_magic_name)[name]
              end
              
              define_method(:"#{name}=") do |val|
                self.send(bit_magic_name)[name] = val
              end
              
              if bits.is_a?(Integer) or bits.length == 1
                define_method(:"#{name}?") do
                  self.send(bit_magic_name)[name] == 1
                end
              end
              
            end
          end
        
        end
        
      end
      
      # List of bits defined in @field_options
      # 
      # @return [Array<Integer>] an array of bits defined in @field_options
      def bits
        @field_list.values.flatten
      end
      
      # Used by the Base#bit_magic to create a Bits wrapper around instances
      # 
      # @return [Class] a Bits class
      def bits_wrapper
        self.action_options[:bits_wrapper] || Bits
      end
      
      # Used by adapters to generate value lists for particular bit operations
      #
      # @return [BitsGenerator] a BitsGenerator object with this magician's field
      #   list
      def bits_generator
        @bits_generator ||= (self.action_options[:bits_generator] || BitsGenerator).new self
      end
      
      # Inspect this object. This is customized just to shorten the output to
      # actually be readable.
      def inspect
        "#<#{self.class.to_s} name=#{@bit_magic_name} field_list=#{@field_list.inspect}>"
      end
      
      protected
      # Internal use only. Sets @field_list @bits_length and @max_bit from @field_options
      def validate_field_options!
        @field_list = {}
        
        @field_options.each_pair do |bits, name|
          name = name.to_sym if name.is_a?(String)
          
          if name.is_a?(Symbol)
            raise FieldError.new("'#{name}' defined more than once") if @field_list.has_key?(name)
            @field_list[name] = bits
          else
            raise FieldError.new("field name must be a symbol or string, #{name.inspect} is not")
          end
          
        end
        
        bits = self.bits
        @bits_length = bits.uniq.length
        @max_bit = bits.max
        @field_list.freeze
      end
      
    end
  
  end
end
