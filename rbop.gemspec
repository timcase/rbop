# frozen_string_literal: true

require_relative "lib/rbop/version"

Gem::Specification.new do |spec|
  spec.name          = "rbop"
  spec.version       = Rbop::VERSION
  spec.authors       = [ "Tim Case" ]
  spec.email         = [ "tim@2drops.net" ]

  spec.summary = "Ruby wrapper around the 1Password CLI for effortless secret retrieval in your scripts."
  spec.description = "rbop lets any Ruby ≥ 3.0 program pull secrets from 1Password with a single line of code.
It shells out to the official op CLI, performs an interactive sign-in when needed"
  spec.homepage      = "https://github.com/timcase/rbop"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.3.0"
  spec.files = Dir["lib/**/*", "README.md", "LICENSE.txt"]
  spec.require_paths = [ "lib" ]

  spec.add_dependency "activesupport"

  spec.add_development_dependency "minitest"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "factory_bot"
end
