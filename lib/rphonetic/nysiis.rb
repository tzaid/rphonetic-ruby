# frozen_string_literal: true

module RPhonetic
  # New York State Identification and Intelligence System phonetic encoding.
  # Strict mode limits the result to six characters.
  #
  # @example
  #   RPhonetic::Nysiis.encode("WESTERLUND")                # => "WASTAR"
  #   RPhonetic::Nysiis.encode("WESTERLUND", strict: false) # => "WASTARLAD"
  class Nysiis < Encoder
    # Create a NYSIIS encoder.
    #
    # @param strict [Boolean] whether to truncate the code to six characters
    # @raise [ArgumentError] if strict is not true or false
    def initialize(strict: true)
      @native = NativeEncoder.nysiis(boolean(strict, :strict))
    end
  end
end
