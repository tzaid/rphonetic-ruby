# frozen_string_literal: true

module RPhonetic
  # Shared interface for reusable native phonetic encoders.
  # Each instance owns its native encoder. Class convenience methods accept
  # the same keywords as the concrete encoder's constructor.
  #
  # @abstract Instantiate a concrete algorithm, such as DoubleMetaphone.
  class Encoder
    class << self
      # Construct an encoder and encode one name.
      # Reuse an instance when encoding repeatedly, especially with external rules.
      #
      # @param value [String] name to encode
      # @param options [Hash] keyword arguments accepted by the subclass constructor
      # @return [String] the single or primary code, or Beider–Morse expression
      # @see #encode
      def encode(value, **options)
        new(**options).encode(value)
      end

      # Construct an encoder and encode several names in input order.
      #
      # @param values [Array<String>] names to encode
      # @param options [Hash] keyword arguments accepted by the subclass constructor
      # @return [Array<String>] one result per input name
      # @see #encode_many
      def encode_many(values, **options)
        new(**options).encode_many(values)
      end
    end

    # Encode one name using this instance's configuration.
    # Strings are transcoded to UTF-8; no transliteration is performed.
    #
    # @param value [String] name to encode
    # @return [String] the single or primary code, or Beider–Morse expression
    # @raise [TypeError] if value is not a String
    # @raise [ArgumentError] if the string contains invalid bytes, or an ASCII-only encoder receives non-ASCII text
    # @raise [EncodingError] if the string cannot be transcoded to UTF-8
    # @raise [RuntimeError] if the upstream encoder panics
    def encode(value)
      @native.encode(text(value))
    end

    # Encode an array in one native call, preserving input order.
    # Returns an empty array for empty input. Beider–Morse guesses languages
    # for each name. This call holds Ruby's GVL.
    #
    # @param values [Array<String>] names to encode
    # @return [Array<String>] one result per input name
    # @raise [TypeError] if values is not an Array or contains a non-String
    # @raise [ArgumentError, EncodingError, RuntimeError] for the same input or upstream errors as #encode
    # @see #encode
    def encode_many(values)
      raise TypeError, "values must be an Array" unless values.is_a?(Array)
      @native.encode_many(values.map { |value| text(value) })
    end

    # Compare two names using the upstream algorithm.
    # Match Rating Approach uses its similarity rating. Other encoders compare
    # {#encode} results: Double Metaphone uses primary codes, Daitch–Mokotoff
    # uses nonbranching codes, and Beider–Morse compares entire expressions.
    # This does not check for overlap between alternative codes.
    #
    # @param first [String] first name
    # @param second [String] second name
    # @return [Boolean] whether the algorithm considers the names equivalent
    # @raise [TypeError, ArgumentError, EncodingError, RuntimeError] for the same input or upstream errors as #encode
    def match?(first, second)
      @native.matches(text(first), text(second))
    end

    private

    def text(value)
      raise TypeError, "value must be a String" unless value.is_a?(String)
      raise ArgumentError, "value contains invalid bytes" unless value.valid_encoding?
      value.encode(Encoding::UTF_8)
    end

    def length_option(value, name, unlimited: false)
      return nil if unlimited && value.nil?
      raise ArgumentError, "#{name} must be a positive Integer#{' or nil' if unlimited}" unless value.is_a?(Integer) && value.positive?
      value
    end

    def boolean(value, name)
      raise ArgumentError, "#{name} must be true or false" unless value == true || value == false
      value
    end
  end
end
