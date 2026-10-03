# frozen_string_literal: true

module RPhonetic
  # The revised Caverphone algorithm for English names. Codes contain ten
  # characters, padded with `1`.
  #
  # @example
  #   RPhonetic::Caverphone2.encode("Thompson") # => "TMPSN11111"
  class Caverphone2 < Encoder
    # Create a Caverphone2 encoder. This algorithm has no configuration options.
    def initialize
      @native = NativeEncoder.simple("Caverphone2")
    end
  end
end
