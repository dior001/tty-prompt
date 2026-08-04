# frozen_string_literal: true

require_relative "const"
require_relative "converter_dsl"

module TTY
  class Prompt
    # The built-in type converters (:bool, :int, :date, :range, ...) used
    # to coerce raw string input into the value type requested via the
    # `:convert` option.
    #
    # @api private
    module Converters
      extend ConverterDSL

      TRUE_VALUES = /^(t(rue)?|y(es)?|on|1)$/i
      FALSE_VALUES = /^(f(alse)?|n(o)?|off|0)$/i

      SINGLE_DIGIT_MATCHER = /^(?<digit>-?\d+(?:\.\d+)?)$/
      DIGIT_MATCHER = /^(?<open>-?\d+(?:\.\d+)?)
                       \s*(?<sep>(?:\.\s*){2,3}|-|,)\s*
                       (?<close>-?\d+(?:\.\d+)?)$
                      /x
      LETTER_MATCHER = /^(?<open>\w)
                        \s*(?<sep>(?:\.\s*){2,3}|-|,)\s*
                        (?<close>\w)$
                       /x

      converter(:boolean, :bool) do |input|
        case input.to_s
        when TRUE_VALUES then true
        when FALSE_VALUES then false
        else Const::Undefined
        end
      end

      converter(:string, :str) do |input|
        String(input).chomp
      end

      converter(:symbol, :sym, &:to_sym)

      converter(:char) do |input|
        String(input).chars.to_a[0]
      end

      converter(:date) do |input|
        require "date" unless defined?(::Date)
        ::Date.parse(input)
      rescue ArgumentError
        Const::Undefined
      end

      converter(:datetime) do |input|
        require "date" unless defined?(::Date)
        ::DateTime.parse(input.to_s)
      rescue ArgumentError
        Const::Undefined
      end

      converter(:time) do |input|
        require "time"
        ::Time.parse(input.to_s)
      rescue ArgumentError
        Const::Undefined
      end

      converter(:integer, :int) do |input|
        Integer(input)
      rescue ArgumentError
        Const::Undefined
      end

      converter(:float) do |input|
        Float(input)
      rescue TypeError, ArgumentError
        Const::Undefined
      end

      # Convert string number to integer or float
      #
      # @return [Integer,Float,Const::Undefined]
      #
      # @api private
      def cast_to_num(num)
        ([convert(:int, num),
          convert(:float, num)] - [Const::Undefined]).first ||
          Const::Undefined
      end
      module_function :cast_to_num

      converter(:range) do |input|
        if input.is_a?(::Range)
          input
        elsif match = input.to_s.match(SINGLE_DIGIT_MATCHER)
          digit = cast_to_num(match[:digit])
          ::Range.new(digit, digit)
        elsif match = input.to_s.match(DIGIT_MATCHER)
          open = cast_to_num(match[:open])
          close = cast_to_num(match[:close])
          ::Range.new(open, close, match[:sep].gsub(/\s*/, "") == "...")
        elsif match = input.to_s.match(LETTER_MATCHER)
          ::Range.new(match[:open], match[:close],
                      match[:sep].gsub(/\s*/, "") == "...")
        else
          Const::Undefined
        end
      end

      converter(:regexp) do |input|
        Regexp.new(input)
      end

      converter(:filepath, :file) do |input|
        ::File.expand_path(input)
      end

      converter(:pathname, :path) do |input|
        require "pathname" unless defined?(::Pathname)
        ::Pathname.new(input)
      end

      converter(:uri) do |input|
        require "uri" unless defined?(::URI)
        ::URI.parse(input)
      end

      converter(:list, :array) do |val|
        (val.respond_to?(:to_a) ? val : val.split(/(?<!\\),/))
          .map { |v| v.strip.gsub("\\,", ",") }
          .reject(&:empty?)
      end

      converter(:hash, :map) do |val|
        values = val.respond_to?(:to_a) ? val : val.split(/[& ]/)
        values.each_with_object({}) do |pair, pairs|
          key, value = pair.split(/[=:]/, 2)
          pairs[key.to_sym] = if (current = pairs[key.to_sym])
                                Array(current) << value
                              else
                                value
                              end
          pairs
        end
      end

      # `.keys` takes a snapshot since the loop body registers new
      # converters, which would otherwise mutate the registry mid-iteration.
      converter_registry.keys.each do |type| # rubocop:disable Style/HashEachMethods
        next if type =~ /list|array|map|hash/

        [:"#{type}_list", :"#{type}_array", :"#{type}s"].each do |new_type|
          converter(new_type) do |val|
            converter_registry[:array].(val).map do |obj|
              converter_registry[type].(obj)
            end
          end
        end

        [:"#{type}_map", :"#{type}_hash"].each do |new_type|
          converter(new_type) do |val|
            converter_registry[:hash].(val).each_with_object({}) do |(k, v), h|
              h[k] = converter_registry[type].(v)
            end
          end
        end

        [:"string_#{type}_map", :"str_#{type}_map",
         :"string_#{type}_hash", :"str_#{type}_hash"].each do |new_type|
          converter(new_type) do |val|
            converter_registry[:hash].(val).each_with_object({}) do |(k, v), h|
              h[converter_registry[:string].(k)] = converter_registry[type].(v)
            end
          end
        end
      end
    end # Converters
  end # Prompt
end # TTY
