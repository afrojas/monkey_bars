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

  gemspec = File.basename(__FILE__)
  excluded_prefixes = %w[
    bin/ test/ spec/ features/
    .git .github appveyor
    .dockerignore .rspec .tool-versions
    Dockerfile docker-compose.yml Gemfile Rakefile
  ].freeze

  files =
    begin
      IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
        ls.readlines("\x0", chomp: true).reject do |f|
          (f == gemspec) ||
            (f == "docs/monkey_bars_patch_for_readme.png") ||
            f.start_with?(*excluded_prefixes)
        end
      end
    rescue Errno::ENOENT
      []
    end

  if files.empty?
    files = Dir.chdir(__dir__) do
      Dir.glob("**/*", File::FNM_DOTMATCH).select { |f| File.file?(f) }.reject do |f|
        (f == ".") ||
          (f == "..") ||
          (f == gemspec) ||
          (f == "docs/monkey_bars_patch_for_readme.png") ||
          f.start_with?(*excluded_prefixes)
      end
    end
  end

  spec.files = files
  spec.require_paths = ["lib"]

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "standard", "~> 1.40"
end
