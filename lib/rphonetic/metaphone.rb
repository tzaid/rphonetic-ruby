# frozen_string_literal: true

module RPhonetic
  # Metaphone encodes English pronunciation as a single phonetic code.
  #
  # @example
  #   RPhonetic::Metaphone.encode("Joanne") # => "JN"
  class Metaphone < Encoder
    # Create a Metaphone encoder.
    #
    # @param max_length [Integer, nil] positive maximum code length; nil removes the limit
    # @raise [ArgumentError] if max_length is neither positive nor nil
    def initialize(max_length: 4)
      @native = NativeEncoder.metaphone(length_option(max_length, :max_length, unlimited: true))
    end
  end
end
