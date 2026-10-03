# frozen_string_literal: true

require_relative "lib/rphonetic/version"

Gem::Specification.new do |spec|
  spec.name = "rphonetic"
  spec.version = RPhonetic::VERSION
  spec.authors = ["tzaid"]
  spec.homepage = "https://github.com/tzaid/rphonetic-ruby"
  spec.metadata = {
    "source_code_uri" => spec.homepage,
    "bug_tracker_uri" => "#{spec.homepage}/issues"
  }
  spec.summary = "Ruby bindings for the rphonetic Rust phonetic algorithms"
  spec.description = "Reusable encoders for all twelve rphonetic algorithms, with caller-supplied rules and precompiled native gem support."
  spec.license = "Apache-2.0"
  spec.required_ruby_version = [">= 3.4", "< 4.1"]
  spec.files = Dir["lib/**/*.rb", "sig/**/*.rbs", "ext/**/*.{rb,rs,toml}"] +
    %w[Cargo.toml Cargo.lock README.md LICENSE NOTICE]
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/rphonetic/extconf.rb"]
  spec.add_dependency "rb_sys", "~> 0.9"
end
