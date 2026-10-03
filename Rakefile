# frozen_string_literal: true

require "rb_sys/extensiontask"
require "rspec/core/rake_task"

spec = Gem::Specification.load("rphonetic.gemspec")
RbSys::ExtensionTask.new("rphonetic_ext", spec) do |ext|
  ext.ext_dir = "ext/rphonetic"
  ext.lib_dir = "lib/rphonetic"
end

RSpec::Core::RakeTask.new(:spec)
task spec: :compile

desc "Run the RSpec suite (alias for spec)"
task test: :spec

desc "Build the source gem (requires Rust when installed)"
task :build do
  ruby "script/package.rb"
end

desc "Generate public API documentation in doc/"
task :docs do
  sh "yard doc --fail-on-warning"
end

desc "Validate the shipped RBS signatures"
task :rbs do
  sh "rbs -I sig validate"
end

task default: :spec
