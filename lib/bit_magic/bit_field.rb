require_relative "./error"

module BitMagic

  # Helper class to encapsulate bit field values and read/write operations
  # Note that indices are based off ruby bit reading, so least-significant bits
  # are to the right and negative numbers are handled as two's complement.
  #
  # @attr [Integer] value the current integer value that contains the bit fields
  class BitField
    attr_reader :value
    
    # Initialize the BitField with an optional value. Default is 0
    #
    # @param [Integer] value the integer that contains the bit fields
    def initialize(value = 0)
      if value.is_a?(Integer)
        @value = value
      else
        raise InputError.new("BitField#new expects an integer value, #{value.inspect} is not an integer")
      end
    end
    
    # Read the specified bit indices into a hash with bit index as key
    #
    # @param [Integer] bits one or more bit indices to read.
    #
    # @example Read a list of bits into a hash
    #   bit_field = BitField.new(5)
    #   bit_field.read_bits(0, 1, 2)
    #   #=> {0=>1, 1=>0, 2=>1}
    #   # because 5 is 101 in binary
    # 
    # @return [Hash] a hash with the bit index as key and bit (1 or 0) as value
    def read_bits(*args)
      {}.tap do |m|
        args.each { |bit| m[bit] = @value[bit] }
      end
    end
    
    # Read the specified bit indices as a group, in the order given
    #
    # @param [Integer] bits one or more bit indices to read. Order matters!
    # 
    # @example Read bits or a list of bits into an integer
    #   bit_field = BitField.new(101) # 1100101 in binary, lsb on the right
    #   bit_field.read_field(0, 1, 2) #=> 5 # or 101
    #   bit_field.read_field(0) #= 1
    #   bit_field.read_field( (2..6).to_a ) #=> 25 # or 11001
    #
    # @return [Integer] the value of the bits read together into an integer
    def read_field(*args)
      m = 0
      args.flatten.each_with_index do |bit, i|
        if bit.is_a?(Integer)
          m |= ((@value[bit] || 0) << i)
        end
      end
      m
    end
    
    alias :[] :read_field
    
    # Write to the specified bits, changing the internal @value to the new value
    #
    # @param [Hash] bit_values a hash with the key being a bit index and value
    #   being the value (must be 1, 0, true or false)
    #
    # @example Write new bit withs with their corresponding values
    #   bit_field = BitField.new
    #   bit_field.write_bits(0 => true) #=> 1
    #   bit_field.write_bits(1 => true, 4 => true) #=> 19 # 10011
    #   bit_field.write_bits(0 => false, 4 => false) #=> 2 # 10
    #
    # @return [Integer] the value after writing the new bits their new values
    def write_bits(bit_values = {})
      bit_values.each_pair do |index, val|
        
        if !index.is_a?(Integer)
          raise InputError.new("BitField#write can only access bits by their index, #{index.inspect} is not a valid index")
        end
        
        if index < 0
          raise InputError.new("BitField#write can not write to negative indices")
        end
        
        if !(val === true) and !(val === false) and !(val === 1) and !(val === 0)
          raise InputError.new("BitField#write must have a boolean value, #{val.inspect} is not a boolean")
        end
        
        if val === true or val === 1
          @value |= (1 << index)
        else
          @value &= ~(1 << index)
        end
      
      end
      
      @value
    end
    
  end
end
