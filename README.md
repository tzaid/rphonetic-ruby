# rphonetic

Ruby bindings for all twelve algorithms in the [rphonetic Rust crate](https://github.com/Dalvany/rphonetic).
The wrapper pins rphonetic 4.0.0 and uses Magnus. Supports CRuby 3.4 and 4.0.

## Installation

```ruby
gem "rphonetic", "~> 1.0"
```

This project has not been published yet. Build a local source gem with
`bundle exec rake build`. Installing the source gem needs Rust and a C toolchain.
The included CI workflow builds platform gems for Linux glibc (x64/ARM64),
macOS (Intel/Apple Silicon), and Windows x64 UCRT, with binaries for Ruby
3.4 and 4.0 in each package. Those packages require no Rust toolchain
at installation. CI builds need to pass before these targets are considered
verified. Linux builds target glibc 2.35 or newer; Alpine/musl is not included.

## API

Every encoder provides `encode(string)`, `encode_many(array)`, and
`match?(first, second)`. There are also class-level `encode` and `encode_many`
conveniences, which construct an encoder per call. Reuse instances when encoding
many names, especially when rules need parsing.

```ruby
require "rphonetic"

encoder = RPhonetic::DoubleMetaphone.new(max_length: 4)
encoder.encode("Smith")                     # => "SM0"
encoder.codes("Smith")                      # => ["SM0", "XMT"]
encoder.alternate("Smith")                  # => "XMT"
encoder.encode_many(["Smith", "Schmidt"])    # => ["SM0", "XMT"]
RPhonetic::DoubleMetaphone.codes("Smith")     # => ["SM0", "XMT"]
RPhonetic::Soundex.encode("Robert")           # => "R163"
```

`encode` consistently returns the upstream primary/single code as a String.
For Double Metaphone, `codes` always returns two strings, including duplicates
when primary and alternate are identical. For Daitch–Mokotoff, `codes` returns
all branching codes as an Array. Beider–Morse returns the upstream expression
string, preserving its parentheses, alternatives, and word groupings.

| Class under `RPhonetic` | Constructor options | Additional methods |
| --- | --- | --- |
| `Caverphone1` | None | |
| `Caverphone2` | None | |
| `Cologne` | None | |
| `MatchRatingApproach` | None | |
| `Metaphone` | `max_length: 4` (`nil` for unlimited) | |
| `DoubleMetaphone` | `max_length: 4` (`nil` for unlimited) | `codes`, `alternate` |
| `Nysiis` | `strict: true` | |
| `Phonex` | `max_length: 4` | |
| `Soundex` | `mapping: DEFAULT_MAPPING`, `special_case_h_w: true` | `difference` |
| `RefinedSoundex` | `mapping: DEFAULT_MAPPING` | `difference` |
| `DaitchMokotoffSoundex` | Required `rules:`, `ascii_folding: true` | `codes` |
| `BeiderMorse` | Required `rules_path:`, `name_type: :generic`, `rule_type: :approx`, `concat: true`, `max_phonemes: 20` | `encode(value, languages: nil)` |

Lengths must be positive integers; only Metaphone and Double Metaphone support
`nil`. Custom Soundex mappings contain 26 characters, corresponding to A–Z.
`Soundex::GENEALOGY_MAPPING` is also available. `difference` counts matching
positions in the codes. `match?` delegates to the crate: it compares primary
codes for Double Metaphone and uses the rating algorithm for Match Rating
Approach. To match either Double Metaphone code, compare the nonempty codes:

```ruby
left = encoder.codes("Smith").reject(&:empty?)
right = encoder.codes("Schmidt").reject(&:empty?)
left.intersect?(right) # => true
```

## External rules

No default rule files are embedded in or shipped with the gem. Supply compatible
[Apache Commons Codec 1.15 rule data](https://github.com/apache/commons-codec/tree/rel/commons-codec-1.15/src/main/resources/org/apache/commons/codec/language)
with your application; the gem never downloads rules automatically.

```ruby
dm = RPhonetic::DaitchMokotoffSoundex.new(rules: File.read("config/dmrules.txt"))
dm.codes("Rosochowaciec")
# => ["944744", "944745", "944754", "944755", "945744", "945745", "945754", "945755"]

bm = RPhonetic::BeiderMorse.new(rules_path: "config/bm")
bm.encode("Smith")                        # guess languages
bm.encode("Smith", languages: ["english"])
bm.encode("Smith", languages: :any)
```

Beider–Morse needs the complete configuration directory, including files
referenced by other rules. `name_type` accepts `:generic`, `:ashkenazi`, or
`:sephardic`; `rule_type` accepts `:approx` or `:exact`. Language names must be
supported by the supplied rules. Both encoders parse their rules at construction
and own the parsed data. Files can be removed afterward without affecting an
existing encoder. Missing/malformed rules normally raise `RPhonetic::RuleError`.
An upstream panic is caught and surfaced as `RuntimeError`.

## Text and threading

Inputs must be valid Ruby Strings and are transcoded to UTF-8. No automatic
transliteration is performed. Soundex and RefinedSoundex require ASCII input
because their upstream implementations use A–Z mapping tables. Other algorithms
retain upstream handling of non-ASCII text; they are not universal multilingual
phonetic encoders. Encoding currently holds Ruby's GVL; `encode_many` reduces
boundary crossings but does not enable parallel Ruby threads.

## Development

All public classes and methods have YARD documentation. RBS signatures live in
`sig/` and ship with both source and platform gems. Type checkers using the gem's
signatures can load them with `library "rphonetic"` (for example in a Steepfile).
Signatures describe constructor keywords, inherited class conveniences, and
Double Metaphone's `[String, String]` result. Constraints such as positive lengths
and nonempty language arrays are checked at runtime.

Generate HTML API documentation with `bundle exec rake docs` (open
`doc/index.html`) and validate signatures with `bundle exec rake rbs`.

Install Rust, Ruby 3.4 or 4.0, a C compiler and libclang, then:

```sh
bundle install
bundle exec rake spec
cargo fmt --check
cargo clippy --locked -- -D warnings
bundle exec rake build
```

`Cargo.lock` is included in source releases for reproducible dependency versions.
The RSpec suite lives in `spec/`. `bundle exec rake spec` compiles the extension
before running the suite; `bundle exec rspec` runs it using an existing build.
`bundle exec rake test` remains an alias for `spec`. CI runs the same specs
against installed platform gems from outside the checkout, so RSpec's local
load path cannot accidentally select the source copy.
The Apache rule fixtures are used only by specs and excluded from all gems.

The [CI workflow](https://github.com/tzaid/rphonetic-ruby/actions/workflows/ci.yml)
compiles and tests each OS/CPU/Ruby combination,
combines the two Ruby binaries into each platform gem, then installs and
loads the packaged gem on each target. The package job uses Ruby 3.4 only to
assemble the archive; it includes the binaries compiled separately for both
Ruby versions. It uploads gem artifacts; it does not
publish to RubyGems. To assemble a platform package manually, place genuine
target binaries in `lib/rphonetic/{3.4,4.0}/rphonetic_ext.<DLEXT>` and run:

```sh
ruby script/package.rb --platform arm64-darwin
```

Never label a binary for an OS, CPU, or Ruby version it was not compiled for.
For local package verification with a single Ruby installation, run
`ruby script/stage_binary.rb`, then add `--ruby-abi 3.4` (or your supported
Ruby series) to the package command. This restricts the gem's Ruby requirement
to that series. Release CI packages both ABIs.

## Versioning

The gem uses independent, three-part semantic versions, starting at `1.0.0`.
Patch releases fix bugs, minor releases add compatible Ruby functionality, and
major releases introduce breaking changes to the Ruby API or behavior. Upstream
crate updates are assessed by their effect on Ruby consumers rather than by
copying the crate's version number. Gem `1.0.0` wraps rphonetic `4.0.0`.

## License

Apache-2.0. See LICENSE and NOTICE. Upstream test fixture attribution is in
`spec/fixtures/NOTICE`.
