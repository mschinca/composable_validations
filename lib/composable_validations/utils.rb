module ComposableValidations::Utils
  def default_errors(validator)
    lambda do |object, errors_hash|
      errors = ComposableValidations::Errors.new(errors_hash)
      validator.call(object, errors, nil)
    end
  end

  def join(*segments)
    segments.inject([]) do |acc, seg|
      acc + Array(seg)
    end
  end

  def validate(msg, key = nil, &blk)
    lambda do |o, errors, prefix|
      if yield(o)
        true
      else
        error(errors, msg, o, prefix, key)
      end
    end
  end

  def error(errors, msg, object, *segments)
    errors.add(msg, join(*segments), object)
    false
  end
end
