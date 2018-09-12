# BitMagic

Bit field and bit flag utility library with integration for ActiveRecord and Mongoid.

| Project                 |  bit_magic        |
|------------------------ | ----------------- |
| gem name                |  bit_magic        |
| license                 |  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) |
| download rank           |  [![Total Downloads](https://img.shields.io/gem/rt/bit_magic.svg)](https://rubygems.org/gems/bit_magic) |
| homepage                |  [homepage (github)](https://github.com/userhello/bit_magic) |
| documentation           |  [rubydoc.info](https://www.rubydoc.info/gems/bit_magic/frames) |

## Summary

This gem provides basic utility classes for reading and writing specific bits as flags or fields on Integer values. It lets you turn a single integer value into a collection of boolean values (flags) or smaller numbers (fields). Includes integration adapters for ActiveRecord and Mongoid and a simple interface to make your own custom adapter for any other ORM (ActiveModel, ActiveResource, etc) or just a plan ruby class.

Flags can be used as though they were a boolean attribute and fields can be treated as an integer with limited range (based on the number of bits allocated to the field).

Pros:

* For SQL: No migrations necessary for new boolean attributes. For large tables with lots of rows and/or columns, this avoids costly `ALTER TABLE` calls.
* Only need to index one integer field, rather than multiple booleans
* Bitwise operations are fast!
* Save on database memory allocation. Since booleans are often stored as a full byte by many databases, using a 4-byte integer value allows up to 32 booleans for the same storage as 4.

Cons: (That's why you have this gem!)

* Querying individual boolean fields can be more complicated.
* Bit allocations need to be maintained
* Uses up more memory initially until you need more than a couple flags or fields


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bit_magic'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bit_magic

## Usage

Bit magic provides bare utility classes and integrations with Rails, ActiveRecord and Mongoid. Use the utility classes if you're working with bits directly such as within a library. For usage with ORMs, you'll want to use it with an integration, so you can skip the section on utility classes and go directly to your Integration below.

### Utility Classes

#### Bit Field

Bit Field is a wraper around integer values. 

_Note: Because of the way ruby handles Integers--and specifically negative integers with two's complement--it's currently not recommended to use this with a negative value. Read bits and write bits will work, but the value will always remain negative because there's no specific sign bit as the case with typecasted languages._

_If there's demand for it, I can implement byte sizes to restrict maximum size and define the sign bit. Let me know if you have a use case that requires it._

```ruby
field = BitMagic::BitField.new(0)
field.write_bits(1 => true, 2 => true, 5 => true)
# => 38 # in binary 38 is 100110
field.value
# => 38
field.read_bits(0, 1, 2, 3, 5)
# => {0=>0, 1=>1, 2=>1, 3=>0, 5=>1}
field.read_field(0)
# => 0
field.read_field(1, 2)
# => 3 # <- because '11' in binary is 3
field.read_field(1, 3, 2)
# => 5 # <- because '101' is 5
```

#### Bit Generator

Bits Generator is a generator for Integer bit representations or arrays of values that match certain bitwise criteria. The criteria are: 

| Name / Alias            |  Criteria         |
|------------------------ | ----------------- |
| with\_any / any\_of     | any of these bits specified are true |
| with\_all / all\_of     | all of these bits are true |
| without\_any / none\_of | none of these bits are true |
| without\_all / instead\_of | all of these bits are *not* true |
| equal\_to(field\_name => value) | the bits for field\_name must equal bits in value |

These all have a corresponding *_number method that returns an integer. (equal\_to's version is named equal\_to\_numbers and returns an array of two numbers, one for bit values 1 and the other for bit values 0).

* Warning: Although bitwise operations are fast, when using this class, you need to be careful when you use lots of bits (more than 20) to return arrays because memory usage grows exponentially! 2**20 is over 1 million, that's 8 megabytes of memory for the array on a 64-bit OS, with 24 bits, it explodes to 134 megabytes!

Example:

```ruby
gen = BitMagic::BitsGenerator.new({:is_odd => 0, :count => [1, 2, 3], :is_cool => 4})
gen.bits_for(:is_cool, :count)
# => [4, 1, 2, 3]
gen.any_of_number(:is_odd, :is_cool)
# => 17 # 10001 (4th bit for is_cool=1, 0th bit for is_odd=1)
gen.any_of(:is_odd, :is_cool) # same as gen.with_any(0, 4)
# => [1, 16, 3, 5, 9, 17, 18, 20, 24, 7, 11, 19, 13, 21, 25, 22, 26, 28, 15, 23, 27, 29, 30, 31]
# or some variation of the above, the order of the numbers is not guaranteed!
# you can #sort the array if you need well-defined ordering
gen.all_of(:is_odd, :count)
# => [15, 31]
# only available choices are 15 (is_cool = false) and 31 (is_cool = true)
gen.equal_to(:count => 5)

```

### Integrations

Integrations inject bit\_magic functionality into your ORM. ActiveRecord and Mongoid are supported and built-in. It's easy to build your own.

The built-in integrations add a class method, `bit_magic` to the class that it's included in. You call this method to define your integration name and flag bits on the model, and it becomes available as additional scopes for querying and instance methods.

| Config            |  What it does         |
|------------------ | --------------------- |
| :bool_caster      | a proc/lambda to use to cast input as a boolean. default varies by adapter |
| :named_scopes     | add extra named scopes for querying individual fields. default: true |
| :query\_by\_value | decides whether to query by value (arrays of individual values) or by bitwise operation. Can be true, false, or an integer. If it's an integer, it will use by value if the total bits defined is less than that value. default: 8 |
| :default          | the default value. default: 0 |
| :helpers          | add extra helper methods to read fields. default: true |
| :attribute\_name  | name of the method that returns the integer to use as the fields container. default: 'flags' |
| :column\_name     | (ActiveRecord only) name of the column. default: same as attribute\_name |
| :updater          | proc that sets the new value for the integer used as the fields container, receives instance as an argument. default: calls '#attribute_name=(value)' |

Example:

```ruby
class YourModel
  bit_magic :settings, 0 => :notify, [1, 2, 3] => :max_backlog, 4 => :disabled, :default => 0, :attribute_name => 'settings_flags'
end
```

You must have an integer column, field, or attribute in the table to use as the bit field container. By default, we assume it is named `flags`, you can change it with `:attribute_name => 'some_other_attribute'`. It also must be a different name than the `bit_magic :name`

Note: bits are zero-indexed, LSB first

Warning: because you are setting bits to have specific meanings, you can not change their meaning in the code without also doing a migration in the database. You can add new fields all you want, change the name, or even add additional bits to arrays of bit fields, but avoid changing one bit to have a different meaning and don't remove it from the list once defined. 

The bit field definition above will define methods based on the name given. For example, with the definition above, where the name is `:settings`, the following methods are defined:

* Class Methods:
  * YourModel.settings\_with\_any(*field\_names)
    returns a query where at least one of the listed fields are set to true
    This is equivalent to the conditional: `field[0] or field[1] or field[2] ...`
  * YourModel.settings\_with\_all(*field\_names)
    returns a query where all of the listed fields are set to true
    This is equivalent to the conditional: `field[0] and field[1] and field[2] ...`
  * YourModel.settings\_without\_any(*field\_names)
    returns a query where at least one of the listed fields are not set (set to false)
    This is equivalent to the conditional: `!field[0] or !field[1] or !field[2] ...`
  * YourModel.settings\_without\_all(*field\_names)
    returns a query where all of the listed fields are not set (set to false)
    This is equivalent to the conditional: `!field[0] and !field[1] and !field[2] ...`
  * YourModel.settings\_equals(field\_value\_list)
    takes a Hash of `field_name => value` key-pairs, and returns a query where
    the value of the bits of field\_name is equal to value (after truncating to
    total bits in the field)
    This is equivalent to the conditional: `field[0] = value[0] and field[1] = value[1] ...`
  * YourModel.settings\_notify [1]
    shorthand for `settings\_with\_all(:notify)`
  * YourModel.settings\_not\_notify [1]
    shorthand for `settings\_without\_all(:notify)`
  * YourModel.settings\_max\_backlog [1]
    shorthand for `settings\_with\_all(:max\_backlog)`
    note that because this is a field with 3 bits, it's equivalent to max\_backlog=4
  * YourModel.settings\_not\_max\_backlog [1]
    shorthand for `settings\_without\_all(:max\_backlog)`
  * YourModel.settings\_max\_backlog\_equals(val) [1]
    returns a query where max\_backlog equals the value. Note: Only compares bit up to 3 bits because that's how big max_backlog is.
  * YourModel.settings\_disabled [1] - shorthand for `settings\_with\_all(:disabled)`
  * YourModel.settings\_not\_disabled [1] - shorthand for `settings\_without\_all(:disabled)`
* Instance Methods
  * YourModel#settings - returns a Bits object for you to work with fields directly
  * YourModel#settings\_enabled?(\*field\_names) - shorthand for `settings.enabled?(\*field\_names)`
  * YourModel#settings\_disabled?(\*field\_names) - shorthand for `settings.disabled?(\*field\_names)`
  * YourModel#notify [2] - returns 1 or 0, shorthand for `settings.read(:notify)`
  * YourModel#notify? [2] - returns true or false, shorthand for `settings.read(:notify) == 1`
  * YourModel#notify=(val) [2] - sets value for notify flag, shorthand for `settings.write(:notify, val)`
  * YourModel#max\_backlog [2] - returns a number from 0 to 7 (3 bits), shorthand for `settings.read(:max_backlog)`
  * YourModel#max\_backlog=(val) [2]
    sets value for max\_backlog, only cares about the last 3 bits, so numbers larger than 3 bits are truncated.
    shorthand for `settings.write(:max\_backlog, val)`
  * YourModel#disabled [2] - returns 1 or 0, shorthand for `settings.read(:disabled)`
  * YourModel#disabled? [2] - returns true or false, shorthand for `settings.read(:disabled) == 1`
  * YourModel#disabled=(val) [2] - sets value for disabled

[1] You can disable these by adding `:named_scope => false` to the bit\_magic options.
[2] You can disable these by adding `:helpers => false` to the bit\_magic options.

#### Ruby on Rails

All official stable, maintained versions of Rails are supported. We include a railtie to activate integration seamlessly.

In your Gemfile, change the gem line to add the require railtie like below.

```ruby
gem 'bit_magic', require: 'bit_magic/railtie'
```

It will activate the ActiveRecord and/or Mongoid adapters globally if it finds it. You do not need to include the adapters as specified below if you go this route.

#### ActiveRecord

To make bit\_magic available to all your models, include the adapter into the Base class. This is done automatically if you are using the Rails integration as defined above.

```ruby
require 'bit_magic/adapters/active_record_adapter'
ActiveRecord::Base.include BitMagic::Adapters::ActiveRecordAdapter
```

Otherwise, you'll need to include it on every model where you want to use bit_magic:

```ruby
class YourModel < ActiveRecord::Base
  # the include below can be removed if activated globally above
  include BitMagic::Adapters::ActiveRecordAdapter
  
  # this defines the bits we will be using for our bitfield.
  # total usable bits is based off what int you are using in the database.
  bit_magic :example, 0 => :is_odd, 1 => :one, 2 => :two, 3 => :wiggle, [4, 5, 6] => :my_shoe
end
```

You must have an integer column or attribute in the table to use as the bit field container. By default, we assume the column is named `flags`. It should be `NOT NULL` and have a default set.

After defining `bit_magic :name`, you can use the methods signature described above.

#### Mongoid

To make bit\_magic available to all your models, include the adapter into the Document module. This is done automatically if you are using the Rails integration as defined above.

```ruby
require 'bit_magic/adapters/mongoid_adapter'
Mongoid::Document.include BitMagic::Adapters::MongoidAdapter
```

Otherwise, you'll need to include it on every model where you want to use bit_magic:

```ruby
class YourModel
  include Mongoid::Document
  
  # the include below can be removed if activated globally above
  include BitMagic::Adapters::MongoidAdapter
  
  # this defines the bits we will be using for our bitfield.
  bit_magic :example, 0 => :is_odd, 1 => :one, 2 => :two, 3 => :wiggle, [4, 5, 6] => :my_shoe
  field :flags, type: Integer, default: 0
end
```

You must have an integer field or attribute in the table to use as the bit field container. By default, we assume the column is named `flags`.

### Custom Integrations

You can make your own custom adapter for your own use-case. At its core, all integrations boil down to:

1. defining custom defaults via a class method `bit_magic_adapter_defaults(options)`
2. injecting base adapter functionality with `extend BitMagic::Adapters::Base`
3. injection of querying functionality via a class method `bit_magic_adapter(name)`

TODO: Better documentation on the process. In the meantime, you can look at the source for the ActiveRecord and Mongoid adapters for examples.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Adapters will need separate gems to be installed if you want to run them. ActiveRecordAdapter needs sqlite3 and activerecord. MongoidAdapter needs mongoid and a running Mongodb server. RailsAdapter needs rails (duh?). You can run them directly with `ruby [testfile]` to avoid bundler restricting the list to specifically bundled gems.

TODO: Define separate Gemfiles for adapter tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/userhello/bit_magic. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BitMagic project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/userhello/bit_magic/blob/master/CODE_OF_CONDUCT.md).
