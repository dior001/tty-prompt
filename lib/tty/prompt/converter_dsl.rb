# frozen_string_literal: true

require_relative "converter_registry"

module TTY
  class Prompt
    # A mixin providing a per-class registry of type converters, used to
    # define and invoke conversions such as :int, :bool or :date.
    #
    # @api private
    module ConverterDSL
      # The memoized registry of converters for the extending class
      #
      # @return [ConverterRegistry]
      #
      # @api private
      def converter_registry
        @converter_registry ||= ConverterRegistry.new
      end

      # Register a new named converter
      #
      # @param [Array<Symbol>] names
      #   the converter names to register, e.g. :int, :integer
      #
      # @api public
      def converter(*names, &)
        converter_registry.register(*names, &)
      end

      # Convert an input value using a registered converter
      #
      # @param [Symbol] name
      #   the registered converter name
      # @param [Object] input
      #   the value to convert
      #
      # @api public
      def convert(name, input)
        converter_registry[name].(input)
      end
    end # ConverterDSL
  end # Prompt
end # TTY
