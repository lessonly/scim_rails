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

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.required_ruby_version = "~> 3.1"
  s.add_dependency "rails", ">= 6.0", "<= 7.1"
  s.add_runtime_dependency "jwt", ">= 1.5"
  s.test_files = Dir["spec/**/*"]

  s.add_development_dependency "appraisal"
  s.add_development_dependency "bundler", "~> 2.0"
  s.add_development_dependency "factory_bot_rails"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "rspec-rails", "~> 5.0"
  s.add_development_dependency "sqlite3", "~> 1.3", "< 1.5"
end
