# frozen_string_literal: true

module TTY
  class Prompt
    # A countdown timer that yields the time remaining on a fixed
    # interval, used by {Keypress} to implement the `:timeout` option.
    #
    # @api private
    class Timer
      # The total countdown duration in seconds, or nil for no timeout
      #
      # @return [Numeric, nil]
      attr_reader :duration

      # The accumulated time elapsed across all ticks
      #
      # @return [Numeric]
      attr_reader :total

      # The interval in seconds between ticks
      #
      # @return [Numeric]
      attr_reader :interval

      # Create a Timer
      #
      # @param [Numeric, nil] duration
      #   the total countdown duration in seconds, or nil for no timeout
      # @param [Numeric] interval
      #   the interval in seconds between ticks
      #
      # @api public
      def initialize(duration, interval)
        @duration = duration
        @interval = interval
        @total = 0.0
        @current = nil
        @events = []
      end

      # Mark the timer as started, unless already running
      #
      # @api public
      def start
        return if @current

        @current = time_now
      end

      # Mark the timer as stopped
      #
      # @api public
      def stop
        return unless @current

        @current = nil
      end

      # Time elapsed since the timer was started
      #
      # @return [Numeric]
      #
      # @api public
      def runtime
        time_now - @current
      end

      # Register a block to run on every tick
      #
      # @yield [tick]
      #
      # @api public
      def on_tick(&block)
        @events << block
      end

      # Loop until the duration elapses, yielding the time remaining and
      # firing registered tick events at each interval
      #
      # @yieldparam [Numeric] remaining
      #   the time left before the timer completes
      #
      # @api public
      def while_remaining(&block)
        start
        remaining = duration

        if @duration
          while remaining >= 0.0
            if runtime >= total
              tick = duration - @total
              @events.each { |block| block.(tick) }
              @total += @interval
            end

            yield(remaining)
            remaining = duration - runtime
          end
        else
          loop(&block)
        end
      ensure
        stop
      end

      if defined?(Process::CLOCK_MONOTONIC)
        # Object representing current time
        def time_now
          ::Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end
      else
        # simplecov:disable
        # Object representing current time, for platforms without a
        # monotonic clock
        def time_now
          ::Time.now
        end
        # simplecov:enable
      end
    end # Timer
  end # Prompt
end # TTY
