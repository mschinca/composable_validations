require 'composable_validations'
require 'spec/composable_validations_helper'

describe ComposableValidations do
  extend ComposableValidations
  extend ComposableValidationsHelper

  describe '#run_all' do
    valid('run_all', ['anything'])
    valid('run_all(success)', ['anything'])

    invalid('run_all(failure)', ['anything'], {'dummy' => ['failure']})
    invalid(
      'run_all(failure, success, another_failure)',
      ['anything'],
      {'dummy' => ['failure', 'another failure']})
  end

  describe '#fail_fast' do
    valid('fail_fast', ['anything'])
    valid('fail_fast(success)', ['anything'])

    invalid('fail_fast(failure)', ['anything'], {'dummy' => ['failure']})
    invalid(
      'fail_fast(failure, another_failure)',
      ['anything'],
      {'dummy' => ['failure']})
  end

  describe '#nil_or' do
    valid('nil_or(success)', ["anything", nil, {}])
    valid('nil_or(failure)', [nil])

    invalid('nil_or(failure)', ["anything"], {'dummy' => ["failure"]})
  end

  describe '#precheck' do
    valid('precheck(failure) { true }', ['anything'])
    valid('precheck(success) { true }', ['anything'])
    valid('precheck(success) { false }', ['anything'])

    invalid(
      'precheck(failure) { false }',
      ['anything'],
      {'dummy' => ['failure']})
  end
end
