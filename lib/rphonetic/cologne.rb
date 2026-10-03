# frozen_string_literal: true

module RPhonetic
  # Cologne phonetics (Kölner Phonetik) for German names, including umlauts.
  # Returns a variable-length numeric code.
  #
  # @example
  #   RPhonetic::Cologne.encode("müller") # => "657"
  class Cologne < Encoder
    # Create a Cologne encoder. This algorithm has no configuration options.
    def initialize
      @native = NativeEncoder.simple("Cologne")
    end
  end
end
