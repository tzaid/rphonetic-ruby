# frozen_string_literal: true

module RPhonetic
  # The original Caverphone algorithm for English names, developed for
  # New Zealand pronunciation. Codes contain six characters, padded with `1`.
  #
  # @example
  #   RPhonetic::Caverphone1.encode("Thompson") # => "TMPSN1"
  class Caverphone1 < Encoder
    # Create a Caverphone1 encoder. This algorithm has no configuration options.
    def initialize
      @native = NativeEncoder.simple("Caverphone1")
    end
  end
end
