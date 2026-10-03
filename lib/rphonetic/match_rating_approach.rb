# frozen_string_literal: true

module RPhonetic
  # Match Rating Approach encodes names in at most six characters.
  # Unlike the other encoders, {#match?} applies the algorithm's similarity
  # rating rather than requiring identical codes.
  #
  # @example
  #   encoder = RPhonetic::MatchRatingApproach.new
  #   encoder.encode("Smith")       # => "SMTH"
  #   encoder.match?("Smith", "Smyth") # => true
  class MatchRatingApproach < Encoder
    # Create a MatchRatingApproach encoder. This algorithm has no configuration options.
    def initialize
      @native = NativeEncoder.simple("MatchRatingApproach")
    end
  end
end
