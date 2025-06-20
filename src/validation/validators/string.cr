# Validators specific to string types

require "../validator"

module Validation::Validators
  # Validates minimum string length
  class MinLengthValidator < Validator(String)
    getter min_length : Int32

    def initialize(@min_length : Int32)
      if @min_length < 0
        raise ArgumentError.new("min_length cannot be negative")
      end
    end

    def validate(value : String, field : String) : String
      if value.size < @min_length
        raise ValidationError.new(field, value, "must have at least #{@min_length} characters")
      end
      value
    end
  end

  # Validates maximum string length
  class MaxLengthValidator < Validator(String)
    getter max_length : Int32

    def initialize(@max_length : Int32)
      if @max_length < 0
        raise ArgumentError.new("max_length cannot be negative")
      end
    end

    def validate(value : String, field : String) : String
      if value.size > @max_length
        raise ValidationError.new(field, value, "must have at most #{@max_length} characters")
      end
      value
    end
  end

  # Validates string length within a range
  class LengthRangeValidator < Validator(String)
    getter min_length : Int32
    getter max_length : Int32

    def initialize(@min_length : Int32, @max_length : Int32)
      if @min_length < 0 || @max_length < 0
        raise ArgumentError.new("lengths cannot be negative")
      end
      if @min_length > @max_length
        raise ArgumentError.new("min_length cannot be greater than max_length")
      end
    end

    def validate(value : String, field : String) : String
      size = value.size
      if size < @min_length || size > @max_length
        raise ValidationError.new(field, value, "must have between #{@min_length} and #{@max_length} characters")
      end
      value
    end
  end

  # Validates string against a regular expression
  class RegexValidator < Validator(String)
    getter pattern : Regex
    getter message : String?

    def initialize(@pattern : Regex, @message : String? = nil)
    end

    def validate(value : String, field : String) : String
      unless @pattern.matches?(value)
        message = @message || "must match pattern #{@pattern.source}"
        raise ValidationError.new(field, value, message)
      end
      value
    end
  end

  # Validates that string is not empty/blank
  class NotBlankValidator < Validator(String)
    def validate(value : String, field : String) : String
      if value.blank?
        raise ValidationError.new(field, value, "cannot be blank")
      end
      value
    end
  end

  # Validates that string contains only alphanumeric characters
  class AlphanumericValidator < Validator(String)
    def initialize(@allow_spaces : Bool = false)
    end

    def validate(value : String, field : String) : String
      pattern = @allow_spaces ? /^[a-zA-Z0-9\s]+$/ : /^[a-zA-Z0-9]+$/
      unless pattern.matches?(value)
        message = @allow_spaces ? "must contain only letters, numbers, and spaces" : "must contain only letters and numbers"
        raise ValidationError.new(field, value, message)
      end
      value
    end
  end

  # Validates that string contains only alphabetic characters
  class AlphaValidator < Validator(String)
    def initialize(@allow_spaces : Bool = false)
    end

    def validate(value : String, field : String) : String
      pattern = @allow_spaces ? /^[a-zA-Z\s]+$/ : /^[a-zA-Z]+$/
      unless pattern.matches?(value)
        message = @allow_spaces ? "must contain only letters and spaces" : "must contain only letters"
        raise ValidationError.new(field, value, message)
      end
      value
    end
  end

  # Validates that string is one of the allowed choices
  class ChoiceValidator < Validator(String)
    getter choices : Array(String)

    def initialize(@choices : Array(String))
      if @choices.empty?
        raise ArgumentError.new("choices cannot be empty")
      end
    end

    def validate(value : String, field : String) : String
      unless @choices.includes?(value)
        raise ValidationError.new(field, value, "must be one of: #{@choices.join(", ")}")
      end
      value
    end
  end
end