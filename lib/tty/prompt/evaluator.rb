# frozen_string_literal: true

require_relative "result"

module TTY
  class Prompt
    # Evaluates provided parameters and stops if any of them fails
    # @api private
    class Evaluator
      attr_reader :results

      # Create an Evaluator
      #
      # @param [Question] question
      #   the question this evaluator validates input for
      #
      # @api private
      def initialize(question, &block)
        @question = question
        @results = []
        instance_eval(&block) if block
      end

      # Run all registered checks against the initial value
      #
      # @param [Object] initial
      #   the value to validate
      #
      # @return [Result]
      #   the result of running all checks
      #
      # @api private
      def call(initial)
        seed = Result::Success.new(@question, initial)
        results.reduce(seed, &:with)
      end

      # Register a check to run against the input value
      #
      # @param [Proc] proc
      #   the check to register
      #
      # @api private
      def check(proc = nil, &block)
        results << (proc || block)
      end
      alias << check
    end # Evaluator
  end # Prompt
end # TTY
