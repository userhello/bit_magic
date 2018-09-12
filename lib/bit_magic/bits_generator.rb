require_relative './bits'

module BitMagic
  # This module generates integers that are bit representations of given bits,
  # arrays of possible values with given bits, and arrays of possible values
  # given some condition on the bits.
  #
  # In short, it gives you a list of possible integer values from a list of bits.
  #
  # @attr_reader [Hash] field_list a hash of :name => bit or :name => [bit, bit, ..., bits] 
  #   key-value pairs for easier access of named bits/bit ranges
  # @attr_reader [Hash] options options given to the generator
  # @attr_reader [Integer] length the total number of bits specified
  # @attr_reader [Integer] bits an array of bits used in field_list, list of
  #   all the bits with which we will be working with
  # 
  class BitsGenerator
    attr_reader :field_list, :options, :length, :bits
    DEFAULT_OPTIONS = {default: 0, bool_caster: Bits::BOOLEAN_CASTER}.freeze
    
    # Initialize the generator.
    #
    # @param [BitMagic::Adapters::Magician, Hash] magician_or_field_list a Magician
    #   object that contains field_list, bits, and options OR a Hash object of 
    #   :name => bit index or bit index array, key-value pairs
    # @param [Hash] options options and defaults, will override Magician action_options
    #   if given
    # @option options [Integer] :default a default value, default: 0
    # @option options [Proc] :bool_caster a callable Method, Proc or lambda that
    #   is used to cast a value into a boolean
    #
    # @return [BitsGenerator] the resulting object
    def initialize(magician_or_field_list, options = {})
      if defined?(BitMagic::Adapters::Magician) and magician_or_field_list.is_a?(BitMagic::Adapters::Magician)
        @magician = magician_or_field_list
        @field_list = @magician.field_list
        @options = @magician.action_options.merge(options)
        @length = @magician.bits_length
        @bits = @magician.bits.uniq
      else
        @field_list = magician_or_field_list
        @options = DEFAULT_OPTIONS.merge(options)
        @bits = @field_list.values.flatten.uniq
        @length = @bits.length
      end
    end
    
    # Given a field name or list of field names, return their corresponding bits
    # Field names are the key values of the field_list hash during initialization
    #
    # @param [Symbol, Integer] one or more keys for the field name or an integer
    #    for a known bit index
    #
    # @example Get a list of bits
    #   gen = BitMagic::BitsGenerator.new(:is_odd => 0, :amount => [1, 2, 3], :is_cool => 4)
    #   gen.bits_for(:is_odd) #=> [0]
    #   gen.bits_for(:amount) #=> [1, 2, 3]
    #   gen.bits_for(:is_odd, :amount) #=> [0, 1, 2, 3]
    #   gen.bits_for(:is_cool, 5, 6) #=> [4, 5, 6]
    #   gen.bits_for(9, 10) #=> [9, 10]
    #
    # @return [Array<Integer>] an array of bit indices
    def bits_for(*field_names)
      bits = []
      
      field_names.flatten.each do |i|
        if i.is_a?(Integer)
          bits << i
          next
        end
        
        if i.respond_to?(:to_sym) and @field_list[i.to_sym]
          bits << @field_list[i.to_sym]
        end
      end
      
      bits.flatten
    end
    
    # Iterates over the entire combination of all possible values utilizing the
    # list of bits we are given.
    #
    # Warning: Because we are iteration over possible values, the total available
    # values grows exponentially with the given number of bits. For example, if
    # you use only 8 bits, there are 2*8 = 256 possible values, with 20 bits it
    # grows to 2**20 = 1048576. At 32 bits, 2**32 = 4294967296.
    #
    # Warning 2: We're using combinations to generate each individual number, so
    # there's additional overhead causing O(n!) complexity. Use carefully when 
    # you have large bit lists (more than 16 bits total). Check timing and memory.
    # 
    # @param [optional, Array<Integer>] each_bits a list of bits used to generate
    #   the combination list. default: the list of bits given during initialization
    # @param [Proc] block a callable method to yield individual values
    #
    # @yield num will yield to the given block multiple times, each time with one
    #   of the integer values that are possible from the given bits list
    #
    # @example Iterate over a list of bits
    #   gen = BitsGenerator.new(:is_odd => 0, :amount => [1, 2, 3], :is_cool => 4)
    #   values = []
    #   gen.each_value { |val| values << val } #=> 32
    #   values #=> [0, 1, 2, 4, 8, 16, 3, 5, 9, 17, 6, 10, 18, 12, 20, 24, 7, 11, 19, 13, 21, 25, 14, 22, 26, 28, 15, 23, 27, 29, 30, 31]
    #   values2 = []
    #   gen.each_value([0, 5]) { |val| values2 << val } #=> 4
    #   values2 #=> [0, 1, 32, 33]
    #
    #
    # @return [Integer] total number of values yielded
    def each_value(each_bits = nil, &block)
      # Warning! This has exponential complexity (time and space)
      # 2**n to be precise, use sparingly
      
      yield 0
      count = 1
      
      if @options[:default] != 0
        yield @options[:default]
        count += 1
      end
      
      each_bits = self.bits if each_bits == nil
      
      1.upto(each_bits.length).each do |i|
        each_bits.combination(i).each do |bits_list|
          num = bits_list.reduce(0) { |m, j| m |= (1 << j) }
          yield num
          count += 1
        end
      end
      
      count
    end
    
    # Gives you an array of all possible integer values based off the bit
    # combinations of the bit list.
    #
    # Note: This will include all possible values from the bit list, but there
    # are no guarantees on their order. If you need an ordered list, sort the result.
    #
    # Warning: Please see the warnings on each_value.
    # 
    # Warning: Memory usage grows exponentially to the number of bits! For example,
    # on a 64 bit platform (assuming pointers are 8 bytes) if you have 8 bits,
    # this array will have 256 values, taking up 2KB of memory. At 20 bits, it's
    # 1048576 values, taking up 8MB. At 32 bits, 4294967296 values take up 34GB!
    #
    # @param [optional, Array<Integer>] each_bits a list of bits used to generate
    #   the combination list. default: the list of bits given during initialization
    # @param [Hash] opts additional options
    # @option opts [Integer] :warn_threshold will output warning messages if
    #   the total number of bits is above this number. false to disable. default: 20 
    #
    # @example Get an array for all values from our bit list
    #   gen = BitsGenerator.new(:is_odd => 0, :amount => [1, 2, 3], :is_cool => 4)
    #   gen.all_values
    #
    # @return [Array<Integer>] an array of all possible values from the bit list
    #   Order is not guaranteed to be consistent.
    def all_values(each_bits = nil, opts = {warn_threshold: 12})
      # Shuffle things around so that people can call #all_values(warn_threshold: false)
      if each_bits.is_a?(Hash)
        opts = each_bits
        each_bits = nil
      end
      
      each_bits = self.bits if each_bits == nil
      
      if opts[:warn_threshold] and each_bits.length > opts[:warn_threshold]
        warn "There are #{each_bits.length} bits. You will have #{2**(each_bits.length)} values in the result. Please carefully benchmark the execution time and memory usage of your use-case."
        warn "You can disable this warning by using #all_values(warn_threshold: false)"
      end
      
      values = []
      
      self.each_value(each_bits) {|num| values << num }
      
      values
    end
    
    # Gives you an array of values where at least one of the bits of the field
    # names list is set to true (ie any of the bits are true).
    #
    # Possible values are derived from the bits list during initialization.
    #
    # Note: Order is not guaranteed. All numbers will be present, but there is
    # no expectation that the numbers will be in the same order every time. If
    # you need an ordered list, you can sort the result.
    # 
    # @param [Symbol, Integer] one or more keys for the field name or an integer
    #    for a known bit index
    #
    # @example Retrieve a list for odd numbers or cool numbers
    #   gen = BitsGenerator.new(:is_odd => 0, :amount => [1, 2, 3], :is_cool => 4)
    #   gen.any_of(:is_odd) #=> [1, 3, 5, 9, 17, 7, 11, 19, 13, 21, 25, 15, 23, 27, 29, 31]
    #   gen.any_of(:is_cool) #=> [16, 17, 18, 20, 24, 19, 21, 25, 22, 26, 28, 23, 27, 29, 30, 31]
    #   gen.any_of(:is_odd, :is_cool) # is_odd or is_cool, same as union of arrays above
    #   #=> [1, 16, 3, 5, 9, 17, 18, 20, 24, 7, 11, 19, 13, 21, 25, 22, 26, 28, 15, 23, 27, 29, 30, 31]
    #
    #
    # @return [Array<Integer>] an array of integer values with at least one of
    #   the bits set (true, bit is 1).  Will be blank if no field names given.
    def any_of(*field_names)
      [].tap do |list|
        any_num = any_of_number(*field_names)
        self.each_value { |num| list << num if (num & any_num) > 0 }
      end
    end
    alias :with_any :any_of
    
    # Gives you an array of values where all of these bits of the field names
    # list is set to false (ie without all of these bits as true).
    # 
    # Possible values are derived from the bits list during initialization.
    #
    # Note: Order is not guaranteed. All numbers will be present, but there is
    # no expectation that the numbers will be in the same order every time. If
    # you need an ordered list, you can sort the result.
    # 
    # @param [Symbol, Integer] one or more keys for the field name or an integer
    #    for a known bit index
    #
    # @example Retrieve a list for even numbers, or uncool numbers
    #   gen = BitsGenerator.new(:is_odd => 0, :amount => [1, 2, 3], :is_cool => 4)
    #   gen.none_of(:is_odd) #=> [0, 2, 4, 8, 16, 6, 10, 18, 12, 20, 24, 14, 22, 26, 28, 30]
    #   gen.none_of(:is_cool) #=> [0, 1, 2, 4, 8, 3, 5, 9, 6, 10, 12, 7, 11, 13, 14, 15]
    #   gen.none_of(:is_odd, :is_cool) #=> [0, 2, 4, 8, 6, 10, 12, 14]
    #   gen.none_of(:is_odd, :is_cool, :amount) #=> [0]
    #
    # @return [Array<Integer>] an array of integer values with all bits of given
    #   field names unset (false, bit is 0). Will be blank if no field names given.
    def none_of(*field_names)
      [].tap do |list|
        lack_num = any_of_number(*field_names)
        self.each_value { |num| list << num if (num & lack_num) == 0 }
      end
    end
    alias :without_all :none_of
    
    # Gives you an array of values where at least one of the bits of the field
    # names list is set to false (ie without any of these bits as true).
    # 
    # Possible values are derived from the bits list during initialization.
    #
    # Note: Order is not guaranteed. All numbers will be present, but there is
    # no expectation that the numbers will be in the same order every time. If
    # you need an ordered list, you can sort the result.
    # 
    # @param [Symbol, Integer] one or more keys for the field name or an integer
    #    for a known bit index
    #
    # @example Retrieve a list for even numbers, and uncool numbers
    #   gen = BitsGenerator.new(:is_odd => 0, :amount => [1, 2, 3], :is_cool => 4)
    #   gen.instead_of(:is_odd) #=> [0, 2, 4, 8, 16, 6, 10, 18, 12, 20, 24, 14, 22, 26, 28, 30]
    #   gen.instead_of(:is_odd, :is_cool) #=> [0, 1, 2, 4, 8, 16, 3, 5, 9, 6, 10, 18, 12, 20, 24, 7, 11, 13, 14, 22, 26, 28, 15, 30]
    #   gen.instead_of(:is_odd, :is_cool, :amount) #=> [0, 1, 2, 4, 8, 16, 3, 5, 9, 17, 6, 10, 18, 12, 20, 24, 7, 11, 19, 13, 21, 25, 14, 22, 26, 28, 15, 23, 27, 29, 30]
    #
    # @return [Array<Integer>] an array of integer values with at least one of
    #   the bits unset (false, bit is 0). Will be blank if no field names given.
    def instead_of(*field_names)
      [].tap do |list|
        none_num = any_of_number(*field_names)
        self.each_value { |num| list << num if (num & none_num) != none_num }
      end
    end
    alias :without_any :instead_of
    
    def all_of(*field_names)
      [].tap do |list|
        all_num = any_of_number(*field_names)
        self.each_value { |num| list << num if (num & all_num) == all_num }
      end
    end
    alias :with_all :all_of
    
    # Gives you an array of values where the given field names are exactly
    # equal to their given field values.
    # 
    # Possible values are derived from the bits list during initialization.
    #
    # Note: Order is not guaranteed. All numbers will be present, but there is
    # no expectation that the numbers will be in the same order every time. If
    # you need an ordered list, you can sort the result.
    # 
    # @param [Hash] one or more field names or an integer for a known bit index
    #   as the key, and the value (integer or boolean) for that field as the hash
    #   value. Values that have more bits than available will be truncated for
    #   comparison. eg. a field with one bit setting value to 2 means field is 0
    #
    # @example Get different amount values
    #   gen = BitsGenerator.new(:is_odd => 0, :amount => [1, 2, 3], :is_cool => 4)
    #   gen.equal_to(:amount => 5) #=> [10, 11, 26, 27]
    #   gen.equal_to(:amount => 7) #=>  [14, 15, 30, 31]
    #   gen.equal_to(:amount => 7, :is_odd => 1, :is_cool => 1) #=> [31]
    #
    # @return [Array<Integer>] an array of integer values where the bits and values
    #   match the given input
    def equal_to(field_values = {})
      all_num, none_num = self.equal_to_numbers(field_values)
      
      [].tap do |list|
        self.each_value { |num| list << num if (num & all_num) == all_num and (num & none_num) == 0 }
      end
    end
    
    # Will return an array of two numbers, the first of which has all bits set
    # where the corresponding value bit is 1, and the second has all bits set
    # where the corresponding value bit is 0.
    # These numbers can be used in advanced bitwise operations to test fields
    # for exact equality.
    # 
    # @param [Hash] one or more field names or an integer for a known bit index
    #   as the key, and the value (integer or boolean) for that field as the hash
    #   value. Values that have more bits than available will be truncated for
    #   comparison. eg. a field with one bit setting value to 2 means field is 0
    #
    # @example Retrieve the representation for various amounts
    #   gen = BitsGenerator.new(:is_odd => 0, :amount => [1, 2, 3], :is_cool => 4)
    #   gen.equal_to_numbers(:amount => 5) #=> [10, 4]
    #   # 5 is 101, 10 is 1010 and 4 is 100. (Note that amount uses bits 1, 2, 3)
    #   gen.equal_to_numbers(:amount => 7) #=> [14, 0]
    #   gen.equal_to_numbers(:amount => 7, :is_odd => 1) #=> [15, 0]
    #
    # 
    # @return [Array<Integer>] an array of two integers, first representing bits
    #   of given field bit values as 1 set to 1, and the second representing bits
    #   of given field bit values as 0 set to 1. See the example.
    def equal_to_numbers(field_values = {})
      fields = {}
      
      field_values.each_pair do |field_name, v|
        bits = self.bits_for(field_name)
        fields[bits] = v if bits.length > 0
      end
      
      all_num = 0
      none_num = 0
      fields.each_pair { |field_bits, val|
        field_bits.each_with_index do |bit, i|
          if @options[:bool_caster].call(val[i])
            all_num |= (1 << bit)
          else
            none_num |= (1 << bit)
          end
        end
      }
      
      [all_num, none_num]
    end
    
    # Get an integer with the given field names' bits all set. This number can
    # be used in bitwise operations to test field conditionals.
    # 
    # @param [Symbol, Integer] one or more keys for the field name or an integer
    #    for a known bit index
    #
    # @example Get a number representing odd numbers, or an arbitrary amount
    #   gen = BitsGenerator.new(:is_odd => 0, :amount => [1, 2, 3], :is_cool => 4)
    #   gen.any_of_number(:is_odd) #=> 1 # because 1 in binary is 00001
    #   gen.any_of_number(:amount) #=> 14 # because 14 is 01110
    #   gen.any_of_number(:is_odd, :amount, :is_cool) #=> 31
    #   # 31 is 11111 because all five bits (0 to 4) are true (one)
    #
    #
    # @return [Integer] the integer with all field names' bits are true 
    def any_of_number(*field_names)
      self.bits_for(*field_names).reduce(0) { |m, bit| m | (1 << bit) }
    end
    alias :with_any_number :any_of_number
    alias :with_all_number :any_of_number
    alias :all_of_number :any_of_number
    
    # Get an integer with the given field names' bits all unset. This number can
    # be used in bitwise operations to test field conditionals.
    #
    # Note: Because of ruby's handling of two's complement, this number is  
    # almost always a negative number.
    # 
    # @param [Symbol, Integer] one or more keys for the field name or an integer
    #    for a known bit index
    #
    # @example Get a number representing even numbers, or an arbitrary amount
    #   gen = BitsGenerator.new(:is_odd => 0, :amount => [1, 2, 3], :is_cool => 4)
    #   gen.none_of_number(:is_odd) #=> -2 # because -2 in binary is 1...11110
    #   gen.none_of_number(:amount) #=> -15
    #   # -15 in binary is 1...10001
    #   gen.none_of_number(:is_odd, :amount, :is_cool) #=> -32
    #   # -32 is 1...00000 because all five bits (0 to 4) are false (zero)
    #   
    # 
    # @return [Integer] the integer with all the field names' bits set to false
    def none_of_number(*field_names)
      ~self.any_of_number(*field_names)
    end
    alias :without_any_number :none_of_number
    alias :without_all_number :none_of_number
    
  end
end
