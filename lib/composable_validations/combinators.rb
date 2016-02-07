module ComposableValidations; end

module ComposableValidations::Combinators
  def run_all(*validators)
    lambda do |object, errors, prefix|
      validators.inject(true) do |acc, validator|
        r = validator.call(object, errors, prefix)
        acc && r
      end
    end
  end

  def fail_fast(*validators)
    lambda do |object, errors, prefix|
      validators.each do |validator|
        return false if !validator.call(object, errors, prefix)
      end
      true
    end
  end

  def nil_or(*validators)
    precheck(*validators, &:nil?)
  end

  def precheck(*validators, &blk)
    lambda do |object, errors, prefix|
      return true if yield(object)
      run_all(*validators).call(object, errors, prefix)
    end
  end
end