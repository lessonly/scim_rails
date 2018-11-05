$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "scim_rails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "scim_rails"
  s.version     = ScimRails::VERSION
  s.authors     = ["Spencer Alan"]
  s.email       = ["devops@lessonly.com"]
  s.homepage    = "https://github.com/lessonly/scim_rails"
  s.summary     = "SCIM Adapter for Rails."
  s.description = "SCIM Adapter for Rails."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0.0"

  s.add_development_dependency "bundler", "~> 1.16"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rspec", "~> 3.0"
end
