# frozen_string_literal: true

require "rubygems/package"
require "fileutils"
require "optparse"

Dir.chdir(File.expand_path("..", __dir__))
options = {}
OptionParser.new do |parser|
  parser.on("--platform PLATFORM") { |value| options[:platform] = value }
  parser.on("--ruby-abi ABI", "Package only this ABI for local verification") { |value| options[:abi] = value }
end.parse!

spec = Gem::Specification.load("rphonetic.gemspec")
abort "--ruby-abi requires --platform" if options[:abi] && !options[:platform]
if options[:platform]
  spec.platform = Gem::Platform.new(options.fetch(:platform))
  abis = options[:abi] ? [options[:abi]] : %w[3.4 4.0]
  abort "Unsupported Ruby ABI" unless (abis - %w[3.4 4.0]).empty?
  abis.each do |abi|
    files = Dir["lib/rphonetic/#{abi}/rphonetic_ext.{so,bundle,dll}"]
    abort "Expected one extension for Ruby #{abi}, found #{files.length}" unless files.length == 1
  end
  spec.files = Dir["lib/**/*.rb", "sig/**/*.rbs"] + abis.flat_map { |abi| Dir["lib/rphonetic/#{abi}/rphonetic_ext.{so,bundle,dll}"] } + %w[README.md LICENSE NOTICE]
  spec.extensions = []
  spec.dependencies.delete_if { |dep| dep.name == "rb_sys" }
  spec.required_ruby_version = "~> #{options[:abi]}.0" if options[:abi]
end

missing = spec.files.reject { |path| File.file?(path) }
abort "Missing package files: #{missing.join(', ')}" unless missing.empty?
FileUtils.mkdir_p("pkg")
file = Gem::Package.build(spec)
FileUtils.mv(file, "pkg/#{file}")
