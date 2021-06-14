[![Build Status](https://travis-ci.com/delonnewman/hash_delegator.svg?branch=master)](https://travis-ci.com/delonnewman/hash_delegator)

# HashDelegator

Thread-safe immutable objects that provide delegation and basic validation to hashes.

## Synopsis

```ruby
class Person < HashDelegator
  require :first_name, :last_name
  transform_keys(&:to_sym)

  def name
    "#{first_name} #{last_name}"
  end
end

person = Person.new(first_name: "Mary", last_name: "Lamb", age: 32)
person.age # => 32
person.name # => "Mary Lamb"

# it supports all non-mutating methods of Hash
person.merge!(favorite_food: "Thai") # => NoMethodError
person.merge(favorite_food: "Thai") # => #<Person { first_name: "Mary", last_name: "Lamb", age: 32 }>



# respects inheritance
class Employee < Person
  require :employee_id
end

Employee.new(age: 32, employee_id: 1234) # => Error, first_name attribute is required
Employee.new(first_name: "John", last_name: "Smith", age: 23, employee_id: 3456) # => #<Employee ...>
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hash_delegator'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install hash_delegator

## See Also

- [Dry Struct](https://dry-rb.org/gems/dry-struct)
- [Clojure Records](https://clojure.org/reference/datatypes#_deftype_and_defrecord)
- [Delegator](https://rubyapi.org/3.0/o/delegator)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
