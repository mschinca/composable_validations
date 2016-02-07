require 'date'
require 'time'

require_relative 'composable_validations/version'
require_relative 'composable_validations/combinators'
require_relative 'composable_validations/utils'
require_relative 'composable_validations/comparison'
require_relative 'composable_validations/errors'
require_relative 'composable_validations/default_error_messages'

module ComposableValidations
  include ComposableValidations::Combinators
  include ComposableValidations::Utils
  include ComposableValidations::Comparison

  # it is named with prefix 'a_' to avoid conflict with built in hash method
  def a_hash(*validators)
    fail_fast(just_hash, run_all(*validators))
  end

  def array(*validators)
    fail_fast(
      just_array,
      run_all(*validators))
  end

  def each(validator)
    each_in_slice(0..-1, validator)
  end

  def each_in_slice(range, validator)
    lambda do |a, errors, prefix|
      slice = a.slice(range) || []
      slice.inject([true, 0]) do |(acc, index), elem|
        suffix = to_index(a, range.begin) + index
        b = validator.call(elem, errors, join(prefix, suffix))
        [acc && b, index + 1]
      end.first
    end
  end

  def to_index(array, range_index)
    indexes = array.map.with_index { |_, i| i }
    indexes[range_index]
  end

  def allowed_keys(*allowed_keys)
    lambda do |h, errors, prefix|
      h.keys.inject(true) do |acc, key|
        if !allowed_keys.include?(key)
          error(errors, :allowed_keys, h, prefix, key)
        else
          acc && true
        end
      end
    end
  end

  def key(key, *validators)
    fail_fast(
      presence_of_key(key),
      lambda do |h, errors, prefix|
        run_all(*validators).call(h[key], errors, join(prefix, key))
      end
    )
  end

  def optional_key(key, *validators)
    lambda do |h, errors, prefix|
      if h.has_key?(key)
        key(key, *validators).call(h, errors, prefix)
      else
        true
      end
    end
  end

  def just_hash(msg = :just_hash)
    just_type(Hash, msg)
  end

  def just_array(msg = :just_array)
    just_type(Array, msg)
  end

  def string(msg = :string)
    just_type(String, msg)
  end

  def non_empty_string(msg = :non_empty_string)
    fail_fast(
      string,
      validate(msg) { |s| s.strip != '' })
  end

  def integer(msg = :integer)
    just_type(Fixnum, msg)
  end

  def stringy_integer(msg = :stringy_integer)
    parsing(msg) { |v| Integer(v.to_s) }
  end

  def float(msg = :float)
    just_types(msg, Float, Fixnum)
  end

  def stringy_float(msg = :stringy_float)
    parsing(msg) { |v| Float(v.to_s) }
  end

  def non_negative_float
    fail_fast(float, non_negative)
  end

  def non_negative_integer
    fail_fast(integer, non_negative)
  end

  def non_negative_stringy_float
    fail_fast(stringy_float, non_negative)
  end

  def non_negative_stringy_integer
    fail_fast(stringy_integer, non_negative)
  end

  def non_negative(msg = :non_negative)
    validate(msg) { |v| Float(v.to_s) >= 0 }
  end

  def date_string(format = /\A\d\d\d\d-\d\d-\d\d\Z/, msg = [:date_string, 'YYYY-MM-DD'])
    guarded_parsing(format, msg) { |v| Date.parse(v) }
  end

  def time_string(format = //, msg = :time_string)
    guarded_parsing(format, msg) { |v| Time.parse(v) }
  end

  def format(regex, msg = :format)
    validate(msg) { |val| regex.match(val) }
  end

  def guarded_parsing(format, msg, &blk)
    fail_fast(
      string(msg),
      format(format, msg),
      parsing(msg, &blk))
  end

  def parsing(msg, &blk)
    validate(msg) do |val|
      begin
        yield(val)
        true
      rescue ArgumentError, TypeError
        false
      end
    end
  end

  def just_type(type, msg)
    just_types(msg, type)
  end

  def just_types(msg, *types)
    validate(msg) do |v|
      types.inject(false) do |acc, type|
        acc || v.is_a?(type)
      end
    end
  end

  def boolean
    inclusion([true, false])
  end

  def inclusion(options, msg = [:inclusion,  options])
    validate(msg) { |v| options.include?(v) }
  end

  def presence_of_key(key, msg = :presence_of_key)
    validate(:presence_of_key, key) { |h| h.has_key?(key) }
  end

  def non_empty(msg = :non_empty)
    validate(msg) { |v| !v.empty? }
  end

  def at_least_one_of(*keys)
    validate([:at_least_one_of, keys]) do |h|
      count = h.keys.count { |k| keys.include?(k) }
      count > 0
    end
  end

  def size(validator)
    lambda do |object, errors, path|
      validator.call(object.size, errors, path)
    end
  end

  def min_size(n, msg = [:min_size, n])
    size(greater_or_equal(n, msg))
  end

  def max_size(n, msg = [:max_size, n])
    size(less_or_equal(n, msg))
  end

  def exact_size(n, msg = [:exact_size, n])
    size(equal(n, msg))
  end

  def size_range(range, msg = [:size_range, range])
    size(in_range(range, msg))
  end
end
