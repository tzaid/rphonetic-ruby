# frozen_string_literal: true

module RPhonetic
  # Soundex encodes a name as its initial letter followed by three digits.
  # Input names must be ASCII; non-ASCII names raise ArgumentError.
  #
  # @example
  #   RPhonetic::Soundex.encode("Robert") # => "R163"
  class Soundex < Encoder
    # Default code mapping for the letters A–Z.
    # @return [String]
    DEFAULT_MAPPING = "01230120022455012623010202"
    # Genealogical mapping; hyphens mark letters that are ignored.
    # @return [String]
    GENEALOGY_MAPPING = "-123-12--22455-12623-1-2-2"

    # Create a Soundex encoder with a standard or custom A–Z mapping.
    #
    # @param mapping [String] exactly 26 characters, one per letter A–Z
    # @param special_case_h_w [Boolean] whether H and W leave the preceding code unchanged
    # @raise [TypeError] if mapping is not a String
    # @raise [ArgumentError] if the mapping is invalid or special_case_h_w is not a Boolean
    def initialize(mapping: DEFAULT_MAPPING, special_case_h_w: true)
      @native = NativeEncoder.soundex(text(mapping), boolean(special_case_h_w, :special_case_h_w))
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
