require_relative 'lib/composable_validations/version'

Gem::Specification.new do |s|
  s.version     = ComposableValidations::VERSION
  s.name        = 'composable_validations'
  s.summary     = "composable validations"
  s.description = "composable validations"
  s.authors     = ["Kajetan Bojko"]
  s.email       = 'dev@shutl.co.uk'
  s.files       = Dir.glob("lib/**/*") + %w(LICENSE README.md)
  s.require_paths = [".", "lib"]

  s.add_development_dependency 'rspec', '~> 3'
end
