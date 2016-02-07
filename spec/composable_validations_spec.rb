require 'composable_validations'
require 'spec/composable_validations_helper'

describe ComposableValidations do
  extend ComposableValidations
  extend ComposableValidationsHelper

  describe '#success' do
    valid('success', ['anything'])
  end

  describe '#failure' do
    invalid('failure', ['anything'], {'dummy' => ['failure']})
  end

  describe '#just_types' do
    valid('just_types("error message", String, Integer)', ['a', 3])

    invalid(
      'just_types("error message", String, Integer)',
      [nil, 1.3, [], {}],
      {'base' => ['error message']})
  end

  describe '#just_type' do
    valid('just_type(Exception, "must be an exception")', [Exception.new])

    invalid(
      'just_type(Exception, "must be an exception")',
      [nil, 'a', 1, []],
      {'base' => ['must be an exception']})
  end

  describe '#just_hash' do
    valid('just_hash', [{}])

    invalid('just_hash', [nil, 'a', 1, []], {'base' => ['must be a hash']})
  end

  describe '#just_array' do
    valid('just_array', [[]])

    invalid('just_array', [nil, 'a', 1, {}], {'base' => ['must be an array']})
  end

  describe '#a_hash' do
    valid('a_hash(success)', [{}])

    invalid('a_hash(failure)', [{}], {'dummy' => ['failure']})
    invalid('a_hash(success, failure)', [{}], {'dummy' => ['failure']})
    invalid('a_hash(failure)', [{}], {'hello/dummy' => ['failure']}, 'hello')
  end

  describe '#array' do
    valid('array(success)', [[]])

    invalid('array(failure)', [['a']], {'dummy' => ['failure']})
    invalid('array(each(string))', [[1]], {'0' => ['must be a string']})
    invalid('array(success, failure)', [['a']], {'dummy' => ['failure']})
    invalid('array(failure)', [['a']], {'hello/dummy' => ['failure']}, 'hello')
    invalid('array(each(failure))', [['a']], {'hello/0/dummy' => ['failure']}, 'hello')
  end

  describe '#each' do
    valid('each(success)', [[], ['a'], ['a', 'b']])
    valid('each(failure)', [[]])

    invalid('each(failure)', [['a']], {'0/dummy' => ['failure']})
    invalid(
      'each(failure)',
      [['a', 'b']],
      {
        '0/dummy' => ['failure'],
        '1/dummy' => ['failure'],
      })
  end

  describe '#each_in_slice' do
    valid('each_in_slice(0..-1, success)', [[]])
    valid('each_in_slice(0..-1, failure)', [[]])
    valid('each_in_slice(0..-2, success)', [['a']])
    valid('each_in_slice(0..-2, failure)', [['a']])
    valid('each_in_slice(-1..-1, success)', [['a']])
    valid('each_in_slice(-1..-1, string)', [[0, 'a']])

    invalid('each_in_slice(-1..-1, failure)', [['a']], {'hello/0/dummy' => ['failure']}, 'hello')
    invalid('each_in_slice(-1..-1, string)', [[0, 1]], {'hello/1' => ['must be a string']}, 'hello')
  end

  describe '#allowed_keys' do
    valid('allowed_keys', [{}])
    valid('allowed_keys("a")', [{'a' => 'b'}])

    invalid('allowed_keys("a")', [{'b' => 'c'}], {'hello/b' => ['is not allowed']}, 'hello')
  end

  describe '#presence_of_key' do
    valid('presence_of_key("a")', [{'a' => 'b'}])
    invalid('presence_of_key("a")', [{}], {'a' => ["can't be blank"]})
  end

  describe '#key' do
    valid('key("a")', [{'a' => 'b'}])
    valid('key("a", success)', [{'a' => 'b'}])

    invalid('key("a")', [{}], {'hello/a' => ["can't be blank"]}, 'hello')
    invalid('key("a", failure)', [{'a' => 'b'}], {'hello/a/dummy' => ["failure"]}, 'hello')
  end

  describe '#optional_key' do
    valid('optional_key("a")', [{}, {'a' => 'b'}])
    valid('optional_key("a", success)', [{'b' => 'c'}, {'a' => 'b'}])
    valid('optional_key("a", failure)', [{'b' => 'c'}, {}])

    invalid('optional_key("a", failure)', [{'a' => 'b'}], {'hello/a/dummy' => ["failure"]}, 'hello')

    invalid('optional_key("a", a_hash)', [{'a' => 'b'}], {'a' => ['must be a hash']})
  end

  describe '#parsing' do
    valid('parsing("failure") {|v|}', ['anything'])
    invalid('parsing("failure") {|v| raise ArgumentError}', ['anything'], {'base' => ['failure']})
    invalid('parsing("failure") {|v| raise TypeError}', ['anything'], {'base' => ['failure']})
    exception(
      'parsing("failure") {|v| raise Exception}',
      ['anything'])
  end

  describe '#string' do
    valid('string', ['', 'hello'])
    invalid('string', [nil, 3.14, {}, []], {'base' => ['must be a string']})
  end

  describe '#integer' do
    valid('integer', [0, 1, -1])
    invalid('integer', [nil, 3.14, '-1', '3.14', {}, []], {'hello' => ['must be an integer']}, 'hello')
  end

  describe '#non_negative_integer' do
    valid('non_negative_integer', [0, 1, 3])
    invalid('non_negative_integer', ['a', '3', [], {}], {'hello' => ['must be an integer']}, 'hello')
    invalid('non_negative_integer', [-1, -3], {'hello' => ['must be greater than or equal to 0']}, 'hello')
  end

  describe '#stringy_integer' do
    valid('stringy_integer', [0, 1, -1, '-1'])
    invalid('stringy_integer', [nil, 3.14, '3.14', {}, []], {'hello' => ['must be an integer']}, 'hello')
  end

  describe '#non_negative_stringy_integer' do
    valid('non_negative_stringy_integer', [0, 1])
    invalid('non_negative_stringy_integer', [-1, '-1'], {'hello' => ["must be greater than or equal to 0"]}, 'hello')
    invalid('non_negative_stringy_integer', [nil, 3.14, '3.14', {}, []], {'hello' => ['must be an integer']}, 'hello')
  end

  describe '#float' do
    valid('float', [0, 1, -1, 3.14])
    invalid('float', [nil, '-1', '3.14', {}, []], {'hello' => ['must be a number']}, 'hello')
  end

  describe '#non_negative_float' do
    valid('non_negative_float', [0, 1, 3.14])
    invalid('non_negative_float', ['a', '3.14', [], {}], {'hello' => ['must be a number']}, 'hello')
    invalid('non_negative_float', [-1, -3.14], {'hello' => ['must be greater than or equal to 0']}, 'hello')
  end

  describe '#non_negative_stringy_float' do
    valid('non_negative_stringy_float', [0, 1, '3.14', 3.14])
    invalid('non_negative_stringy_float', ['a', [], {}], {'hello' => ['must be a number']}, 'hello')
    invalid('non_negative_stringy_float', [-1, '-3.14', -3.14], {'hello' => ['must be greater than or equal to 0']}, 'hello')
  end

  describe '#stringy_float' do
    valid('stringy_float', [0, 1, -1, '-1', 3.14, '3.14'])
    invalid('stringy_float', [nil, {}, []], {'hello' => ['must be a number']}, 'hello')
  end

  describe '#non_negative' do
    valid('non_negative', [0, 1, 3.14, '3'])
    invalid('non_negative', [-1, '-1', -3.14, '-3'], {'hello' => ['must be greater than or equal to 0']}, 'hello')
  end

  describe '#non_empty' do
    valid('non_empty', [['a'], {'a' => 'b'}])
    invalid('non_empty', [[], {}, ''], {'hello' => ["can't be empty"]}, 'hello')
  end

  describe '#at_least_one_of' do
    valid('at_least_one_of("a")', [{'a' => 'b'}])
    valid('at_least_one_of("a", "b")', [{'a' => 'b', 'b' => 'c'}])

    invalid('at_least_one_of("a", "b")', [{}], {'hello' => ["at least one of a, b is required"]}, 'hello')
  end

  describe '#inclusion' do
    valid('inclusion(["a"])', ['a'])
    invalid('inclusion(["a", "b"])', ['c'], {'hello' => ["must be one of: a, b"]}, 'hello')
  end

  describe '#boolean' do
    valid('boolean', [true, false])

    invalid('boolean', ['a', 1, {}, nil], {'hello' => ["must be one of: true, false"]}, 'hello')
  end

  describe '#non_empty_string' do
    valid('non_empty_string', ["a"])

    invalid('non_empty_string', ["", " "], {'hello' => ["can't be blank"]}, 'hello')
  end

  describe '#date_string' do
    valid('date_string', ["2015-11-28"])

    invalid(
      'date_string',
      [
        "2015-13-28",
        "2015-11-31",
        "2015/11/28",
        "2015-11-28abc",
        "hello", 1, {}, []
      ],
      {'base' => ['must be a date in format YYYY-MM-DD']})
  end

  describe '#time_string' do
    context 'with default format and message' do
      valid('time_string', [
        "2015-11-28T11:30",
        "2015/11/28 11:30",
        "2015 Nov 28 11:30",
        "2015-11-31",
      ])

      invalid(
        'time_string',
        [
          "2015-11-28T11:30:61",
          "hello", 1, {}, []
        ],
        {'base' => ['must be a time']})
    end

    context 'with format and message overrides' do
      validator_code = 'time_string(/\A\d\d\d\d-\d\d-\d\d \d\d:\d\d\Z/, [:time_string])'
      valid(validator_code, [
        "2015-11-28 11:30",
      ])

      invalid(
        validator_code,
        [
          "2015/11/28 11:30",
          "2015-11-28 11:60",
          "2015-11-28 11:30:00",
          "2015 Nov 28 11:30",
          "hello", 1, {}, []
        ],
        {'base' => ['must be a time']})
    end
  end

  describe '#guarded_parsing' do
    validator_code = 'guarded_parsing(/\A\d\d\Z/, "error message") {|v| Integer(v)}'
    valid(validator_code, ['12'])

    invalid(
      validator_code,
      [ '1', 'a', '018' ],
      {'hello' => ["error message"]}, 'hello')
  end

  describe '#format' do
    validator_code = 'format(/\A\d\d\Z/)'
    valid(validator_code, ['12'])

    invalid(
      validator_code,
      [ '1', 'a', '018' ],
      {'hello' => ["is invalid"]}, 'hello')
  end

  describe '#min_size' do
    valid('min_size(2)', [[1, 2], "12", "123", {a: 1, b: 2}])

    invalid(
      'min_size(2)',
      [[1], "1", {a: 1}],
      {'hello' => ["is too short (minium size is 2)"]}, 'hello')
  end

  describe '#max_size' do
    valid('max_size(2)', [[1, 2], "12", "1", {a: 1, b: 2}])

    invalid(
      'max_size(2)',
      [[1, 2, 3], "123", {a: 1, b: 2, c: 3}],
      {'hello' => ["is too long (maximum size is 2)"]}, 'hello')
  end

  describe '#exact_size' do
    valid('exact_size(2)', [[1, 2], "12", {a: 1, b: 2}])

    invalid(
      'exact_size(2)',
      [[1, 2, 3], "123", "1", {a: 1, b: 2, c: 3}],
      {'hello' => ["is the wrong size (should be 2)"]}, 'hello')
  end

  describe '#size_range' do
    valid('size_range(2..3)', [[1, 2], "12", "123", {a: 1, b: 2}])

    invalid(
      'size_range(2..3)',
      [[1], "1234", {}],
      {'hello' => ["is the wrong size (minimum is 2 and maximum is 3)"]}, 'hello')
  end

  describe '#to_index' do
    include ComposableValidations
    specify { expect(to_index(%w(a b c), 2)).to eql(2) }
    specify { expect(to_index(%w(a b c), -1)).to eql(2) }
    specify { expect(to_index(%w(a b c), -2)).to eql(1) }
  end
end
