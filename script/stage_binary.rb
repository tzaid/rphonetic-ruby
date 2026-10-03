# frozen_string_literal: true

require "rbconfig"
require "fileutils"

Dir.chdir(File.expand_path("..", __dir__))
abi = RUBY_VERSION.split(".").first(2).join(".")
extension = "rphonetic_ext.#{RbConfig::CONFIG.fetch('DLEXT')}"
destination = "lib/rphonetic/#{abi}"
FileUtils.mkdir_p(destination)
FileUtils.cp("lib/rphonetic/#{extension}", "#{destination}/#{extension}")
