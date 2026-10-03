use std::panic::{catch_unwind, AssertUnwindSafe};
use std::path::PathBuf;

use magnus::{function, method, prelude::*, Error, Ruby};
use rphonetic::{
    BeiderMorseBuilder, Caverphone1, Caverphone2, Cologne, ConfigFiles, DaitchMokotoffSoundex,
    DaitchMokotoffSoundexBuilder, DoubleMetaphone, Encoder, LanguageSet, MatchRatingApproach,
    Metaphone, NameType, Nysiis, Phonex, RefinedSoundex, RuleType, Soundex, SoundexCommons,
};

struct BeiderConfig {
    // Own the parsed rules. Build a cheap borrowing engine for each call,
    // avoiding self-references, leaked rules, and Ruby GC lifetime hazards.
    files: ConfigFiles,
    name_type: NameType,
    rule_type: RuleType,
    concat: bool,
    max_phonemes: usize,
}

impl BeiderConfig {
    fn builder(&self) -> BeiderMorseBuilder<'_> {
        BeiderMorseBuilder::new(&self.files)
            .name_type(self.name_type)
            .rule_type(self.rule_type)
            .concat(self.concat)
            .max_phonemes(self.max_phonemes)
    }
}

enum Algorithm {
    Simple(Box<dyn Encoder + Send>),
    Double(DoubleMetaphone),
    Soundex(Soundex),
    Refined(RefinedSoundex),
    Daitch(DaitchMokotoffSoundex),
    Beider(Box<BeiderConfig>),
}

#[magnus::wrap(class = "RPhonetic::NativeEncoder", free_immediately, size)]
struct NativeEncoder(Algorithm);

fn argument_error(message: impl Into<String>) -> Error {
    Error::new(Ruby::get().unwrap().exception_arg_error(), message.into())
}

fn rule_error(error: rphonetic::PhoneticError) -> Error {
    let ruby = Ruby::get().unwrap();
    let module = ruby
        .class_object()
        .const_get::<_, magnus::RModule>("RPhonetic")
        .unwrap();
    let class = module
        .const_get::<_, magnus::ExceptionClass>("RuleError")
        .unwrap();
    Error::new(class, error.to_string())
}

// Malformed external rules or unsupported text must never unwind through Ruby.
fn checked<T>(f: impl FnOnce() -> Result<T, Error>) -> Result<T, Error> {
    catch_unwind(AssertUnwindSafe(f)).unwrap_or_else(|_| {
        Err(Error::new(
            Ruby::get().unwrap().exception_runtime_error(),
            "rphonetic could not process this input or rule configuration",
        ))
    })
}

fn mapping(value: String) -> Result<[char; 26], Error> {
    value
        .chars()
        .collect::<Vec<_>>()
        .try_into()
        .map_err(|_| argument_error("mapping must contain exactly 26 characters (A through Z)"))
}

impl NativeEncoder {
    fn simple(name: String) -> Result<Self, Error> {
        let encoder: Box<dyn Encoder + Send> = match name.as_str() {
            "Caverphone1" => Box::new(Caverphone1),
            "Caverphone2" => Box::new(Caverphone2),
            "Cologne" => Box::new(Cologne),
            "MatchRatingApproach" => Box::new(MatchRatingApproach),
            _ => return Err(argument_error("unknown algorithm")),
        };
        Ok(Self(Algorithm::Simple(encoder)))
    }

    fn metaphone(length: Option<usize>) -> Self {
        Self(Algorithm::Simple(Box::new(Metaphone::new(length))))
    }

    fn double_metaphone(length: Option<usize>) -> Self {
        Self(Algorithm::Double(DoubleMetaphone::new(length)))
    }

    fn nysiis(strict: bool) -> Self {
        Self(Algorithm::Simple(Box::new(Nysiis::new(strict))))
    }

    fn phonex(length: usize) -> Self {
        Self(Algorithm::Simple(Box::new(Phonex::new(length))))
    }

    fn soundex(value: String, special_case_h_w: bool) -> Result<Self, Error> {
        Ok(Self(Algorithm::Soundex(Soundex::new(
            mapping(value)?,
            special_case_h_w,
        ))))
    }

    fn refined_soundex(value: String) -> Result<Self, Error> {
        Ok(Self(Algorithm::Refined(RefinedSoundex::new(mapping(
            value,
        )?))))
    }

    fn daitch_mokotoff(rules: String, folding: bool) -> Result<Self, Error> {
        checked(|| {
            DaitchMokotoffSoundexBuilder::with_rules(&rules)
                .ascii_folding(folding)
                .build()
                .map(|encoder| Self(Algorithm::Daitch(encoder)))
                .map_err(rule_error)
        })
    }

