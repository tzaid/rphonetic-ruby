# frozen_string_literal: true

module RPhonetic
  # Double Metaphone produces primary and alternate phonetic codes.
  # Inherited {#encode} and {#match?} use only the primary code. Use {#codes}
  # when comparing names across both pronunciations.
  #
  # @example
  #   RPhonetic::DoubleMetaphone.codes("Smith") # => ["SM0", "XMT"]
  class DoubleMetaphone < Encoder
    # Create a Double Metaphone encoder.
    #
    # @param max_length [Integer, nil] positive maximum length of each code; nil removes the limit
    # @raise [ArgumentError] if max_length is neither positive nor nil
    def initialize(max_length: 4)
      @native = NativeEncoder.double_metaphone(length_option(max_length, :max_length, unlimited: true))
    end

    # Construct an encoder and return both codes for one name.
    #
    # @param value [String] name to encode
    # @param options [Hash] constructor keywords
    # @option options [Integer, nil] :max_length (4) positive maximum code length; nil removes the limit
    # @return [Array(String, String)] primary and alternate codes, in that order
    # @see #codes
    # @see #initialize
    def self.codes(value, **options)
      new(**options).codes(value)
    end

    # Return the primary and alternate codes.
    # The result always contains two strings, even when the codes are identical
    # or empty. Both codes respect the configured max_length.
    #
    # @param value [String] name to encode
    # @return [Array(String, String)] primary and alternate codes, in that order
    # @raise [TypeError, ArgumentError, EncodingError, RuntimeError] for the same input or upstream errors as #encode
    def codes(value)
      @native.codes(text(value))
    end

    # Return only the alternate code.
    #
    # @param value [String] name to encode
    # @return [String] alternate code, possibly identical to the primary code or empty
    # @raise [TypeError, ArgumentError, EncodingError, RuntimeError] for the same input or upstream errors as #encode
    # @see #codes
    def alternate(value)
      codes(value).last
    end
  end
end
