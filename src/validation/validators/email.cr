# Email validation functionality

require "./string"

module Validation::Validators
  # Validates email address format
  class EmailValidator < RegexValidator
    # Basic email regex pattern
    EMAIL_PATTERN = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/

    def initialize(custom_pattern : Regex? = nil, custom_message : String? = nil)
      pattern = custom_pattern || EMAIL_PATTERN
      message = custom_message || "must be a valid email address"
      super(pattern, message)
    end
  end

  # More strict email validator with additional checks
  class StrictEmailValidator < Validator(String)
    EMAIL_PATTERN = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/

    def initialize(@max_length : Int32 = 254)
    end

    def validate(value : String, field : String) : String
      # Check length (RFC 5321 limit)
      if value.size > @max_length
        raise ValidationError.new(field, value, "email address too long (max #{@max_length} characters)")
      end

      # Check basic format
      unless EMAIL_PATTERN.matches?(value)
        raise ValidationError.new(field, value, "must be a valid email address")
      end

      # Split into local and domain parts
      parts = value.split('@')
      if parts.size != 2
        raise ValidationError.new(field, value, "must contain exactly one @ symbol")
      end

      local_part, domain_part = parts

      # Validate local part
      validate_local_part(local_part, field, value)

      # Validate domain part
      validate_domain_part(domain_part, field, value)

      value
    end

    private def validate_local_part(local_part : String, field : String, full_email : String) : Nil
      if local_part.empty?
        raise ValidationError.new(field, full_email, "local part cannot be empty")
      end

      if local_part.size > 64
        raise ValidationError.new(field, full_email, "local part too long (max 64 characters)")
      end

      # Check for consecutive dots
      if local_part.includes?("..")
        raise ValidationError.new(field, full_email, "local part cannot contain consecutive dots")
      end

      # Check for dots at start/end
      if local_part.starts_with?('.') || local_part.ends_with?('.')
        raise ValidationError.new(field, full_email, "local part cannot start or end with a dot")
      end
    end

    private def validate_domain_part(domain_part : String, field : String, full_email : String) : Nil
      if domain_part.empty?
        raise ValidationError.new(field, full_email, "domain part cannot be empty")
      end

      if domain_part.size > 253
        raise ValidationError.new(field, full_email, "domain part too long (max 253 characters)")
      end

      # Check for valid domain format
      unless /^[a-zA-Z0-9.-]+$/.matches?(domain_part)
        raise ValidationError.new(field, full_email, "domain contains invalid characters")
      end

      # Check for consecutive dots
      if domain_part.includes?("..")
        raise ValidationError.new(field, full_email, "domain cannot contain consecutive dots")
      end

      # Check for dots at start/end
      if domain_part.starts_with?('.') || domain_part.ends_with?('.')
        raise ValidationError.new(field, full_email, "domain cannot start or end with a dot")
      end

      # Must have at least one dot for TLD
      unless domain_part.includes?('.')
        raise ValidationError.new(field, full_email, "domain must include a top-level domain")
      end
    end
  end
end
