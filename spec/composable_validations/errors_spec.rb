require 'composable_validations.rb'

describe ComposableValidations::Errors do
  include ComposableValidations

  let(:errors) { described_class.new({}) }

  context 'when message found' do
    it 'renders message' do
      errors.add(:string, ['abc'], 'validated object')
      expect(errors.to_hash).to eq(
        'abc' => ['must be a string'])
    end

    it 'renders message with context when found' do
      errors.add([:greater, 123], ['abc'], 'validated object')
      expect(errors.to_hash).to eq(
        'abc' => ['must be greater than 123'])
    end
  end

  it 'adds given symbol when message not found' do
    errors.add(:hello, ['abc'], 'validated object')
    expect(errors.to_hash).to eq('abc' => [:hello])
  end

  it 'adds given symbol with context when message not found' do
    errors.add([:hello, 123], ['abc'], 'validated object')
    expect(errors.to_hash).to eq('abc' => [[:hello, 123]])
  end

  it 'adds just plain string message' do
    errors.add('error message', ['abc'], 'validated object')
    expect(errors.to_hash).to eq('abc' => ['error message'])
  end

  it 'adds more than one error correctly' do
    errors.add('error 1', ['abc'], 'validated object')
    errors.add('error 2', ['abc'], 'validated object')
    expect(errors.to_hash).to eq('abc' => ['error 1', 'error 2'])
  end

  it 'does not duplicate error messages' do
    errors.add('error', ['abc'], 'validated object')
    errors.add('error', ['abc'], 'validated object')
    expect(errors.to_hash).to eq('abc' => ['error'])
  end

  context 'with error overrides' do
    it 'allows overriding original lambda with static string' do
      errors = described_class.new({}, less: 'some custom message')
      errors.add(:less, ['abc'], 'validated object')
      expect(errors.to_hash).to eq(
        'abc' => ['some custom message'])
    end

    it 'gives access to full context' do
      overrides = {
        less: lambda do |validated_object, path, val|
          "#{validated_object} at #{path.join('/')} is not less than #{val}"
        end
      }

      errors = described_class.new({}, overrides)
      errors.add([:less, 'value'], ['abc'], 'object')
      expect(errors.to_hash).to eq(
        'abc' => ['object at abc is not less than value'])
    end
  end

  describe 'error message of inclusion validator' do
    let(:message_builder) { described_class::DEFAULT_MESSAGE_MAP[:inclusion] }

    specify 'with short list of options' do
      options = (1..10).map(&:to_s)
      message = message_builder.call('object', 'path', options)

      expect(message).to eq("must be one of: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10")
    end

    specify 'with short list of options' do
      options = (1..11).map(&:to_s)
      message = message_builder.call('object', 'path', options)

      expect(message).to eq("is not allowed")
    end
  end
end
