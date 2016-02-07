module ComposableValidationsHelper
  def success
    lambda do |o, errors, prefix|
      true
    end
  end

  def failure
    lambda do |o, errors, prefix|
      error(errors, 'failure', o, prefix, 'dummy')
    end
  end

  def another_failure
    lambda do |o, errors, prefix|
      error(errors, 'another failure', o, prefix, 'dummy')
    end
  end

  def exception
    lambda do |o, errors, prefix|
      raise 'boom'
    end
  end

  def valid(validator_code, payloads, prefix = nil)
    validator = eval(validator_code)
    payloads.each do |payload|
      specify "#{validator_code} is valid with #{payload}" do
        errors = ComposableValidations::Errors.new({})
        result = validator.call(payload, errors, prefix)
        expect(result).to be true
        expect(errors.to_hash).to be_empty
      end
    end
  end

  def invalid(validator_code, payloads, expected_errors, prefix = nil)
    validator = eval(validator_code)
    payloads.each do |payload|
      specify "#{validator_code} is invalid with #{payload.inspect} giving errors: #{expected_errors}" do
        errors = ComposableValidations::Errors.new({})
        result = validator.call(payload, errors, prefix)
        expect(result).to be false
        expect(errors.to_hash).to eq(expected_errors)
      end
    end
  end

  def exception(validator_code, payloads, exception = Exception)
    validator = eval(validator_code)
    payloads.each do |payload|
      errors = ComposableValidations::Errors.new({})
      specify "#{validator_code} blows up with #{payload}" do
        expect do
          validator.call(payload, errors, nil)
        end.to raise_error(exception)
      end
    end
  end
end
