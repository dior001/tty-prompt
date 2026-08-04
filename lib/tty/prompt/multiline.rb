# frozen_string_literal: true

require_relative "question"
require_relative "symbols"

module TTY
  class Prompt
    # A prompt responsible for multi line user input
    #
    # @api private
    class Multiline < Question
      HELP = "(Press Ctrl+D or Ctrl+Z to finish)"

      # Create a Multiline question
      #
      # @param [Prompt] prompt
      #   the prompt
      # @param [Hash] options
      #
      # @api public
      def initialize(prompt, **options)
        super
        @help         = options[:help] || self.class::HELP
        @first_render = true
        @lines_count  = 0
      end

      # Provide help information
      #
      # @return [String]
      #
      # @api public
      def help(value = (not_set = true))
        return @help if not_set

        @help = value
      end

      # Read multiline input from the user
      #
      # @return [Array[String]]
      #
      # @api private
      def read_input
        @prompt.read_multiline
      end

      # Handle the enter/return key by tracking the number of lines
      # entered
      #
      # @api private
      def keyreturn(*)
        @lines_count += 1
      end
      alias keyenter keyreturn

      # Render question
      #
      # @return [String]
      #
      # @api private
      def render_question
        header = ["#{@prefix}#{message} "]
        if echo?
          if @done
            header << @prompt.decorate(@input.to_s, @active_color)
          elsif @first_render
            header << @prompt.decorate(help, @help_color)
            @first_render = false
          end
        end
        header << "\n"
        header.join
      end

      # Decide how to handle input from user
      #
      # @api private
      def process_input(question)
        @prompt.print(question)
        @lines = read_input
        @input = "#{@lines.first.strip} ..." unless @lines.first.to_s.empty?
        if Utils.blank?(@input) && default?
          @input = default
          @lines = default
        end
        @evaluator.(@lines)
      end

      # Determine area of the screen to clear
      #
      # @param [Integer] lines_to_clear
      #   number of lines to clear
      #
      # @return [String]
      #
      # @api private
      def refresh(_lines, lines_to_clear)
        size = @lines_count + lines_to_clear + 1
        @prompt.clear_lines(size)
      end
    end # Multiline
  end # Prompt
end # TTY
