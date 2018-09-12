module BitMagic
  # This is our Error class. There are many like it, but this one is ours.
  class Error < Exception; end
  
  class InputError < Error; end
  class FieldError < Error; end
end
