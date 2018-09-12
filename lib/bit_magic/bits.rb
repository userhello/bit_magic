require_relative './bit_field'

module BitMagic
  # This is a wrapper class for objects that want bitfield functionality.
  # It implements bit field read, write and attribute field read and updating.
  #
  # This is usually used alongside Magician (an adapter helper class).
  #
  # If you're using this class directly, you can subclass it and set DEFAULT_OPTIONS
  # on your subclass to change default options.
  #
  # @example Subclass this class to change defaults
  #   # (do not set attribute_name to 'object_id' in real code, it's an example)
  #   class MyBits < BitMagic::Bits
  #     DEFAULT_OPTIONS = BitMagic::Bits::DEFAULT_OPTIONS.merge({default: 99, :attribute_name => 'object_id'})
  #   end
  #   # and now, if you initialize a new MyBits...
  #   MyBits.new(Object.new).options
  #   # will have default: 99 (instead of 0), and attribute_name: 'object_id'
  #   
  #
  # @attr_reader instance the instance we're doing operations for
  # @attr_reader [Hash] field_list a hash of field name => field bits key-pairs
  # @attr_reader [Hash] options options for this instance
  class Bits
    # This casts a given input value into a boolean.
    BOOLEAN_CASTER = lambda {|i| !(i == false or i == 0) }
    
    # Default options
    #
    # The bool_caster is expected to be overwritten depending on your use-case.
    # eg, form fields can send '0' or 'f' to mean false.
    DEFAULT_OPTIONS = {
      :attribute_name => 'flags',
      :default => 0,
      :updater => Proc.new {|bits, new_value| bits.instance.send(:"#{bits.attribute_name}=", new_value) },
      :bool_caster => BOOLEAN_CASTER
      }.freeze
    
    attr_reader :instance, :field_list, :options
    
    # This class wraps around any arbitrary objects (instance) that respond to
    # certain methods (a getter and setter for the flag field).
    #
    # @param [Object] instance some arbitrary object with bit_magic interest
    # @param [BitMagic::Adapters::Magician, Hash] magician_or_field_list either
    #   an instance of Magician (usually from an adapter) or a Hash with
    #   field name => bit/field bits array as key-pair.
    # @param [Hash] options additional options to override defaults
    # @option options [String] :attribute_name the name for the attribute, will
    #   be used as the getter and setter (by appending '=') on the instance object
    #   default: 'flags'
    # @option options [Integer] :default the default value. default: 0
    # @option options [Proc] :updater a callable (Proc/lambda/Method) used to
    #   update the bit field attribute after it has been changed.
    #   default: calls "#{attribute_name}=(newValue)" on instance
    # @option options [Proc] :bool_caster a callable (Proc/lambda/Method) used to
    #   cast some input value into a boolean (used with #write)
    #   default: cast false or 0 (integer) as false, everything else as true
    #
    # @example Initialize a Bits object
    #   Example = Struct.new('Example', :flags)
    #   # above, Example is a class with the 'flags' instance method
    #   # below, we initialize an instance with flags set to 0
    #   bits = BitMagic::Bits.new(Example.new(0), {:is_odd => 0, :amount => [1, 2, 3], :is_cool => 4})
    #
    # @return [BitMagic::Bits] a Bits object
    def initialize(instance, magician_or_field_list = {}, options = {})
      if defined?(BitMagic::Adapters::Magician) and magician_or_field_list.is_a?(BitMagic::Adapters::Magician)
        @magician = magician_or_field_list
        @field_list = @magician.field_list
        @options = @magician.action_options.merge(options)
      else
        @field_list = magician_or_field_list
        @options = self.class::DEFAULT_OPTIONS.merge(options)
      end
      @instance = instance
    end
    
    # Get the attribute name option (a method on the instance that returns the
    # current bit field value).
    #
    # In the future, attribute name may be a Proc. This class could also possibly
    # be subclassed and this method overwritten if advanced lookup is necessary.
    #
    # @return [String] name of the method we will use to get the bit field value
    def attribute_name
      @options[:attribute_name]
    end
    
    # Get the current value from the instance. It should return an integer if the
    # value exists, otherwise anything falsy will be set to the default value
    # given during initialization.
    # 
    # @return [Integer] the current value for the bit field
    def value
      value = @instance.send(attribute_name)
      value ||= @options[:default]
      value
    end
    
    # Update the bit field value on the instance with a new value using the updater
    # Proc given during initialization.
    #
    # @param [Integer] new_value the new value for the bit field
    #
    # @return returns the value returned by the updater, usually is the new_value
    def update(new_value)
      if @options[:updater].respond_to?(:call)
        @options[:updater].call(self, new_value)
      end
    end
    
    # Check whether all the given field name or bits are enabled (true or 1)
    # On fields with more than one bit, will return true if any of the bits are
    # enabled (value > 0)
    # 
    # @param [Symbol, Integer] fields one or more field names or bit indices
    #
    # @example Check fields to see if they are enabled
    #   # The struct is just an example, normally you would define a new class
    #   Example = Struct.new('Example', :flags)
    #   exo = Example.new(0)
    #   bits = Bits.new(exo, {:is_odd => 0, :amount => [1, 2, 3], :is_cool => 4})
    #   # we initialized flags to 0, so nothing is enabled
    #   bits.enabled?(:is_odd) #=> false
    #   bits.enabled?(:amount, :is_cool) #=> false
    #   bits.enabled?(10, 5, :is_odd) #=> false
    #
    #   # We now change flags on our instance object
    #   exo.flags = 5 # is_odd = 1, amount = 2, is_cool = 0
    #   bits.enabled?(:is_odd) #=> true
    #   bits.enabled?(:amount, :is_cool) #=> false
    #   bits.enabled?(:amount, :is_odd) #=> true
    #   bits.enabled?(:is_cool) #=> false
    #   
    #
    # @return [Boolean] true if ALL the given field bits are enabled
    def enabled?(*fields)
      memo = true
      field = self.field
      
      fields.flatten.each do |name|
        break unless memo
        memo &&= (read(name, field) >= 1)
      end
      
      memo
    end
    
    # Check whether all the given field names or bits are disabled (false or 0)
    # On fields with more than one bit, will return true only if the value of the
    # field is 0 (no bits set).
    # 
    # @param [Symbol, Integer] fields one or more field names or bit indices
    #
    # @example Check fields to see if they are disabled
    #   # The struct is just an example, normally you would define a new class
    #   Example = Struct.new('Example', :flags)
    #   exo = Example.new(0)
    #   bits = Bits.new(exo, {:is_odd => 0, :amount => [1, 2, 3], :is_cool => 4})
    #   # we initialized flags to 0, so everything is disabled
    #   bits.disabled?(:is_odd) #=> true
    #   bits.disabled?(:amount, :is_cool) #=> true
    #   bits.disabled?(10, 5, :is_odd) #=> true
    #
    #   # We now change flags on our instance object
    #   exo.flags = 5 # is_odd = 1, amount = 2, is_cool = 0
    #   bits.disabled?(:is_odd) #=> false
    #   bits.disabled?(:amount, :is_cool) #=> false
    #   bits.disabled?(:amount, :is_odd) #=> false
    #   bits.disabled?(:is_cool) #=> true
    #
    # @return [Boolean] true if ALL the given field bits are disabled (all bits
    #   are not set or false)
    def disabled?(*fields)
      memo = true
      field = self.field
      
      fields.flatten.each do |name|
        break unless memo
        memo &&= (read(name, field) == 0)
      end
      
      memo
    end
    
    # Get a BitField instance for the current value.
    #
    # Note: Value changes are NOT tracked and updated into the instance, so call
    # this method directly as needed.
    #
    # @return [BitMagic::BitField] a BitField object with the current value
    def field
      BitField.new(self.value)
    end
    
    # Read a field or bit from its bit index or name
    #
    # @param [Symbol, Integer] name either the name of the bit (a key in field_list)
    #   or a integer bit position
    # @param [BitField optional] field a specific BitField to read from.
    #   default: return value of #field
    #
    # @example Read bit values
    #   # The struct is just an example, normally you would define a new class
    #   Example = Struct.new('Example', :flags)
    #   exo = Example.new(9)
    #   bits = Bits.new(exo, {:is_odd => 0, :amount => [1, 2, 3], :is_cool => 4})
    #   bits.read(:is_odd) #=> 1
    #   bits.read(:amount) #=> 4
    #   bits.read(:is_cool) #=> 0
    #   bits.read(:amount, BitField.new(78)) #=> 7
    #   # Bonus: aliased as []
    #   bits[:is_odd] #=> 1
    #
    # @return [Integer] a value of the bit (0 or 1) or bits (number from 0 to
    #   (2**bit_length) - 1) or nil if the field name is not in the list
    def read(name, field = nil)
      field ||= self.field
      
      if name.is_a?(Integer)
        field.read_field(name)
      elsif bits = @field_list[name]
        field.read_field(bits)
      end
    end
    
    alias :[] :read
    
    # Write a field or bit from its field name or index
    #
    # Note: only the total bits of the field is used from the given value, so
    # any additional bits are ignored. eg: writing a field with one bit as value
    # of 4 will set the bit to 0, writing 5 sets it to 1.
    #
    # @param [Symbol, Integer, Array<Integer>] name a field name, or bit position,
    #   or array of bit positions
    # @param [Integer, Array<Integer>] target_value the target value for the field
    #   (note: technically, this can be anything that responds to :[](index), but
    #   usage in that type of context is discouraged without adapter support)
    #
    # @example Write values to bit fields
    #   # The struct is just an example, normally you would define a new class
    #   Example = Struct.new('Example', :flags)
    #   exo = Example.new(0)
    #   bits = Bits.new(exo, {:is_odd => 0, :amount => [1, 2, 3], :is_cool => 4})
    #   bits.write(:is_odd, 1) #=> 1
    #   bits.write(:amount, 5) #=> 11
    #   exo.flags #=> 11
    #   # Bonus, aliased as :[]=, but note in this mode, the return value is same as given value
    #   bits[:is_cool] = 1 #=> 1
    #   exo.flags #=> 27
    # 
    # @return the return value of the updater Proc, usually is equal to the final
    #   master value (with all the bits) after writing this bit
    def write(name, target_value)
      if name.is_a?(Symbol)
        self.write(@field_list[name], target_value)
      elsif name.is_a?(Integer)
        self.update self.field.write_bits(name => @options[:bool_caster].call(target_value))
      elsif name.respond_to?(:[]) and target_value.respond_to?(:[])
        bits = {}
        
        name.each_with_index do |bit, i|
          bits[bit] = @options[:bool_caster].call(target_value[i])
        end
        
        self.update self.field.write_bits bits
      end
    end
    
    alias :[]= :write
    
    # Inspect output. 
    #
    # @return [String] an #inspect value for this instance
    def inspect
      short_options = {}
      short_options[:default] = @options[:default]
      short_options[:attribute_name] = @options[:attribute_name]
      "#<#{self.class.to_s} #{@magician ? "bit_magic=#{@magician.bit_magic_name.inspect} " : nil}value=#{self.value}> options=#{short_options.inspect}"
    end
  end
end
