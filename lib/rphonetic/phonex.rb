# frozen_string_literal: true

module RPhonetic
  # Phonex combines Soundex-style codes with pronunciation normalization.
  # Codes are padded with zeroes to the configured length.
  #
  # @example
  #   RPhonetic::Phonex.encode("William") # => "W450"
  class Phonex < Encoder
    # Create a Phonex encoder.
    #
    # @param max_length [Integer] positive code length; nil is not supported
    # @raise [ArgumentError] if max_length is not a positive Integer
    def initialize(max_length: 4)
      @native = NativeEncoder.phonex(length_option(max_length, :max_length))
    end
  end
end
