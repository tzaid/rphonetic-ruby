# frozen_string_literal: true

module RPhonetic
  # Refined Soundex uses more consonant groups than Soundex and returns
  # variable-length codes. Input names must be ASCII; non-ASCII names raise
  # ArgumentError.
  #
  # @example
  #   RPhonetic::RefinedSoundex.encode("jumped") # => "J408106"
  class RefinedSoundex < Encoder
    # Default code mapping for the letters A–Z.
    # @return [String]
    DEFAULT_MAPPING = "01360240043788015936020505"

    # Create a Refined Soundex encoder.
    #
    # @param mapping [String] exactly 26 characters, one per letter A–Z
    # @raise [TypeError] if mapping is not a String
    # @raise [ArgumentError] if the mapping is invalid
    def initialize(mapping: DEFAULT_MAPPING)
      @native = NativeEncoder.refined_soundex(text(mapping))
    end

    # Count positions at which the two encoded names have the same character.
    # This is a similarity count, not an edit distance.
    #
    # @param first [String] first ASCII name
    # @param second [String] second ASCII name
    # @return [Integer] number of equal positions, from zero through the shorter code's length
    # @raise [TypeError, ArgumentError, EncodingError, RuntimeError] for the same input or upstream errors as #encode
    def difference(first, second)
      @native.difference(text(first), text(second))
    end
  end
end
