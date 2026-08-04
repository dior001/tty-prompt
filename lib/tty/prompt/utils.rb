# frozen_string_literal: true

module TTY
  # A collection of small helper functions shared across TTY::Prompt
  # classes, e.g. option extraction and blank checks.
  #
  # @api private
  module Utils
    module_function

    BLANK_REGEX = /\A[[:space:]]*\z/o

    # Extract options hash from array argument
    #
    # @param [Array[Object]] args
    #
    # @api public
    def extract_options(args)
      options = args.last
      options.respond_to?(:to_hash) ? options.to_hash.dup : {}
    end

    # Extract and remove options hash from array argument, mutating args
    #
    # @param [Array[Object]] args
    #
    # @return [Hash]
    #
    # @api public
    def extract_options!(args)
      args.last.respond_to?(:to_hash) ? args.pop : {}
    end

    # Check if value is nil or an empty string
    #
    # @param [Object] value
    #   the value to check
    #
    # @return [Boolean]
    #
    # @api public
    def blank?(value)
      value.nil? || BLANK_REGEX === value
    end

    # Deep copy object
    #
    # @api public
    def deep_copy(object)
      Marshal.load(Marshal.dump(object))
    end
  end # Utils
end # TTY
