# Base validator interface and common functionality

require "./errors"

module Validation
  # Abstract base class for all validators
  abstract class Validator(T)
    # Validates a value and returns the validated value or raises ValidationError
    abstract def validate(value : T, field : String) : T

    # Validates a value and returns a tuple of {valid?, error_message}
    def validate_safe(value : T, field : String) : {Bool, String?}
      begin
        validate(value, field)
        {true, nil}
      rescue ex : ValidationError
        {false, ex.message}
      end
    end

    # Checks if a value is valid without raising exceptions
    def valid?(value : T, field : String) : Bool
      valid, _ = validate_safe(value, field)
      valid
    end
  end

  # Validator that combines multiple validators
  class CompositeValidator(T) < Validator(T)
    getter validators : Array(Validator(T))

    def initialize(@validators : Array(Validator(T)))
    end

    def validate(value : T, field : String) : T
      @validators.each do |validator|
        value = validator.validate(value, field)
      end
      value
    end

    def add_validator(validator : Validator(T)) : Nil
      @validators << validator
    end
  end

  # Validator that applies a custom validation function
  class CustomValidator(T) < Validator(T)
    def initialize(@validation_proc : Proc(T, String, T), @error_message : String? = nil)
    end

    def validate(value : T, field : String) : T
      begin
        @validation_proc.call(value, field)
      rescue ex : Exception
        message = @error_message || ex.message || "validation failed"
        raise ValidationError.new(field, value.to_s, message)
      end
    end
  end
end