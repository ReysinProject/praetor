# Error classes for validation failures

module Validation
  # Single field validation error
  class ValidationError < Exception
    getter field : String
    getter value : String
    getter validation_message : String

    def initialize(@field : String, @value : String, @validation_message : String)
      super("#{@field}: #{@validation_message} (got: #{@value})")
    end

    def to_s(io : IO) : Nil
      io << "#{@field}: #{@validation_message} (got: #{@value})"
    end
  end

  # Collection of validation errors for multiple fields
  class ValidationErrors < Exception
    getter errors : Array(ValidationError)

    def initialize(@errors : Array(ValidationError))
      super(build_message)
    end

    def add_error(error : ValidationError) : Nil
      @errors << error
    end

    def empty? : Bool
      @errors.empty?
    end

    def size : Int32
      @errors.size
    end

    def each(&block : ValidationError -> _)
      @errors.each(&block)
    end

    private def build_message : String
      return "No validation errors" if @errors.empty?

      if @errors.size == 1
        @errors.first.validation_message
      else
        "#{@errors.size} validation errors: #{@errors.map(&.validation_message).join(", ")}"
      end
    end
  end
end
