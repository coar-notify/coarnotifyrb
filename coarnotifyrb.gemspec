# frozen_string_literal: true

require_relative "lib/coarnotify/version"

Gem::Specification.new do |spec|
  spec.name          = "coarnotify"
  spec.version       = Coarnotify::VERSION
  spec.authors       = ["Cottage Labs"]
  spec.email         = ["us@cottagelabs.com"]
  spec.summary       = "COAR Notify Common Library"
  spec.description   = "COAR Notify Common Library"
  spec.license       = "MIT"
  spec.files         = Dir["lib/**/*"]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "json", "~> 2.0"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
end
