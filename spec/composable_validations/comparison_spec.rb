require 'composable_validations'
require 'spec/composable_validations_helper'

describe ComposableValidations do
  extend ComposableValidations
  extend ComposableValidationsHelper

  describe '#key_to_key_comparison' do
    validator_code =
      'key_to_key_comparison("a", "b", "not equal", &:>)'
    valid(
      validator_code,
      [
        {'a' => 4, 'b' => 3},
        {'a' => 'hello'},
        {'b' => 'hello'},
        {},
      ])

    invalid(
      validator_code,
      [{'a' => 3, 'b' => 4}],
      {'a' => ["not equal"]})

    exception(
      validator_code,
      [
        {'a' => '4', 'b' => 3},
        {'a' => 4, 'b' => '3'}
      ],
      ArgumentError)
  end

  describe '#comparison' do
    validator_code = 'comparison(3, "not greater", &:>)'

    valid(validator_code, [3.01, 4])

    invalid(
      validator_code,
      [2, 2.99],
      {'base' => ["not greater"]})

    exception(validator_code, [{}], NoMethodError)
    exception(validator_code, ["hello", "4"], ArgumentError)
  end

  describe '#key_greater_or_equal_to_key' do
    validator_code = 'key_greater_or_equal_to_key("a", "b")'
    valid(validator_code, [
      {"a" => 3, "b" => 3},
      {"a" => 4, "b" => 3},
      {"a" => nil, "b" => 3},
      {"a" => 4, "b" => nil},
      {"a" => nil, "b" => '3'},
      {"a" => '4', "b" => nil},
    ])
    invalid(
      validator_code,
      [{"a" => 3, "b" => 4}],
      {'hello/a' => ["must be greater than or equal to b"]}, 'hello')
    exception(
      validator_code, [
      {"a" => '4', "b" => 3},
      {"a" => 4, "b" => '3'}
    ], ArgumentError)
  end

  describe '#key_greater_than_key' do
    validator_code = 'key_greater_than_key("a", "b")'
    valid(validator_code, [{"a" => 3.1, "b" => 3}])
    invalid(validator_code, [
      {"a" => 3, "b" => 3},
      {"a" => 3, "b" => 4},
    ], {'hello/a' => ["must be greater than b"]}, 'hello')
    exception(validator_code, [{"a" => '4', "b" => 3}], ArgumentError)
  end

  describe '#key_less_or_equal_to_key' do
    validator_code = 'key_less_or_equal_to_key("a", "b")'
    valid(validator_code, [
      {"a" => 3, "b" => 3},
      {"a" => 3, "b" => 4}
    ])
    invalid(
      validator_code, [
      {"a" => 4, "b" => 3}],
      {'hello/a' => ["must be less than or equal to b"]},'hello')
    exception(validator_code, [{"a" => '3', "b" => 4}], ArgumentError)
  end

  describe '#key_less_than_key' do
    validator_code = 'key_less_than_key("a", "b")'
    valid(validator_code, [{"a" => 3, "b" => 4}])
    invalid(validator_code, [
      {"a" => 4, "b" => 4},
      {"a" => 4, "b" => 3},
    ], {'hello/a' => ["must be less than b"]}, 'hello')
    exception(validator_code, [{"a" => '3', "b" => 4}], ArgumentError)
  end

  describe '#key_equal_to_key' do
    validator_code = 'key_equal_to_key("a", "b")'
    valid(validator_code, [{"a" => 3, "b" => 3}])
    invalid(validator_code, [
      {"a" => 4, "b" => 3},
      {"a" => '3', "b" => 3}
    ], {'hello/a' => ["must be equal to b"]}, 'hello')
  end

  describe '#greater_or_equal' do
    validator_code = 'greater_or_equal(3)'
    valid(validator_code, [3])
    invalid(validator_code, [2], {'hello' => ["must be greater than or equal to 3"]}, 'hello')
    exception(validator_code, ['4'], ArgumentError)
  end

  describe '#greater' do
    validator_code = 'greater(3)'
    valid(validator_code, [4])
    invalid(validator_code, [3, 2], {'hello' => ["must be greater than 3"]}, 'hello')
    exception(validator_code, ['4'], ArgumentError)
  end

  describe '#less_or_equal' do
    validator_code = 'less_or_equal(3)'
    valid(validator_code, [3, 2])
    invalid(validator_code, [4], {'hello' => ["must be less than or equal to 3"]}, 'hello')
    exception(validator_code, ['2'], ArgumentError)
  end

  describe '#less' do
    validator_code = 'less(3)'
    valid(validator_code, [2])
    invalid(validator_code, [3, 4], {'hello' => ["must be less than 3"]}, 'hello')
    exception(validator_code, ['2'], ArgumentError)
  end

  describe '#equal' do
    validator_code = 'equal(3)'
    valid(validator_code, [3])
    invalid(validator_code, ['3', 2, 4], {'hello' => ["must be equal to 3"]}, 'hello')
  end

  describe '#in_range' do
    validator_code = 'in_range(3..5)'
    valid(validator_code, [3, 4, 5])
    invalid(validator_code, [1, 2, 6, 7], {'hello' => ["must be in range 3..5"]}, 'hello')
  end
end
