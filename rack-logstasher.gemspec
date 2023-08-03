lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rack/logstasher/version"

Gem::Specification.new do |spec|
  spec.name          = "rack-logstasher"
  spec.version       = Rack::Logstasher::VERSION
  spec.authors       = ["GOV.UK Dev"]
  spec.email         = ["govuk-dev@digital.cabinet-office.gov.uk"]
  spec.description   = "Rack middleware to log requests in logstash json event format.  Like the logstasher gem, but for rack apps."
  spec.summary       = "Rack middleware to log requests in logstash json event format"
  spec.homepage      = "https://github.com/alphagov/rack-logstasher"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.0"

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w[lib]

  spec.add_dependency "logstash-event", "~> 1.2"
  spec.add_dependency "rack", ">= 2", "< 4"

  spec.add_development_dependency "rack-test", "~> 2"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3"
  spec.add_development_dependency "rubocop-govuk", "4.12.0"
end
