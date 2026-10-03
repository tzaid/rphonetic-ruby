# frozen_string_literal: true

require "rubygems/package"
require "yaml"
require_relative "../lib/rphonetic/version"

Dir.chdir(File.expand_path("..", __dir__))
abort "Tag must match v#{RPhonetic::VERSION}" unless ENV.fetch("RELEASE_TAG") == "v#{RPhonetic::VERSION}"

matrix = YAML.load_file(".github/workflows/ci.yml", aliases: true).fetch("jobs").fetch("build").fetch("strategy").fetch("matrix")
platforms = ["ruby"] + matrix.fetch("target").map { |target| target.fetch("platform") }
abis = matrix.fetch("ruby")
expected_spec = Gem::Specification.load("rphonetic.gemspec")
files = Dir["pkg/*.gem"]
abort "Expected #{platforms.length} release packages, found #{files.length}" unless files.length == platforms.length

seen = []
files.each do |file|
  package = Gem::Package.new(file)
  package.verify
  spec = package.spec
  platform = spec.platform.to_s
  abort "Unexpected gem: #{file}" unless spec.name == "rphonetic" && spec.version.to_s == RPhonetic::VERSION
  abort "Unexpected or duplicate platform: #{platform}" unless platforms.include?(platform) && !seen.include?(platform)
  abort "Incorrect Ruby requirement: #{file}" unless spec.required_ruby_version == expected_spec.required_ruby_version
  if platform == "ruby"
    abort "Missing source build hook: #{file}" unless spec.extensions == ["ext/rphonetic/extconf.rb"]
  else
    abort "Unexpected native build hook or dependency: #{file}" unless spec.extensions.empty? && spec.runtime_dependencies.empty?
    abis.each do |abi|
      binaries = spec.files.grep(%r{\Alib/rphonetic/#{Regexp.escape(abi)}/rphonetic_ext\.(so|bundle|dll)\z})
      abort "Expected one binary for Ruby #{abi}: #{file}" unless binaries.length == 1
    end
  end
  seen << platform
end

puts "Verified #{files.length} packages for rphonetic #{RPhonetic::VERSION}: #{seen.sort.join(', ')}"
