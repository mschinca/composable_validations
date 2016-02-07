module ComposableValidations::Comparison
  def key_to_key_comparison(key1, key2, msg, &compfun)
    precheck(
      validate(msg, key1) do |h|
        v1 = h[key1]
        v2 = h[key2]
        compfun.call(v1, v2)
      end
    ) do |h|
      h[key1].nil? || h[key2].nil?
    end
  end

  def comparison(val, msg, &compfun)
    validate(msg) do |v|
      compfun.call(v, val)
    end
  end

  def key_greater_or_equal_to_key(key1, key2, msg = [:key_greater_or_equal_to_key, key1, key2])
    key_to_key_comparison(key1, key2, msg, &:>=)
  end

  def key_greater_than_key(key1, key2, msg = [:key_greater_than_key, key1, key2])
    key_to_key_comparison(key1, key2, msg, &:>)
  end

  def key_less_or_equal_to_key(key1, key2, msg = [:key_less_or_equal_to_key, key1, key2])
    key_to_key_comparison(key1, key2, msg, &:<=)
  end

  def key_less_than_key(key1, key2, msg = [:key_less_than_key, key1, key2])
    key_to_key_comparison(key1, key2, msg, &:<)
  end

  def key_equal_to_key(key1, key2, msg = [:key_equal_to_key, key1, key2])
    key_to_key_comparison(key1, key2, msg, &:==)
  end

  def greater_or_equal(val, msg = [:greater_or_equal, val])
    comparison(val, msg, &:>=)
  end

  def greater(val, msg = [:greater, val])
    comparison(val, msg, &:>)
  end

  def less_or_equal(val, msg = [:less_or_equal, val])
    comparison(val, msg, &:<=)
  end

  def less(val, msg = [:less, val])
    comparison(val, msg, &:<)
  end

  def equal(val, msg = [:equal, val])
    comparison(val, msg, &:==)
  end

  def in_range(range, msg = [:in_range, range])
    validate(msg) do |val|
      range.include?(val)
    end
  end
end
