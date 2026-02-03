# frozen_string_literal: true

require_relative "lib/monkey_bars/version"

Gem::Specification.new do |spec|
  spec.name = "monkey_bars"
  spec.version = MonkeyBars::VERSION
  spec.authors = ["Andrés Rojas"]
  spec.email = ["afrojas@gmail.com"]

  spec.summary = "Safe, version-aware monkey patching for Ruby modules"
  spec.description = "MonkeyBars provides a structured DSL for safely monkey patching Ruby modules with built-in version checking, method validation, and constant management to prevent silent breakage when dependencies update."
  spec.homepage = "https://github.com/afrojas/monkey_bars"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0", "< 4.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/afrojas/monkey_bars"
  spec.metadata["bug_tracker_uri"] = "https://github.com/afrojas/monkey_bars/issues"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/monkey_bars"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = %w[
    CODE_OF_CONDUCT.md
    CONTRIBUTING.md
    LICENSE.txt
    README.md
    docs/llm-usage.md
    lib/monkey_bars.rb
    lib/monkey_bars/errors.rb
    lib/monkey_bars/patch.rb
    lib/monkey_bars/validation.rb
    lib/monkey_bars/version.rb
  ]
  spec.require_paths = ["lib"]

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "standard", "~> 1.40"
end
