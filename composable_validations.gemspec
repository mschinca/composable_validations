require_relative 'lib/composable_validations/version'

Gem::Specification.new do |s|
  s.version       = ComposableValidations::VERSION
  s.name          = 'composable_validations'
  s.summary       = "Gem for validating complex JSON payloads"
  s.description   = "Gem for validating complex JSON payloads in a functional way"
  s.authors       = ["Kajetan Bojko"]
  s.email         = 'kai@shutl.com'
  s.files         = Dir.glob("lib/**/*") + %w(LICENSE README.md)
  s.require_paths = [".", "lib"]
  s.homepage      = "https://github.com/shutl/composable_validations"
  s.license       = "MIT"
  s.required_ruby_version = '>= 2'

  s.add_development_dependency 'rspec', '~> 3'
end
