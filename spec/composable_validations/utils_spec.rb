require 'composable_validations'
require 'spec/composable_validations_helper'

describe ComposableValidations::Utils do
  describe '#join' do
    include ComposableValidations

    specify { expect(join).to eq([]) }
    specify { expect(join(nil)).to eq([]) }
    specify { expect(join(nil, 'a')).to eq(['a']) }
    specify { expect(join(['a'], nil)).to eq(['a']) }
    specify { expect(join(['a'], ['b'])).to eq(['a', 'b']) }
    specify { expect(join(['a'], 'b')).to eq(['a', 'b']) }
  end

  describe '#validate' do
    extend ComposableValidations
    extend ComposableValidationsHelper

    valid('validate("failure") { true }', ['anything'])

    invalid(
      'validate("failure") { false }',
      ['anything'],
      {'base' => ["failure"]})
  end

  describe '#error' do
    include ComposableValidations

    let(:errors) { ComposableValidations::Errors.new({}) }

    specify { expect(error(errors, 'msg', 'validated object')).to eq(false) }

    specify do
      error(errors, 'msg', 'validated object')
      expect(errors.to_hash).to eq('base' => ['msg'])
    end

    specify do
      error(errors, 'msg', 'validate object', 'path')
      expect(errors.to_hash).to eq('path' => ['msg'])
    end
  end
end
