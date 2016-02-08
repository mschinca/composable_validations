# Composable Validations

Gem for validating complex JSON payloads.

## Features
* allows composition of generic validators into readable and reusable
  validation rules ([Composability](#composability))
* returned errors always contain exact path of the invalid payload element
  ([Path to invalid element](#path-to-an-invalid-element))
* easy to extend with new validators ([Custom validators](#custom-validators))
* overridable error messages ([Overriding error messages](#overriding-error-messages))

## Requirements

* Ruby 2+
* A tolerance to parantheses... the validator code has rather "lispy" functional look and feel

## Install

```
gem install composable_validations
```

## Quick guide

This gem allows you to build a validator - how/when you call this validation is up to you.

### Basic example

Say we want to validate a payload that specifies a person with name and age. E.g. `{"person" => {"name"
=> "Bob", "age" => 28}}`

```ruby
require 'composable_validations'

include ComposableValidations

# building validator function
validator = a_hash(
  allowed_keys("person"),
  key("person", a_hash(
    allowed_keys("name", "age"),
    key("name", non_empty_string),
    key("age", non_negative_integer))))

# invalid payload with non-integer age
payload = {
  "person" => {
    "name" => 123,
    "age" => "mistake!"
  }
}

# container for error messages
errors = {}

# application of the validator to the payload with default error messages
valid = default_errors(validator).call(payload, errors)

if valid
  puts "payload is valid"
else
  # examine error messages collected by validator
  puts errors.inspect
end
```
In the example above the payload is invalid and as a result `valid` has value
`false` and `errors` contains:
```
{"person/name"=>["must be a string"], "person/age"=>["must be an integer"]}
```
Note that invalid elements of the payload are identified by exact path within
the payload.

### Sinatra app

When using this gem in your application code you would only include
`ComposableValidations` module in classes responsible for validation.

Extending previous example into Sinatra app:

```ruby
require 'sinatra'
require 'json'
require 'composable_validations'

post '/' do
  payload = JSON.parse(request.body.read)
  validator = PersonValidator.new(payload)

  if validator.valid?
    status(204)
  else
    status(422)
    validator.errors.to_json
  end
end

class PersonValidator
  include ComposableValidations
  attr_reader :errors

  def initialize(payload)
    @payload = payload
    @errors = {}

    @validator = a_hash(
      allowed_keys("person"),
      key("person", a_hash(
        allowed_keys("name", "age"),
        key("name", non_empty_string),
        key("age", non_negative_integer))))
  end

  def valid?
    default_errors(@validator).call(@payload, @errors)
  end
end
```

### Arrays

The previous examples showed validation of a JSON object. We can also
validate JSON arrays. Let's add list of hobbies to our person object from
the previous examples:
```ruby
{
  "person" => {
    "name" => "Bob",
    "age" => 28,
    "hobbies" => ["knitting", "horse riding"]
  }
}
```
We will also not accept people with fewer than two hobbies. Validator for this
payload:
```ruby
a_hash(
  allowed_keys("person"),
  key("person", a_hash(
    allowed_keys("name", "age", "hobbies"),
    key("name", non_empty_string),
    key("age", non_negative_integer),
    key("hobbies", array(
      min_size(2),
      each(non_empty_string))))))
```

### Dependent validations

Sometimes we need to ensure that elements of the payload are in certain
relation.

We can ensure simple relations between keys using validators
`key_greater_than_key`, `key_less_than_key` etc. Check out
[Composability](#composability) for example of simple relation between keys.

### Uniqueness

For uniqueness validation follow the example in [Custom
validators](#custom-validators).

## Key concepts

### Validators

Validator is a function returning boolean value and having following signature:
```ruby
lambda { |validated_object, errors_hash, path| ... }
```
* `errors_hash` is mutated while errors are collected by validators.
* `path` represents a path to the invalid element within the JSON object. It is
  an array of strings (keys in hash map) and integers (indexes of an array).
  E.g.  if validated payload is `{"numbers" => [1, 2, "abc", 4]}`, path to
  invalid element "abc" is `["numbers", 2]`.

This gem comes with basic validators like `a_hash`, `array`, `string`,
`integer`, `float`, `date_string`, etc. You can find complete list of
validators [below](#api). Adding new validators is explained in ([Custom
validators](#custom-validators)).

### Combinators

Validators can be composed using two combinators:

* `run_all(*validators)` - applies all validators collecting errors from all of
them and returning false if any of the validators returns false. Useful when
collecting errors of independent validators e.g. fields of the hash.

* `fail_fast(*validators)` - applies validators returning false on first failing
validator. Useful when using validators depending on some preconditions. For
example when checking that a value is non negative, you want to ensure first
that it is a number: `fail_fast(float, non_negative)`.

Return values of above combinators are themselves validators. This way they can
be further composed into more powerful validation rules.

### Composability

We want to validate object representing opening hours of a store. E.g. store
opened from 9am to 5pm would be represented by
```ruby
{"from" => 9, "to" => 17}
```
Let's start by building validator ensuring that payload is a hash where both
`from` and `to` are integers:
```ruby
a_hash(
  key("from", integer),
  key("to", integer))
```
We also want to make sure that extra keys like
```ruby
{"from" => 9, "to" => 17, "something" => "wrong"}
```
are not allowed. Let's fix it by using `allowed_keys` validator:
```ruby
a_hash(
  allowed_keys("from", "to"),
  key("from", integer),
  key("to", integer))
```
Better, but we don't want to allow negative hours like this:
```ruby
{"from" => -1, "to" => 17}
```
We can fix it by using more specific integer validator:
```ruby
a_hash(
  allowed_keys("from", "to"),
  key("from", non_negative_integer),
  key("to", non_negative_integer))
```
Let's assume here that we represent store opened all day as
```ruby
{"from" => 0, "to" => 24}
```
so hours greater than 24 should also be invalid. We can validate hour by
composing `non_negative_integer` validator with `less_or_equal` using
`fail_fast` combinator:
```ruby
hour = fail_fast(non_negative_integer, less_or_equal(24))

a_hash(
  allowed_keys("from", "to"),
  key("from", hour),
  key("to", hour))
```
This validator still has a little problem. Opening hours like this are not
rejected:
```ruby
{"from" => 21, "to" => 1}
```
We have to make sure that closing is not before opening. We can do it by using
`key_greater_than_key` validator:
```ruby
key_greater_than_key("to", "from")
```
and our validator will look like this:
```ruby
a_hash(
  allowed_keys("from", "to"),
  key("from", hour),
  key("to", hour),
  key_greater_than_key("to", "from"))
```
That looks good, but it's not complete yet. `a_hash` validator applies all
validators to the provided payload by using `run_all` combinator. This
behaviour is problematic if our `from` or `to` keys are missing or are not
valid integers. Payload
```ruby
{"from" => "abc", "to" => 17}
```
will cause an exception as `key_greater_than_key` can not compare string to
integer. Let's fix it by using `fail_fast` and `run_all` combinators:
```ruby
a_hash(
  allowed_keys("from", "to"),
  fail_fast(
    run_all(
      key("from", hour),
      key("to", hour)),
    key_greater_than_key("to", "from")))
```
This way if `from` and `to` are not both valid hours we will not be comparing
them.

You can see this validator reused in a bigger example
[below](#path-to-an-invalid-element).

## Path to an invalid element

Validation errors on deeply nested JSON structure will always contain exact
path to the invalid element.

### Example

Let's say we validate stores. Example of store object:

```ruby
store = {
  "store" => {
    "name"        => "Scrutton Street",
    "description" => "large store",
    "opening_hours" => {
      "monday"   => {"from" =>  9, "to" => 17},
      "tuesday"  => {"from" =>  9, "to" => 17},
      "wednesday"=> {"from" =>  9, "to" => 17},
      "thursday" => {"from" =>  9, "to" => 17},
      "friday"   => {"from" =>  9, "to" => 17},
      "saturday" => {"from" => 10, "to" => 16}
    },
    "employees"=> ["bob", "alice"]
  }
}
```

Definition of the store validator (using `from_to` built in the [previous section](#composability)):
```ruby
hour = fail_fast(non_negative_integer, less_or_equal(24))

from_to = a_hash(
  allowed_keys("from", "to"),
  fail_fast(
    run_all(
      key("from", hour),
      key("to", hour)),
    key_greater_than_key("to", "from")))

store_validator = a_hash(
  allowed_keys("store"),
  key("store",
    a_hash(
      allowed_keys("name", "description", "opening_hours", "employees"),
      key("name", non_empty_string),
      optional_key("description"),
      key("opening_hours",
        a_hash(
          allowed_keys("monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"),
          optional_key("monday",    from_to),
          optional_key("tuesday",   from_to),
          optional_key("wednesday", from_to),
          optional_key("thursday",  from_to),
          optional_key("friday",    from_to),
          optional_key("saturday",  from_to),
          optional_key("sunday",    from_to))),
      key("employees", array(each(non_empty_string))))))
```

Let's say we try to validate store that has Wednesday opening hours invalid
(closing time before opening time) like this:
```ruby
...
"wednesday"=> {"from" => 9, "to" => 7},
...
```
Now we use store validator to fill in the collection of errors using default
error messages:
```ruby
  errors = {}
  result = default_errors(store_validator).call(store, errors)
```
Result is `false` and we get validation error in the `errors` hash:
```ruby
{"store/opening_hours/wednesday/to" => ["must be greater than from"]}
```
You can find this example in
[functional spec](https://github.com/shutl/composable_validations/blob/master/spec/functional/composable_validations_spec.rb)
ready for experiments.

## Overriding error messages

This gem comes with set of [default error
messages](https://github.com/shutl/composable_validations/blob/master/lib/composable_validations/default_error_messages.rb).
There are few ways to provide your own error messages.

### Local override

You can override error message when building your validator:
```ruby
a_hash(
  key("from", integer("custom error message")),
  key("to", integer("another custom error message")))
```
This approach is good if you need just few specialized error messages for
different parts of your payload.

### Global override

If you need to change some of the error messages across all your validators you
can provide map of error messages. Keys in the map are symbols matching names
of basic validators:
```ruby
  error_overrides = {
    string:  "not a string",
    integer: "not an integer"
  }

  errors = {}
  errors_container = ComposableValidations::Errors.new(errors, error_overrides)
  result = validator.call(valid_data, errors_container, nil)
```
Note that your error messages don't need to be strings. You could for example
use rendering function that returns combination of error code, error context
and human readable message:
```ruby
 error_overrides = {
    key_greater_than_key: lambda do |validated_object, path, key1, key2|
      {
        code: 123,
        context: [key1, key2],
        message: "#{key1}=#{object[key1]} is not less than or equal to #{key2}=#{object[key2]}"
      }
    end
  }

  errors = {}
  errors_container = ComposableValidations::Errors.new(errors, error_overrides)
  result = validator.call(valid_data, errors_container, nil)
```
And when applied to invalid payload your validator will return an error:
```ruby
  {
    "store/opening_hours/wednesday/to"=>
      [
        {
          :code=>123,
          :context=>["to", "from"],
          :message=>"to=17 is not less than or equal to from=24"
        }
      ]
  }
```
You can experiment with this example in the [specs](https://github.com/shutl/composable_validations/blob/master/spec/functional/error_overrides_spec.rb#L19).

### Override error container

You can override error container class and provide any error collecting
behaviour you need. The only method error container must provide is:
```ruby
def add(msg, path, object)
```
where
* `msg` is a symbol of an error or an array where first element is a symbol of
error and remaining elements are context needed to render the error message.
* `path` represents a path to the invalid element within the JSON object. It is
  an array of strings (keys in hash map) and integers (indexes in array).
* `object` is a validated object.

Example of error container that just collects error paths:
```ruby
class CollectPaths
  attr_reader :paths

  def initialize
    @paths = []
  end

  def add(msg, path, object)
    @paths << path
  end
end

validator = ...
errors_container = CollectPaths.new
result = validator.call(valid_data, errors_container, nil)
```
and example of the value of `errors_container.paths` after getting an error:
```ruby
[["store", "opening_hours", "wednesday", "to"]]
```
You can experiment with this example in the [spec](https://github.com/shutl/composable_validations/blob/master/spec/functional/error_overrides_spec.rb#L80).

## Custom validators

You can create your own validators as functions returning lambdas with signature
```ruby
lambda { |validated_object, errors_hash, path| ... }
```
Use `error` helper function to add errors to the error container and
functions `validate`, `precheck` and `nil_or` to avoid boilerplate.

### Example

Let's say we have an ActiveRecord model Store and API allowing update of the
store name. We will be receiving payload:
```ruby
{ name: 'new store name' }
```
We can build validator ensuring uniqueness of the store name:
```ruby
a_hash(
  allowed_keys('name'),
  key('name',
    non_empty_string,
    unique_store_name))
```
where `unique_store_name` is defined as:
```ruby
def unique_store_name
  lambda do |store_name, errors, path|
    if !Store.exists?(name: store_name)
      true
    else
      error(errors, "has already been taken", store_name, path)
    end
  end
end
```
Note that we could simplify this code by using `validate` helper method:
```ruby
def unique_store_name
  validate("has already been taken") do |store_name|
    !Store.exists?(name: store_name)
  end
end
```
We could also generalize this function and end up with generic ActiveModel
attribute uniqueness validator ready to be reused:
```ruby
def unique(klass, attr_name)
  validate("has already been taken") do |attr_value|
    !klass.exists?(attr_name => attr_value)
  end
end

a_hash(
  allowed_keys('name'),
  key('name',
    non_empty_string,
    unique(Store, :name)))
```

## API

* `a_hash(*validators)` - ensures that the validated object is a hash and then
  applies all `validators` in sequence using `run_all` combinator.

* `allowed_keys(*allowed_keys)` - ensures that validated hash has only keys
  provided as arguments.

* `array(*validators)` - ensures that the validated object is an array and then
  applies all `validators` in sequence using `run_all` combinator.

* `at_least_one_of(*keys)` - ensures that the validated hash has at least one
  of the keys provided as arguments.

* `boolean` - ensures that validated object is `true` or `false`.

* `date_string(format = /\A\d\d\d\d-\d\d-\d\d\Z/, msg = [:date_string,
  'YYYY-MM-DD'])` - ensures that validated object is a string in a given
  format and is parsable by `Date#parse`.

* `default_errors(validator)` - helper function binding validator to the
  default implementation of the error collection object. Returned function is
  not a composable validator so it should only be applied to the top level
  validator right before applying it to the object. Example:
  ```ruby
  errors = {}
  default_errors(validator).call(validated_object, errors)
  ```

* `each_in_slice(range, validator)` - applies `validator` to each slice of the array. Example:
  ```ruby
  array(
    each_in_slice(0..-2, normal_element_validator),
    each_in_slice(-1..-1, special_last_element_validator))
  ```

* `each(validator)` - applies `validator` to each element of the array.

* `equal(val, msg = [:equal, val])` - ensures that validated object is equal
  `val`.

* `error(errors, msg, object, *segments)` - adds error message `msg` to the
  error collection `errors` under path `segments`. Use it in your custom
  validators.

* `exact_size(n, msg = [:exact_size, n])` - ensures that validated object has
  size of exactly `n`. Can be applied only to objects responding to the method
  `#size`.

* `fail_fast(*validators)` - executes `validators` in sequence until one
  of the validators returns `false` or all of them were executed.

* `float(msg = :float)` - ensures that validated object is a number (parsable
  as `Float` or `Fixnum`).

* `format(regex, msg = :format)` - ensures that validated string conforms to
  the regular expression provided.

* `greater_or_equal(val, msg = [:greater_or_equal, val])` - ensures that
  validated object is greater or equal than `val`.

* `greater(val, msg = [:greater, val])` - ensures that validated object is
  greater than `val`.

* `guarded_parsing(format, msg, &blk)` - ensures that validated object is a
  string of a given format and that it can be parsed by provided block (block
  does not raise `ArgumentError` or `TypeError`).

* `inclusion(options, msg = [:inclusion,  options])` - ensures that validated
  object is one of the provided `options`.

* `in_range(range, msg = [:in_range, range])` - ensures that validated object is
  in given `range`.

* `integer(msg = :integer)` - ensures that validated object is an integer
  (parsable as `Fixnum`).

* `just_array(msg = :just_array)` - ensures that validated object is of type
  `Array`.

* `just_hash(msg = :just_hash)` - ensures that validated object is of type
  `Hash`.

* `key_equal_to_key(key1, key2, msg = [:key_equal_to_key, key1, key2])` -
  ensures that validated hash has equal values under keys `key1` and `key2`. If
  any of the values are nil validator returns true.

* `key_greater_or_equal_to_key(key1, key2, msg = [:key_greater_or_equal_to_key,
  key1, key2])` - ensures that validated hash has values under keys `key1` and
  `key2` in relation `h[key1] >= h[key2]`. If any of the values are nil
  validator returns true.

* `key_greater_than_key(key1, key2, msg = [:key_greater_than_key, key1, key2])`- 
    ensures that validated hash has values under keys `key1` and `key2` in
    relation `h[key1] > h[key2]`. If any of the values are nil validator
    returns true.

* `key(key, *validators)` - ensures presence of the key in the validated hash
  and applies validators to the value under the `key` using `run_all`
  combinator.

* `key_less_or_equal_to_key(key1, key2, msg = [:key_less_or_equal_to_key, key1, key2])`- 
    ensures that validated hash has values under keys `key1` and `key2` in
    relation `h[key1] <= h[key2]`. If any of the values are nil validator
    returns true.

* `key_less_than_key(key1, key2, msg = [:key_less_than_key, key1, key2])`- 
    ensures that validated hash has values under keys `key1` and `key2` in
    relation `h[key1] < h[key2]`. If any of the values are nil validator
    returns true.

* `less_or_equal(val, msg = [:less_or_equal, val])` - ensures that
  validated object is less or equal than `val`.

* `less(val, msg = [:less, val])` - ensures that validated object is less than
  `val`.

* `max_size(n, msg = [:max_size, n])` - ensures that validated object has size
  not greater than `n`. Can be applied only to objects responding to the method
  `#size`.

* `min_size(n, msg = [:min_size, n])` - ensures that validated object has size
  not less than `n`. Can be applied only to objects responding to the method
  `#size`.

* `nil_or(*validators)` - helper function returning validator that returns true
  if validated object is `nil` or applies all `validators` using `run_all`
  combinator if validated object is not `nil`.

* `non_empty(msg = :non_empty)` - ensures that validated object is not empty.

* `non_empty_string(msg = :non_empty_string)` - ensures that validated object
  is a non-empty string.

* `non_negative_float` - ensures that validated object is a non-negative number.

* `non_negative_integer` - ensures that validated object is a non-negative
  integer.

* `non_negative(msg = :non_negative)` - ensures that validated object is not
  negative.

* `non_negative_stringy_float` - ensures that validated object is a
  non-negative number or string that can be parsed into non-negative number.
  Example: both 0.1 and "0.1" are valid.

* `non_negative_stringy_integer` - ensures that validated object is a
  non-negative integer or string that can be parsed into non-negative integer.
  Example: both 1 and "1" are valid.

* `optional_key(key, *validators)` - applies `validators` to the value under
  the `key` using `run_all` combinator. Returns `true` if `key` does not exist
  in the validated hash.

* `precheck(*validators, &blk)` - helper function returning validator that
  returns `true` if `&blk` returns `true` or applies all `validators` using
  `run_all` combinator if `&blk` returns `false`. Example - validate that value
  is a number but also allow value "infinity":
  ```ruby
  precheck(float) { |v| v == 'infinity' }
  ```

* `presence_of_key(key, msg = :presence_of_key)` - ensures that validated hash
  has `key`.

* `run_all(*validators)` - executes all `validators` in sequence collecting all
  error messages.

* `size_range(range, msg = [:size_range, range])` - ensures that validated
  object has size `n` in range `range`. Can be applied only to objects
  responding to the method `#size`.

* `string(msg = :string)` - ensures that validated object is of class `String`.

* `stringy_float(msg = :stringy_float)` - ensures that validated object is a
  number or string that can be parsed into number. Example: both 0.1 and "0.1"
  are valid.

* `stringy_integer(msg = :stringy_integer)` - ensures that validated object is
  an integer or string that can be parsed into integer. Example: both 1 and
  "1" are valid.

* `time_string(format = //, msg = :time_string)` - ensures that validated
  object is a string in a given format and is parsable by `Time#parse`.

* `validate(msg, key = nil, &blk)` - helper method returning validator that
  returns `true` if `&blk` returns `true` and `false` otherwise. `msg` is an
  error message added to the error container when validation returns `false`.
  Example - ensure that validated object is equal "hello":
  ```ruby
  validate('must be "hello"') { |v| v == 'hello' }
  ```
