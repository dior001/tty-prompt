# frozen_string_literal: true

module TTY
  class Prompt
    # Accumulates errors
    class Result
      attr_reader :question, :value, :errors

      # Create a Result
      #
      # @param [Question] question
      #   the question this result belongs to
      # @param [Object] value
      #   the current value
      # @param [Array] errors
      #   the accumulated errors
      #
      # @api private
      def initialize(question, value, errors = [])
        @question = question
        @value  = value
        @errors = errors
      end

      # Run a validator against the current value and accumulate errors
      #
      # @param [Proc] condition
      #   the validator to run
      #
      # @return [Result]
      #   a Success when there are no errors, a Failure otherwise
      #
      # @api private
      def with(condition = nil, &block)
        validator = condition || block
        (new_value, validation_error) = validator.(question, value)
        accumulated_errors = errors + Array(validation_error)

        if accumulated_errors.empty?
          Success.new(question, new_value)
        else
          Failure.new(question, new_value, accumulated_errors)
        end
      end

      # Check if this result is a success
      #
      # @return [Boolean]
      #
      # @api private
      def success?
        is_a?(Success)
      end

      # Check if this result is a failure
      #
      # @return [Boolean]
      #
      # @api private
      def failure?
        is_a?(Failure)
      end

      class Success < Result
      end

      class Failure < Result
      end
    end
  end # Prompt
end # TTY
