# frozen_string_literal: true

require_relative "question"

module TTY
  class Prompt
    # A question whose input is echoed back as a masking character
    # instead of the typed value, e.g. for password prompts. Used by
    # {Prompt#mask}.
    #
    # @api private
    class MaskQuestion < Question
      # Names for delete keys
      DELETE_KEYS = %i[backspace delete].freeze

      # Create masked question
      #
      # @param [Hash] options
      # @option options [String] :mask
      #
      # @api public
      def initialize(prompt, **options)
        super
        @mask        = options.fetch(:mask) { @prompt.symbols[:dot] }
        @done_masked = false
        @failure     = false
      end

      # Set character for masking the STDIN input
      #
      # @param [String] char
      #
      # @return [self]
      #
      # @api public
      def mask(char = (not_set = true))
        return @mask if not_set

        @mask = char
      end

      # Handle the return key by finishing the masked input
      #
      # @api private
      def keyreturn(_event)
        @done_masked = true
      end

      # Handle the enter key by finishing the masked input
      #
      # @api private
      def keyenter(_event)
        @done_masked = true
      end

      # Handle a key press by appending or removing characters from
      # the masked input buffer
      #
      # @param [TTY::Reader::KeyEvent] event
      #   the key event
      #
      # @api private
      def keypress(event)
        if DELETE_KEYS.include?(event.key.name)
          @input.chop! unless @input.empty?
        elsif event.value =~ /^[^\e\n\r]/
          @input += event.value
        end
      end

      # Render question and input replaced with masked character
      #
      # @api private
      def render_question
        header = ["#{@prefix}#{message} "]
        if echo?
          masked = @mask.to_s * @input.to_s.length
          if @done_masked && !@failure
            masked = @prompt.decorate(masked, @active_color)
          elsif @done_masked && @failure
            masked = @prompt.decorate(masked, @error_color)
          end
          header << masked
        end
        header << "\n" if @done
        header.join
      end

      # Handle error condition, tracking failure to color the masked
      # input accordingly
      #
      # @return [String]
      #
      # @api private
      def render_error(errors)
        @failure = !errors.empty?
        super
      end

      # Read input from user masked by character
      #
      # @private
      def read_input(question)
        @done_masked = false
        @failure = false
        @input = ""
        @prompt.print(question)
        until @done_masked
          @prompt.read_keypress
          question = render_question
          total_lines = @prompt.count_screen_lines(question)
          @prompt.print(@prompt.clear_lines(total_lines))
          @prompt.print(render_question)
        end
        @prompt.puts
        @input
      end
    end # MaskQuestion
  end # Prompt
end # TTY
