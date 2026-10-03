# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe RPhonetic do
  let(:fixtures) { File.expand_path("fixtures", __dir__) }

  {
    Caverphone1: ["Thompson", "TMPSN1"],
    Caverphone2: ["Thompson", "TMPSN11111"],
    Cologne: ["müller", "657"],
    MatchRatingApproach: ["Smith", "SMTH"],
    Metaphone: ["Joanne", "JN"],
    DoubleMetaphone: ["jumped", "JMPT"],
    Nysiis: ["WESTERLUND", "WASTAR"],
    Phonex: ["William", "W450"],
    Soundex: ["jumped", "J513"],
    RefinedSoundex: ["jumped", "J408106"]
  }.each do |name, (input, expected)|
    describe RPhonetic.const_get(name) do
      it "encodes the reference name through the class convenience method" do
        expect(described_class.encode(input)).to eq(expected)
      end

      it "encodes a batch in input order" do
        expect(described_class.new.encode_many([input, input])).to eq([expected, expected])
      end

      it "accepts an empty batch" do
        expect(described_class.new.encode_many([])).to eq([])
      end
    end
  end

  describe RPhonetic::DoubleMetaphone do
    it "returns primary and alternate codes" do
      expect(described_class.codes("Smith")).to eq(["SM0", "XMT"])
      expect(described_class.codes("jumped")).to eq(["JMPT", "AMPT"])
    end

    it "preserves identical primary and alternate codes" do
      expect(described_class.codes("Coburn")).to eq(["KPRN", "KPRN"])
    end

    it "returns the alternate code separately" do
      expect(described_class.new.alternate("Smith")).to eq("XMT")
    end

    it "supports unlimited and explicitly bounded code lengths" do
      full = described_class.codes("Schwarzenegger", max_length: nil)
      expect(full.first.length).to be > 4
      expect(described_class.codes("Schwarzenegger")).to eq(full.map { |code| code[0, 4] })
      expect(described_class.codes("Schwarzenegger", max_length: 2)).to eq(full.map { |code| code[0, 2] })
    end

    it "requires a String input" do
      expect { described_class.encode(nil) }.to raise_error(TypeError)
    end

    it "requires an Array of Strings for batches" do
      expect { described_class.encode_many("Smith") }.to raise_error(TypeError)
      expect { described_class.encode_many(["Smith", nil]) }.to raise_error(TypeError)
    end

    it "rejects invalid encoded text" do
      expect { described_class.encode("\xff".b.force_encoding("UTF-8")) }.to raise_error(ArgumentError)
    end

    [0, -1, 2.5, "4"].each do |length|
      it "rejects max_length: #{length.inspect}" do
        expect { described_class.new(max_length: length) }.to raise_error(ArgumentError)
      end
    end
  end

  describe RPhonetic::Nysiis do
    it "supports non-strict encoding" do
      expect(described_class.encode("WESTERLUND", strict: false)).to eq("WASTARLAD")
    end

    it "requires a Boolean for strict" do
      expect { described_class.new(strict: "false") }.to raise_error(ArgumentError)
    end
  end

  describe RPhonetic::Metaphone do
    it "supports bounded and unlimited code lengths" do
      expect(described_class.encode("Joanne", max_length: 1)).to eq("J")
      expect(described_class.encode("Joanne", max_length: nil)).to eq("JN")
    end
  end

  describe RPhonetic::Phonex do
    it "supports a custom code length" do
      expect(described_class.encode("William", max_length: 2)).to eq("W4")
    end

    it "rejects an unlimited code length" do
      expect { described_class.new(max_length: nil) }.to raise_error(ArgumentError)
    end
  end

  describe RPhonetic::Caverphone1 do
    it "compares encoded names" do
      encoder = described_class.new
      expect(encoder.match?("Peter", "Peady")).to be(true)
      expect(encoder.match?("Peter", "Stevenson")).to be(false)
    end
  end

  describe RPhonetic::Soundex do
    it "counts matching code positions" do
      expect(described_class.new.difference("Robert", "Rupert")).to eq(4)
    end

    it "supports a custom mapping" do
      expect(described_class.encode("Abc", mapping: "0" * 26)).to eq("A000")
    end

    it "requires a mapping for all 26 letters" do
      expect { described_class.new(mapping: "abc") }.to raise_error(ArgumentError)
    end

    it "rejects non-ASCII names" do
      expect { described_class.encode("müller") }.to raise_error(ArgumentError)
    end
  end

  describe RPhonetic::RefinedSoundex do
    it "counts matching code positions" do
      expect(described_class.new.difference("jumped", "jumped")).to eq(7)
    end

    it "supports a custom mapping" do
      expect(described_class.encode("Abc", mapping: "0" * 26)).to eq("A0")
    end

    it "rejects non-ASCII names" do
      expect { described_class.encode("müller") }.to raise_error(ArgumentError)
    end
  end

  describe RPhonetic::MatchRatingApproach do
    it "uses the upstream rating comparison instead of code equality" do
      encoder = described_class.new
      expect(encoder.match?("", "")).to be(false)
      expect(encoder.match?("Smith", "Smyth")).to be(true)
    end
  end

  describe RPhonetic::DaitchMokotoffSoundex do
    it "parses external rules and returns both branching and nonbranching codes" do
      encoder = described_class.new(rules: File.read("#{fixtures}/dmrules.txt"))
      expected = %w[944744 944745 944754 944755 945744 945745 945754 945755]
      expect(encoder.codes("Rosochowaciec")).to eq(expected)
      expect(encoder.encode("Rosochowaciec")).to eq(expected.first)
      expect(encoder.encode_many(["Rosochowaciec"])).to eq([expected.first])
    end

    it "supports custom rules without ASCII folding" do
      encoder = described_class.new(rules: "\"a\" \"1\" \"1\" \"1\"\n", ascii_folding: false)
      expect(encoder.encode("a")).to eq("100000")
    end

    it "reports malformed rule text" do
      expect { described_class.new(rules: "invalid rule\n") }.to raise_error(RPhonetic::RuleError)
    end
  end

  describe RPhonetic::BeiderMorse do
    it "owns its parsed rules after files are removed and garbage collection runs" do
      Dir.mktmpdir do |dir|
        FileUtils.cp_r("#{fixtures}/bm/.", dir)
        encoder = described_class.new(rules_path: dir, rule_type: :exact)
        FileUtils.rm_rf(Dir.children(dir).map { |name| File.join(dir, name) })
        GC.start
        GC.compact if GC.respond_to?(:compact)
        expect(encoder.encode("Angelo")).to eq("anZelo|andZelo|angelo|anhelo|anjelo|anxelo")
        expect(encoder.encode("Angelo", languages: ["italian"])).to eq("andZelo")
        expect(encoder.encode_many(["Smith"])).to eq([encoder.encode("Smith")])
        expect(encoder.encode("Smith", languages: ["english"])).to be_a(String)
        expect(encoder.encode("Smith", languages: :any)).to be_a(String)
      end
    end

    %i[generic ashkenazi sephardic].each do |name|
      it "supports the #{name} name type with separate words and a phoneme limit" do
        encoder = described_class.new(rules_path: "#{fixtures}/bm", name_type: name, rule_type: :exact, concat: false, max_phonemes: 5)
        expect(encoder.encode("Smith")).not_to be_empty
      end
    end

    it "reports a missing rule directory" do
      expect { described_class.new(rules_path: "#{fixtures}/missing") }.to raise_error(RPhonetic::RuleError)
    end

    [{ name_type: :invalid }, { rule_type: :invalid }, { max_phonemes: 0 }].each do |options|
      it "rejects invalid configuration #{options.inspect}" do
        expect { described_class.new(rules_path: "#{fixtures}/bm", **options) }.to raise_error(ArgumentError)
      end
    end
  end

  describe RPhonetic::Cologne do
    it "transcodes names to UTF-8" do
      expect(described_class.encode("müller".encode("ISO-8859-1"))).to eq("657")
    end

    it "ignores H between identical codes" do
      expect(described_class.encode("Mülhler")).to eq("657")
      expect(described_class.encode("Bhb")).to eq("1")
      expect(described_class.encode("Hoffmann")).to eq("0366")
    end
  end
end
