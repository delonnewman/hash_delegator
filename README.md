# HashDelegator

Provides delegation and basic validation to hashes.

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

person.merge!(favorite_food: "Thai") # => NoMethodError
person.merge(favorite_food: "Thai") # => { first_name: "Mary", last_name: "Lamb", age: 32 }
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

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
