require 'composable_validations.rb'
require_relative 'basic_setup'

describe 'basic functionality' do
  include ComposableValidations

  include_context 'basic setup'

  it 'has no errors on valid payload' do
    errors = {}
    result = default_errors(validator).call(valid_data, errors)

    expect(result).to eq true
    expect(errors).to eq({})
  end

  it 'validates opening hours' do
    valid_data["store"]["opening_hours"]["wednesday"]["from"] = 24
    errors = {}
    result = default_errors(validator).call(valid_data, errors)

    expect(result).to eq false
    expect(errors.to_hash).to eq(
      "store/opening_hours/wednesday/to"=>["must be greater than from"])
  end
end
