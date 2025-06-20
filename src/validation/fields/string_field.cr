# String field with string-specific validators

require "./base_field"
require "../validators/string"
require "../validators/email"

module Validation::Fields
  # Specialized field for string values with string-specific validators
  class StringField < BaseField(String)
    def initialize(default : String? = nil,
                   required : Bool = true,
                   validators : Array(Validator(String)) = [] of Validator(String),
                   description : String? = nil,
                   **options)
      # Create validators from options
      computed_validators = create_validators_from_options(**options)
      all_validators = validators + computed_validators

      super(default, required, all_validators, description)
    end

    # Factory method with string-specific options
    def self.new(default : String? = nil,
                 required : Bool = true,
                 description : String? = nil,
                 min_length : Int32? = nil,
                 max_length : Int32? = nil,
                 pattern : Regex? = nil,
                 email : Bool? = nil,
                 not_blank : Bool? = nil,
                 alpha : Bool? = nil,
                 alphanumeric : Bool? = nil,
                 allow_spaces : Bool? = nil,
                 choices : Array(String)? = nil,
                 strict_email : Bool? = nil) : StringField
      validators = [] of Validator(String)

      # Length validators
      if min_length && max_length
        validators << Validators::LengthRangeValidator.new(min_length, max_length)
      else
        validators << Validators::MinLengthValidator.new(min_length) if min_length
        validators << Validators::MaxLengthValidator.new(max_length) if max_length
      end

      # Pattern validator
      validators << Validators::RegexValidator.new(pattern) if pattern

      # Email validators
      if email == true
        validators << Validators::EmailValidator.new
      elsif strict_email == true
        validators << Validators::StrictEmailValidator.new
      end

      # Content validators
      validators << Validators::NotBlankValidator.new if not_blank == true

      if alpha == true
        allow_spaces_val = allow_spaces == true
        validators << Validators::AlphaValidator.new(allow_spaces_val)
      elsif alphanumeric == true
        allow_spaces_val = allow_spaces == true
        validators << Validators::AlphanumericValidator.new(allow_spaces_val)
      end

      # Choice validator
      validators << Validators::ChoiceValidator.new(choices) if choices

      new(default, required, validators, description)
    end

    private def create_validators_from_options(**options) : Array(Validator(String))
      validators = [] of Validator(String)

      # Length validators
      if min_length = options[:min_length]?
        validators << Validators::MinLengthValidator.new(min_length.as(Int32))
      end

      if max_length = options[:max_length]?
        validators << Validators::MaxLengthValidator.new(max_length.as(Int32))
      end

      if pattern = options[:pattern]?
        validators << Validators::RegexValidator.new(pattern.as(Regex))
      end

      if options[:email]? == true
        validators << Validators::EmailValidator.new
      end

      if options[:strict_email]? == true
        validators << Validators::StrictEmailValidator.new
      end

      if options[:not_blank]? == true
        validators << Validators::NotBlankValidator.new
      end

      if options[:alpha]? == true
        allow_spaces = options[:allow_spaces]? == true
        validators << Validators::AlphaValidator.new(allow_spaces)
      end

      if options[:alphanumeric]? == true
        allow_spaces = options[:allow_spaces]? == true
        validators << Validators::AlphanumericValidator.new(allow_spaces)
      end

      if choices = options[:choices]?
        validators << Validators::ChoiceValidator.new(choices.as(Array(String)))
      end

      validators
    end
  end

  # Convenience methods for creating common string fields
  module StringFieldFactory
    def self.email_field(default : String? = nil,
                         required : Bool = true,
                         strict : Bool = false,
                         description : String? = nil) : StringField
      if strict
        StringField.new(default: default, required: required, description: description, strict_email: true)
      else
        StringField.new(default: default, required: required, description: description, email: true)
      end
    end

    def self.password_field(default : String? = nil,
                            required : Bool = true,
                            min_length : Int32 = 8,
                            max_length : Int32? = nil,
                            description : String? = nil) : StringField
      StringField.new(
        default: default,
        required: required,
        description: description,
        min_length: min_length,
        max_length: max_length,
        not_blank: true
      )
    end

    def self.name_field(default : String? = nil,
                        required : Bool = true,
                        min_length : Int32? = 1,
                        max_length : Int32? = 100,
                        description : String? = nil) : StringField
      StringField.new(
        default: default,
        required: required,
        description: description,
        min_length: min_length,
        max_length: max_length,
        alpha: true,
        allow_spaces: true,
        not_blank: true
      )
    end

    def self.username_field(default : String? = nil,
                            required : Bool = true,
                            min_length : Int32 = 3,
                            max_length : Int32 = 30,
                            description : String? = nil) : StringField
      StringField.new(
        default: default,
        required: required,
        description: description,
        min_length: min_length,
        max_length: max_length,
        alphanumeric: true,
        not_blank: true
      )
    end

    def self.choice_field(choices : Array(String),
                          default : String? = nil,
                          required : Bool = true,
                          description : String? = nil) : StringField
      StringField.new(
        default: default,
        required: required,
        description: description,
        choices: choices
      )
    end
  end
end
