# frozen_string_literal: true

require_relative "question"
require_relative "utils"

module TTY
  class Prompt
    # A yes/no question used by {Prompt#yes?} and {Prompt#no?}.
    #
    # @api private
    class ConfirmQuestion < Question
      # Create confirmation question
      #
      # @param [Hash] options
      # @option options [String] :suffix
      # @option options [String] :positive
      # @option options [String] :negative
      #
      # @api public
      def initialize(prompt, **options)
        super
        @suffix   = options.fetch(:suffix)   { UndefinedSetting }
        @positive = options.fetch(:positive) { UndefinedSetting }
        @negative = options.fetch(:negative) { UndefinedSetting }
      end

      # Check if a custom positive label is configured
      #
      # @return [Boolean]
      #
      # @api public
      def positive?
        @positive != UndefinedSetting
      end

      # Check if a custom negative label is configured
      #
      # @return [Boolean]
      #
      # @api public
      def negative?
        @negative != UndefinedSetting
      end

      # Check if a custom suffix is configured
      #
      # @return [Boolean]
      #
      # @api public
      def suffix?
        @suffix != UndefinedSetting
      end

      # Set question suffix
      #
      # @api public
      def suffix(value = (not_set = true))
        return @negative if not_set

        @suffix = value
      end

      # Set value for matching positive choice
      #
      # @api public
      def positive(value = (not_set = true))
        return @positive if not_set

        @positive = value
      end

      # Set value for matching negative choice
      #
      # @api public
      def negative(value = (not_set = true))
        return @negative if not_set

        @negative = value
      end

      # Call the question
      #
      # @param [String] message
      #
      # @return [Boolean]
      #
      # @api public
      def call(message, &block)
        return if Utils.blank?(message)

        @message = message
        block&.(self)
        setup_defaults
        render
      end

      # Render confirmation question
      #
      # @return [String]
      #
      # @api private
      def render_question
        header = "#{@prefix}#{message} "
        if @done
          answer = conversion.(@input)
          label  = answer ? @positive : @negative
          header += @prompt.decorate(label, @active_color)
        else
          header += "#{@prompt.decorate("(#{@suffix})", @help_color)} "
        end
        header << "\n" if @done
        header
      end

      protected

      # Decide how to handle input from user
      #
      # @api private
      def process_input(question)
        @input = read_input(question)
        if Utils.blank?(@input)
          @input = default ? positive : negative
        end
        @evaluator.(@input)
      end

      # @api private
      def setup_defaults
        infer_default
        @convert = conversion
        return if suffix? && positive?

        if suffix? && (!positive? || !negative?)
          parts = @suffix.split("/")
          @positive = parts[0]
          @negative = parts[1]
        elsif !suffix? && positive?
          @suffix = create_suffix
        else
          create_default_labels
        end
      end

      # @api private
      def infer_default
        converted = Converters.convert(:bool, default.to_s)
        if converted == Const::Undefined
          raise InvalidArgument, "default needs to be `true` or `false`"
        end

        default(converted)
      end

      # @api private
      def create_default_labels
        @suffix   = default ? "Y/n" : "y/N"
        @positive = default ? "Yes" : "yes"
        @negative = default ? "no" : "No"
        @validation = /^(y(es)?|no?)$/i
        @messages[:valid?] = "Invalid input."
      end

      # @api private
      def create_suffix
        pos = default ? positive.capitalize : positive.downcase
        neg = default ? negative.downcase : negative.capitalize
        "#{pos}/#{neg}"
      end

      # Create custom conversion
      #
      # @api private
      def conversion
        lambda do |input|
          positive_word   = Regexp.escape(positive)
          positive_letter = Regexp.escape(positive[0])
          pattern = Regexp.new("^(#{positive_word}|#{positive_letter})$", true)
          !input.match(pattern).nil?
        end
      end
    end # ConfirmQuestion
  end # Prompt
end # TTY
