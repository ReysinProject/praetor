require "./string_field"

module Validation::Fields
  # Specialized field for email strings
  class EmailField < StringField
    def initialize(
      default : String? = nil,
      required : Bool = true,
      strict : Bool = false,
      description : String? = nil,
    )
      super(
        default: default,
        required: required,
        description: description,
        strict_email: strict,
        email: !strict # fallback to basic if strict is false
      )
    end
  end
end
