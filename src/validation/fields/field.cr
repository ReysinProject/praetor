# src/validation/fields/field.cr
# Generic field implementation for basic types

require "./base_field"
require "../validators/numeric"

module Validation::Fields
  # Generic field that works with any type
  class Field(T) < BaseField(T)
    def initialize(default : T? = nil,
                   required : Bool = true,
                   validators : Array(Validator(T)) = [] of Validator(T),
                   description : String? = nil,
                   **options)
      # Create validators from options
      computed_validators = create_validators_from_options(**options)
      all_validators = validators + computed_validators

      super(default, required, all_validators, description)
    end

    # Factory method with options for common validations
    def self.new(default : T? = nil,
                 required : Bool = true,
                 description : String? = nil,
                 **options) : Field(T)
      validators = create_validators_from_options(**options)
      new(default, required, validators, description)
    end

    protected def self.create_validators_from_options(**options) : Array(Validator(T))
      validators = [] of Validator(T)

      # Numeric validators (works for Int32, Float64, etc.)
      {% if T <= Number %}
        if min = options[:min]?
          validators << Validators::MinValidator(T).new(min.as(T))
        end

        if max = options[:max]?
          validators << Validators::MaxValidator(T).new(max.as(T))
        end

        if options[:positive]? == true
          validators << Validators::PositiveValidator(T).new
        end

        if options[:negative]? == true
          validators << Validators::NegativeValidator(T).new
        end
      {% end %}

      # Integer-specific validators
      {% if T == Int32 %}
        if options[:even]? == true
          validators << Validators::EvenValidator.new
        end

        if options[:odd]? == true
          validators << Validators::OddValidator.new
        end
      {% end %}

      validators
    end

    private def create_validators_from_options(**options) : Array(Validator(T))
      self.class.create_validators_from_options(**options)
    end
  end

  # Convenience methods for creating common field types
  module FieldFactory
    def self.int_field(default : Int32? = nil,
                       required : Bool = true,
                       min : Int32? = nil,
                       max : Int32? = nil,
                       positive : Bool? = nil,
                       negative : Bool? = nil,
                       even : Bool? = nil,
                       odd : Bool? = nil,
                       description : String? = nil) : Field(Int32)
      Field(Int32).new(
        default: default,
        required: required,
        description: description,
        min: min,
        max: max,
        positive: positive,
        negative: negative,
        even: even,
        odd: odd
      )
    end

    def self.float_field(default : Float64? = nil,
                         required : Bool = true,
                         min : Float64? = nil,
                         max : Float64? = nil,
                         positive : Bool? = nil,
                         negative : Bool? = nil,
                         description : String? = nil) : Field(Float64)
      Field(Float64).new(
        default: default,
        required: required,
        description: description,
        min: min,
        max: max,
        positive: positive,
        negative: negative
      )
    end

    def self.bool_field(default : Bool? = nil,
                        required : Bool = true,
                        description : String? = nil) : Field(Bool)
      Field(Bool).new(
        default: default,
        required: required,
        description: description
      )
    end
  end
end
