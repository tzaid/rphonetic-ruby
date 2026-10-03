# frozen_string_literal: true

require "rphonetic"
require "tmpdir"
require "fileutils"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
  config.expect_with(:rspec) { |expectations| expectations.syntax = :expect }
end
