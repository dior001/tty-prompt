# frozen_string_literal: true

module TTY
  class Prompt
    class Error < StandardError
    end

    # Raised when wrong parameter is used to configure prompt
    class ConfigurationError < Error
    end

    # Raised when type conversion cannot be performed
    class ConversionError < Error
    end

    # Raised when the passed in validation argument is of wrong type
    class ValidationCoercion < Error
    end

    # Raised when the required argument is not supplied
    class ArgumentRequired < Error
    end

    # Raised when the argument validation fails
    class ArgumentValidation < Error
    end

    # Raised when the argument is not expected
    class InvalidArgument < Error
    end

    # Raised when overriding already defined conversion
    class ConversionAlreadyDefined < Error
    end

    # Raised when conversion type isn't registered
    class UnsupportedConversion < Error
    end
  end # Prompt
end # TTY
