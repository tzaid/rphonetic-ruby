# frozen_string_literal: true

require "rbconfig"
require_relative "rphonetic/version"

# Ruby bindings for the rphonetic Rust phonetic algorithms.
# Encoders are reusable and accept valid Strings, transcoded to UTF-8.
module RPhonetic
  # Raised when caller-supplied rules cannot be loaded or parsed.
  class RuleError < ArgumentError; end
end

series = RUBY_VERSION.split(".").first(2).join(".")
binary = File.expand_path("rphonetic/#{series}/rphonetic_ext.#{RbConfig::CONFIG.fetch('DLEXT')}", __dir__)
local_binary = File.expand_path("rphonetic/rphonetic_ext.#{RbConfig::CONFIG.fetch('DLEXT')}", __dir__)
if File.file?(local_binary)
  # A fresh development build takes precedence over staged release artifacts.
  require local_binary
elsif File.file?(binary)
  require binary
else
  require "rphonetic/rphonetic_ext"
end

require_relative "rphonetic/encoders"
