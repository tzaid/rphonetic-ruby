# frozen_string_literal: true

require_relative "encoder"
require_relative "caverphone1"
require_relative "caverphone2"
require_relative "cologne"
require_relative "match_rating_approach"
require_relative "metaphone"
require_relative "double_metaphone"
require_relative "nysiis"
require_relative "phonex"
require_relative "soundex"
require_relative "refined_soundex"
require_relative "daitch_mokotoff_soundex"
require_relative "beider_morse"

module RPhonetic
  private_constant :NativeEncoder
end
