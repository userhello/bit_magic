# TODO

* Test against different versions of integration adapters (ActiveRecord and Mongoid). And in the case of ActiveRecord, test against different databases also.
* Allow value returns on field names, something like:
````
[0, 1] => {:name => :values, 0 => :nothing, 1 => :one, 2 => :two, 3 => :three}

values = :three
values #=> 3
values_name #=> :four
`

* Strict checking of field attributes (currently they override, we're only checking the flags/fields not the attributes)
* Better handling and querying of fields

# Integrations

## Rails

* Form Helpers - something to help with checkbox/select/radio helpers

## ActiveModel (ActiveRecord/Mongoid)

* Validators

