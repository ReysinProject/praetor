# Validators for numeric types (Int, Float, etc.)

require "../validator"

module Validation::Validators
  # Validates that a numeric value is greater than or equal to a minimum
  class MinValidator(T) < Validator(T)
    getter min : T

    def initialize(@min : T)
    end

    def validate(value : T, field : String) : T
      if value < @min
        raise ValidationError.new(field, value.to_s, "must be >= #{@min}")
      end
      value
    end
  end

  # Validates that a numeric value is less than or equal to a maximum
  class MaxValidator(T) < Validator(T)
    getter max : T

    def initialize(@max : T)
    end

    def validate(value : T, field : String) : T
      if value > @max
        raise ValidationError.new(field, value.to_s, "must be <= #{@max}")
      end
      value
    end
  end

  # Validates that a numeric value is within a specific range
  class RangeValidator(T) < Validator(T)
    getter min : T
    getter max : T

    def initialize(@min : T, @max : T)
      if @min > @max
        raise ArgumentError.new("min value (#{@min}) cannot be greater than max value (#{@max})")
      end
    end

    def validate(value : T, field : String) : T
      if value < @min || value > @max
        raise ValidationError.new(field, value.to_s, "must be between #{@min} and #{@max}")
      end
      value
    end
  end

  # Validates that a numeric value is positive
  class PositiveValidator(T) < Validator(T)
    def validate(value : T, field : String) : T
      if value <= 0
        raise ValidationError.new(field, value.to_s, "must be positive")
      end
      value
    end
  end

  # Validates that a numeric value is negative
  class NegativeValidator(T) < Validator(T)
    def validate(value : T, field : String) : T
      if value >= 0
        raise ValidationError.new(field, value.to_s, "must be negative")
      end
      value
    end
  end

  # Validates that a numeric value is even
  class EvenValidator < Validator(Int32)
    def validate(value : Int32, field : String) : Int32
      if value.odd?
        raise ValidationError.new(field, value.to_s, "must be even")
      end
      value
    end
  end

  # Validates that a numeric value is odd
  class OddValidator < Validator(Int32)
    def validate(value : Int32, field : String) : Int32
      if value.even?
        raise ValidationError.new(field, value.to_s, "must be odd")
      end
      value
    end
  end
end