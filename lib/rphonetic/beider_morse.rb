# frozen_string_literal: true

module RPhonetic
  # Beider–Morse phonetic matching with caller-supplied configuration files.
  # Results are expression strings preserving alternatives, parentheses, and
  # word groupings. {#match?} compares complete expression strings.
  #
  # The full rules directory is parsed at construction and owned by the
  # instance; later changes to those files do not affect it. No rules are
  # bundled. Inherited {.encode}, {.encode_many}, and {#encode_many} guess
  # languages for each name; use {#encode} to select languages explicitly.
  #
  # @example
  #   encoder = RPhonetic::BeiderMorse.new(rules_path: "config/bm")
  #   encoder.encode("Smith", languages: ["english"])
  class BeiderMorse < Encoder
    # Load a complete Apache Commons Codec Beider–Morse rules directory.
    # Referenced rule files must also be present.
    #
    # @param rules_path [String] path to the configuration directory
    # @param name_type [Symbol, String] generic, ashkenazi, or sephardic
    # @param rule_type [Symbol, String] approx or exact
    # @param concat [Boolean] whether to encode words together instead of separately
    # @param max_phonemes [Integer] positive limit on generated phonemes
    # @raise [RuleError] if files cannot be read or rule parsing fails
    # @raise [TypeError] if rules_path is not a String
    # @raise [ArgumentError] if an option has an invalid value
    # @raise [RuntimeError] if the upstream parser panics
    def initialize(rules_path:, name_type: :generic, rule_type: :approx, concat: true, max_phonemes: 20)
      @native = NativeEncoder.beider_morse(
        text(rules_path), name_type.to_s, rule_type.to_s,
        boolean(concat, :concat), length_option(max_phonemes, :max_phonemes)
      )
    end

    # Encode a name with guessed or explicitly selected languages.
    # Language names must be supported by the supplied configuration.
    # This keyword is available only on the instance method.
    #
    # @param value [String] name to encode
    # @param languages [nil, :any, Array<String>] nil guesses languages; :any uses catch-all rules; a nonempty array selects language names
    # @return [String] phonetic expression including alternatives and word groupings
    # @raise [ArgumentError] if languages is not nil, :any, or a nonempty Array
    # @raise [TypeError, ArgumentError, EncodingError, RuntimeError] for the same input or upstream errors as Encoder#encode
    def encode(value, languages: nil)
      return super(value) if languages.nil?
      unless languages == :any || (languages.is_a?(Array) && !languages.empty?)
        raise ArgumentError, "languages must be nil, :any, or a nonempty Array of language names"
      end
      selected = languages == :any ? ["any"] : languages.map { |language| text(language) }
      @native.encode_languages(text(value), selected)
    end
  end
end
