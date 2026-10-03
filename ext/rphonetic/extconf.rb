# frozen_string_literal: true

require "mkmf"
require "rb_sys/mkmf"

create_rust_makefile("rphonetic/rphonetic_ext") do |config|
  config.extra_cargo_args = ["--locked"]
end