    fn beider_morse(
        path: String,
        name: String,
        rule: String,
        concat: bool,
        max: usize,
    ) -> Result<Self, Error> {
        let name_type = match name.as_str() {
            "generic" => NameType::Generic,
            "ashkenazi" => NameType::Ashkenazi,
            "sephardic" => NameType::Sephardic,
            _ => {
                return Err(argument_error(
                    "name_type must be :generic, :ashkenazi, or :sephardic",
                ))
            }
        };
        let rule_type = match rule.as_str() {
            "approx" => RuleType::Approx,
            "exact" => RuleType::Exact,
            _ => return Err(argument_error("rule_type must be :approx or :exact")),
        };
        checked(|| {
            let files = ConfigFiles::new(&PathBuf::from(path)).map_err(rule_error)?;
            Ok(Self(Algorithm::Beider(Box::new(BeiderConfig {
                files,
                name_type,
                rule_type,
                concat,
                max_phonemes: max,
            }))))
        })
    }

    fn validate(&self, value: &str) -> Result<(), Error> {
        // These upstream implementations index fixed A-Z mapping arrays.
        if matches!(self.0, Algorithm::Soundex(_) | Algorithm::Refined(_)) && !value.is_ascii() {
            return Err(argument_error(
                "Soundex and RefinedSoundex require ASCII input; transliterate the name first",
            ));
        }
        Ok(())
    }

    fn with_encoder<T>(&self, f: impl FnOnce(&dyn Encoder) -> T) -> T {
        match &self.0 {
            Algorithm::Simple(encoder) => f(encoder.as_ref()),
            Algorithm::Double(encoder) => f(encoder),
            Algorithm::Soundex(encoder) => f(encoder),
            Algorithm::Refined(encoder) => f(encoder),
            Algorithm::Daitch(encoder) => f(encoder),
            Algorithm::Beider(config) => f(&config.builder().build()),
        }
    }

    fn encode(&self, value: String) -> Result<String, Error> {
        self.validate(&value)?;
        checked(|| Ok(self.with_encoder(|encoder| encoder.encode(&value))))
    }

    fn encode_many(&self, values: Vec<String>) -> Result<Vec<String>, Error> {
        for value in &values {
            self.validate(value)?;
        }
        checked(|| {
            Ok(self
                .with_encoder(|encoder| values.iter().map(|value| encoder.encode(value)).collect()))
        })
    }

    fn matches(&self, first: String, second: String) -> Result<bool, Error> {
        self.validate(&first)?;
        self.validate(&second)?;
        checked(|| Ok(self.with_encoder(|encoder| encoder.is_encoded_equals(&first, &second))))
    }

    fn codes(&self, value: String) -> Result<Vec<String>, Error> {
        checked(|| match &self.0 {
            Algorithm::Double(encoder) => {
                let result = encoder.double_metaphone(&value);
                Ok(vec![result.primary(), result.alternate()])
            }
            Algorithm::Daitch(encoder) => Ok(encoder.inner_soundex(&value, true)),
            _ => Err(argument_error(
                "this encoder does not expose multiple codes",
            )),
        })
    }

    fn difference(&self, first: String, second: String) -> Result<usize, Error> {
        self.validate(&first)?;
        self.validate(&second)?;
        checked(|| match &self.0 {
            Algorithm::Soundex(encoder) => Ok(encoder.difference(&first, &second)),
            Algorithm::Refined(encoder) => Ok(encoder.difference(&first, &second)),
            _ => Err(argument_error("difference requires a Soundex encoder")),
        })
    }

    fn encode_languages(&self, value: String, languages: Vec<String>) -> Result<String, Error> {
        let selected = if languages == ["any"] {
            LanguageSet::Any
        } else {
            LanguageSet::SomeLanguages(languages.into_iter().collect())
        };
        checked(|| match &self.0 {
            Algorithm::Beider(config) => Ok(config
                .builder()
                .build()
                .encode_with_languages(&value, &selected)),
            _ => Err(argument_error("languages requires BeiderMorse")),
        })
    }
}

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("RPhonetic")?;
    let class = module.define_class("NativeEncoder", ruby.class_object())?;
    class.define_singleton_method("simple", function!(NativeEncoder::simple, 1))?;
    class.define_singleton_method("metaphone", function!(NativeEncoder::metaphone, 1))?;
    class.define_singleton_method(
        "double_metaphone",
        function!(NativeEncoder::double_metaphone, 1),
    )?;
    class.define_singleton_method("nysiis", function!(NativeEncoder::nysiis, 1))?;
    class.define_singleton_method("phonex", function!(NativeEncoder::phonex, 1))?;
    class.define_singleton_method("soundex", function!(NativeEncoder::soundex, 2))?;
    class.define_singleton_method(
        "refined_soundex",
        function!(NativeEncoder::refined_soundex, 1),
    )?;
    class.define_singleton_method(
        "daitch_mokotoff",
        function!(NativeEncoder::daitch_mokotoff, 2),
    )?;
    class.define_singleton_method("beider_morse", function!(NativeEncoder::beider_morse, 5))?;
    class.define_method("encode", method!(NativeEncoder::encode, 1))?;
    class.define_method("encode_many", method!(NativeEncoder::encode_many, 1))?;
    class.define_method("matches", method!(NativeEncoder::matches, 2))?;
    class.define_method("codes", method!(NativeEncoder::codes, 1))?;
    class.define_method("difference", method!(NativeEncoder::difference, 2))?;
    class.define_method(
        "encode_languages",
        method!(NativeEncoder::encode_languages, 2),
    )?;
    Ok(())
}
