# Base field class with common functionality

require "../validator"
require "../errors"

module Validation::Fields
  # Abstract base class for all field types
  abstract class BaseField(T)
    getter validators : Array(Validator(T))
    getter default : T?
    getter required : Bool
    getter description : String?

    def initialize(@default : T? = nil,
                   @required : Bool = true,
                   @validators : Array(Validator(T)) = [] of Validator(T),
                   @description : String? = nil)
    end

    # Validates a value using all configured validators
    def validate(value : T?, field_name : String) : T?
      # Handle nil values
      if value.nil?
        return handle_nil_value(field_name)
      end

      # Apply all validators
      validated_value = value
      @validators.each do |validator|
        validated_value = validator.validate(validated_value, field_name)
      end

      validated_value
    end

    # Checks if a value is valid without raising exceptions
    def valid?(value : T?, field_name : String) : Bool
      begin
        validate(value, field_name)
        true
      rescue ValidationError
        false
      end
    end

    # Adds a validator to this field
    def add_validator(validator : Validator(T)) : Nil
      @validators << validator
    end

    # Removes all validators
    def clear_validators : Nil
      @validators.clear
    end

    # Gets the effective value (actual value or default)
    def effective_value(value : T?) : T?
      value.nil? ? @default : value
    end

    private def handle_nil_value(field_name : String) : T?
      if @required && @default.nil?
        raise ValidationError.new(field_name, "nil", "field is required")
      end
      @default
    end
  end

  # Helper methods for creating validators
  module ValidatorHelpers
    def self.create_validator_from_options(type : T.class, **options) : Array(Validator(T)) forall T
      validators = [] of Validator(T)

      # This would be implemented based on the specific type
      # Subclasses will override this with type-specific logic
      validators
    end
  end
end
