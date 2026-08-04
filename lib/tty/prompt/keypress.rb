# frozen_string_literal: true

require_relative "question"
require_relative "timer"

module TTY
  class Prompt
    # A question answered by a single keypress, optionally bound to a
    # timeout or a restricted set of accepted keys. Used by
    # {Prompt#keypress}.
    #
    # @api private
    class Keypress < Question
      # Create keypress question
      #
      # @param [Prompt] prompt
      # @param [Hash] options
      #
      # @api public
      def initialize(prompt, **options)
        super
        @echo    = options.fetch(:echo, false)
        @keys    = options.fetch(:keys) { UndefinedSetting }
        @timeout = options.fetch(:timeout) { UndefinedSetting }
        @interval = options.fetch(:interval) {
          @timeout != UndefinedSetting && @timeout < 1 ? @timeout : 1
        }
        @decimals = (@interval.to_s.split(".")[1] || []).size
        @countdown = @timeout
        time = timeout? ? Float(@timeout) : nil
        @timer = Timer.new(time, Float(@interval))

        @prompt.subscribe(self)
      end

      # Get or set the remaining countdown time in seconds
      #
      # @param [Numeric] value
      #   the remaining time to set
      #
      # @return [Numeric]
      #
      # @api private
      def countdown(value = (not_set = true))
        return @countdown if not_set

        @countdown = value
      end

      # Check if any specific keys are set
      def any_key?
        @keys == UndefinedSetting
      end

      # Check if timeout is set
      def timeout?
        @timeout != UndefinedSetting
      end

      # Handle a key press by finishing the question when the pressed
      # key is accepted
      #
      # @param [TTY::Reader::KeyEvent] event
      #   the key event
      #
      # @api private
      def keypress(event)
        @done = any_key? ||
                (@keys.is_a?(Array) && @keys.include?(event.key.name))
      end

      # Render question with the :countdown token substituted for the
      # remaining time
      #
      # @return [String]
      #
      # @api private
      def render_question
        header = super
        header.gsub!(":countdown", "%.#{@decimals}f" % countdown) if timeout?
        header
      end

      # Refresh the question display with the updated countdown time
      #
      # @param [Numeric] time
      #   the remaining time
      #
      # @api private
      def interval_handler(time)
        return if @done

        question = render_question
        line_size = question.size
        total_lines = @prompt.count_screen_lines(line_size)
        @prompt.print(refresh(question.lines.count, total_lines))
        countdown(time)
        @prompt.print(render_question)
      end

      # Decide how to handle input from user, polling for a keypress
      # until the timer runs out or the question is done
      #
      # @api private
      def process_input(_question)
        @prompt.print(render_question)

        @timer.on_tick do |time|
          interval_handler(time)
        end

        @timer.while_remaining do |_remaining|
          break if @done

          @input = @prompt.read_keypress(nonblock: true)
        end
        countdown(0) unless @done

        @evaluator.(@input)
      end

      # Determine area of the screen to clear
      #
      # @param [Integer] lines
      #   number of lines to clear
      #
      # @return [String]
      #
      # @api private
      def refresh(lines, _lines_to_clear)
        @prompt.clear_lines(lines)
      end
    end # Keypress
  end # Prompt
end # TTY
