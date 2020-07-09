$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "scim_rails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "scim_rails"
  s.version = ScimRails::VERSION
  s.authors = ["Spencer Alan"]
  s.email = ["devops@lessonly.com"]
  s.homepage = "https://github.com/lessonly/scim_rails"
  s.summary = "SCIM Adapter for Rails."
  s.description = "SCIM Adapter for Rails."
  s.license = "MIT"

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.require_paths = ["lib"]
  
  s.required_ruby_version = "~> 2.4"
  s.add_dependency "rails", "~> 5.0"
  s.add_runtime_dependency "jwt", ">= 1.5", "< 3.0"
  s.test_files = Dir["spec/**/*"]

  s.add_development_dependency "bundler"
  s.add_development_dependency "factory_bot_rails"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "rspec-rails", "~> 3.0"
  s.add_development_dependency "pry-rescue"
  s.add_development_dependency "faker"
  s.add_development_dependency "byebug"
  s.add_development_dependency "awesome_print"
  s.add_development_dependency "sqlite3", "~> 1.3.6"
end
