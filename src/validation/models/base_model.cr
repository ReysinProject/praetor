# Base model class with validation capabilities

require "../fields/base_field"
require "../fields/field"
require "../fields/string_field"
require "../errors"

module Validation::Models
  # Base class for validated models
  abstract class BaseModel
    # Type alias for supported field types
    alias FieldType = Validation::Fields::Field(String) | Validation::Fields::Field(Int32) | Validation::Fields::Field(Float64) | Validation::Fields::Field(Bool) | Validation::Fields::StringField
    
    # Type alias for supported value types
    alias ValueType = String | Int32 | Float64 | Bool | Nil

    # Class-level field registry
    @@fields = {} of String => FieldType

    # Class method to register a field
    def self.register_field(name : String, field : FieldType) : Nil
      @@fields[name] = field
    end

    # Class method to get field definitions
    def self.fields : Hash(String, FieldType)
      @@fields
    end

    # Class method to get field names
    def self.field_names : Array(String)
      @@fields.keys
    end

    # Class method to check if a field exists
    def self.has_field?(name : String) : Bool
      @@fields.has_key?(name)
    end

    # Class method to get a specific field
    def self.get_field(name : String) : FieldType?
      @@fields[name]?
    end

    # Instance method to access class fields
    def fields : Hash(String, FieldType)
      self.class.fields
    end

    # Macro to define validated fields
    macro field(name, type, **options)
      # Register the field
      {% if type == String %}
        @@fields[{{name.stringify}}] = Validation::Fields::StringField.new(**{{options}})
      {% else %}
        @@fields[{{name.stringify}}] = Validation::Fields::Field({{type}}).new(**{{options}})
      {% end %}
      
      # Create instance variable
      @{{name.id}} : {{type}}?
      
      # Create getter
      def {{name.id}} : {{type}}?
        @{{name.id}}
      end
      
      # Create setter with validation
      def {{name.id}}=(value : {{type}}?)
        field_def = @@fields[{{name.stringify}}].as(Validation::Fields::Field({{type}}))
        validated_value = field_def.validate(value, {{name.stringify}})
        @{{name.id}} = validated_value
      end

      # Create getter that returns non-nil value or raises
      def {{name.id}}! : {{type}}
        value = @{{name.id}}
        if value.nil?
          raise ValidationError.new({{name.stringify}}, "nil", "field is nil")
        end
        value
      end
      
    end

    # Macro for string fields with additional options
    macro string_field(name, **options)
      @@fields[{{name.stringify}}] = Validation::Fields::StringField.new(**{{options}})
      
      @{{name.id}} : String?
      
      def {{name.id}} : String?
        @{{name.id}}
      end
      
      def {{name.id}}=(value : String?)
        field_def = @@fields[{{name.stringify}}].as(Validation::Fields::StringField)
        validated_value = field_def.validate(value, {{name.stringify}})
        @{{name.id}} = validated_value
      end

      def {{name.id}}! : String
        value = @{{name.id}}
        if value.nil?
          raise ValidationError.new({{name.stringify}}, "nil", "field is nil")
        end
        value
      end
    end

    # Initialize from hash
    def initialize(data : Hash(String, ValueType) = {} of String => ValueType)
      validate_and_assign(data)
    end

    # Initialize from named tuple
    def initialize(**data)
      hash_data = {} of String => ValueType
      data.each do |key, value|
        hash_data[key.to_s] = value.as(ValueType)
      end
      validate_and_assign(hash_data)
    end

    # Validate and assign values from hash
    private def validate_and_assign(data : Hash(String, ValueType)) : Nil
      errors = [] of ValidationError
      
      # Validate each field
      fields.each do |field_name, field_def|
        begin
          value = data[field_name]?
          validated_value = field_def.validate(value, field_name)
          
          # Set the instance variable dynamically
          set_instance_variable(field_name, validated_value)
        rescue ex : ValidationError
          errors << ex
        end
      end
      
      # Check for unknown fields
      data.each do |key, value|
        unless fields.has_key?(key)
          errors << ValidationError.new(key, value.to_s, "unknown field")
        end
      end
      
      # Raise validation errors if any
      unless errors.empty?
        raise ValidationErrors.new(errors)
      end
    end

    # Dynamically set instance variable
    private def set_instance_variable(field_name : String, value : ValueType) : Nil
      {% begin %}
        case field_name
        {% for ivar in @type.instance_vars %}
          when {{ivar.name.stringify}}
            @{{ivar.name}} = value.as({{ivar.type}})
        {% end %}
        else
          # This shouldn't happen if fields are properly registered
          raise ArgumentError.new("Unknown field: #{field_name}")
        end
      {% end %}
    end

    # Get instance variable value
    private def get_instance_variable(field_name : String) : ValueType
      {% begin %}
        case field_name
        {% for ivar in @type.instance_vars %}
          when {{ivar.name.stringify}}
            @{{ivar.name}}.as(ValueType)
        {% end %}
        else
          raise ArgumentError.new("Unknown field: #{field_name}")
        end
      {% end %}
    end

    # Convert to hash
    def to_h(include_nil : Bool = false) : Hash(String, ValueType)
      hash = {} of String => ValueType
      
      fields.each do |field_name, _|
        value = get_instance_variable(field_name)
        if include_nil || !value.nil?
          hash[field_name] = value
        end
      end
      
      hash
    end

    # Convert to hash with only non-nil values
    def to_h_compact : Hash(String, ValueType)
      to_h(include_nil: false)
    end

    # Update from hash
    def update(data : Hash(String, ValueType)) : Nil
      validate_and_assign(data)
    end

    # Update from named tuple
    def update(**data) : Nil
      hash_data = {} of String => ValueType
      data.each do |key, value|
        hash_data[key.to_s] = value.as(ValueType)
      end
      update(hash_data)
    end

    # Check if the model is valid
    def valid? : Bool
      begin
        validate!
        true
      rescue ValidationErrors
        false
      end
    end

    # Validate the current state
    def validate! : Nil
      current_data = to_h(include_nil: true)
      errors = [] of ValidationError
      
      fields.each do |field_name, field_def|
        begin
          value = current_data[field_name]?
          field_def.validate(value, field_name)
        rescue ex : ValidationError
          errors << ex
        end
      end
      
      unless errors.empty?
        raise ValidationErrors.new(errors)
      end
    end

    # Get validation errors without raising
    def validation_errors : Array(ValidationError)
      begin
        validate!
        [] of ValidationError
      rescue ex : ValidationErrors
        ex.errors
      end
    end

    # Check if a specific field is valid
    def field_valid?(field_name : String) : Bool
      return false unless fields.has_key?(field_name)
      
      begin
        field_def = fields[field_name]
        value = get_instance_variable(field_name)
        field_def.validate(value, field_name)
        true
      rescue ValidationError
        false
      end
    end

    # Get validation error for a specific field
    def field_error(field_name : String) : ValidationError?
      return nil unless fields.has_key?(field_name)
      
      begin
        field_def = fields[field_name]
        value = get_instance_variable(field_name)
        field_def.validate(value, field_name)
        nil
      rescue ex : ValidationError
        ex
      end
    end

    # String representation
    def to_s(io : IO) : Nil
      io << "#{self.class.name}("
      
      first = true
      fields.each do |field_name, _|
        unless first
          io << ", "
        end
        first = false
        
        value = get_instance_variable(field_name)
        io << "#{field_name}: #{value.inspect}"
      end
      
      io << ")"
    end

    def inspect(io : IO) : Nil
      to_s(io)
    end
  end
end