require 'composable_validations'
require_relative 'basic_setup'

describe 'overriding error messages' do
  include_context 'basic setup'

  let(:error_overrides) do
    {
      key_greater_than_key: lambda do |object, _, key1, key2|
        {
          code: 123,
          context: [key1, key2],
          message: "#{key1}=#{object[key1]} is not less than or equal to #{key2}=#{object[key2]}"
        }
      end
    }
  end

  describe 'overriding error message by passing overrides to error container' do
    include ComposableValidations

    specify do
      valid_data["store"]["opening_hours"]["wednesday"]["from"] = 24

      errors = {}
      errors_container = ComposableValidations::Errors.new(errors, error_overrides)
      result = validator.call(valid_data, errors_container, nil)

      expect(result).to eq false
      expect(errors).to eq(
        "store/opening_hours/wednesday/to"=>
          [
            {
              :code=>123,
              :context=>["to", "from"],
              :message=>"to=17 is not less than or equal to from=24"
            }
          ]
      )
    end
  end

  describe 'overriding error message by overriding validator method' do
    module CustomValidations
      include ComposableValidations

      def key_greater_than_key(key1, key2)
        msg = {
          code: 123,
          context: [key1, key2],
          message: "'#{key1}' is not less than or equal to '#{key2}'"
        }

        super(key1, key2, msg, &:>)
      end
    end

    include CustomValidations

    specify do
      valid_data["store"]["opening_hours"]["wednesday"]["from"] = 24

      errors = {}
      result = default_errors(validator).call(valid_data, errors)

      expect(result).to eq false
      expect(errors.to_hash).to eq(
        "store/opening_hours/wednesday/to"=>
          [
            {
              :code=>123,
              :context=>["to", "from"],
              :message=>"'to' is not less than or equal to 'from'"
            }
          ]
      )
    end
  end

  describe 'overriding error message by providing custom error container' do
    class CollectPaths
      attr_reader :paths

      def initialize
        @paths = []
      end

      def add(msg, path, object)
        @paths << path
      end
    end

    include CustomValidations

    specify do
      valid_data["store"]["opening_hours"]["wednesday"]["from"] = 24

      errors_container = CollectPaths.new
      result = validator.call(valid_data, errors_container, nil)

      expect(result).to eq false
      expect(errors_container.paths).to eq([["store", "opening_hours", "wednesday", "to"]])
    end
  end
end
