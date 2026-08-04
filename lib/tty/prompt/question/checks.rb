# frozen_string_literal: true

require_relative "../const"

module TTY
  class Prompt
    class Question
      module Checks
        # Check if modifications are applicable
        class CheckModifier
          # Apply configured modifiers to the value
          #
          # @param [Question] question
          #   the question providing the modifier rules
          # @param [Object] value
          #   the value to modify
          #
          # @return [Array]
          #   the modified value wrapped in an array
          #
          # @api private
          def self.call(question, value)
            if !question.modifier.nil? || question.modifier
              [Modifier.new(question.modifier).apply_to(value)]
            else
              [value]
            end
          end
        end

        # Check if value is within range
        class CheckRange
          # Check if value looks like a float
          #
          # @param [Object] value
          #
          # @return [Boolean]
          #
          # @api private
          def self.float?(value)
            !/[-+]?(\d*[.])?\d+/.match(value.to_s).nil?
          end

          # Check if value looks like an integer
          #
          # @param [Object] value
          #
          # @return [Boolean]
          #
          # @api private
          def self.int?(value)
            !/^[-+]?\d+$/.match(value.to_s).nil?
          end

          # Cast value to a float or integer when possible
          #
          # @param [Object] value
          #
          # @return [Object]
          #
          # @api private
          def self.cast(value)
            if float?(value)
              value.to_f
            elsif int?(value)
              value.to_i
            else
              value
            end
          end

          # Check if value falls within the question's configured range
          #
          # @param [Question] question
          #   the question providing the range rule
          # @param [Object] value
          #   the value to check
          #
          # @return [Array]
          #   the value, plus an error message when out of range
          #
          # @api private
          def self.call(question, value)
            if !question.in? ||
               (question.in? && question.in.include?(cast(value)))
              [value]
            else
              tokens = {value: value, in: question.in}
              [value, question.message_for(:range?, tokens)]
            end
          end
        end

        # Check if input requires validation
        class CheckValidation
          # Check if value passes the question's validation rule
          #
          # @param [Question] question
          #   the question providing the validation rule
          # @param [Object] value
          #   the value to validate
          #
          # @return [Array]
          #   the value, plus an error message when invalid
          #
          # @api private
          def self.call(question, value)
            if !question.validation? || (question.required? && value.nil?) ||
               (question.validation? &&
                 Validation.new(question.validation).(value))
              [value]
            else
              tokens = {valid: question.validation.inspect, value: value}
              [value, question.message_for(:valid?, tokens)]
            end
          end
        end

        # Check if default value provided
        class CheckDefault
          # Substitute the question's default value when value is nil
          #
          # @param [Question] question
          #   the question providing the default value
          # @param [Object] value
          #   the value to check
          #
          # @return [Array]
          #   the value or the question's default
          #
          # @api private
          def self.call(question, value)
            if value.nil? && question.default?
              [question.default]
            else
              [value]
            end
          end
        end

        # Check if input is required
        class CheckRequired
          # Check if a required value is missing
          #
          # @param [Question] question
          #   the question specifying whether a value is required
          # @param [Object] value
          #   the value to check
          #
          # @return [Array]
          #   the value, plus an error message when missing
          #
          # @api private
          def self.call(question, value)
            if question.required? && !question.default? && value.nil?
              [value, question.message_for(:required?)]
            else
              [value]
            end
          end
        end

        # Check if input converts to the question's requested type
        class CheckConversion
          # Convert value to the question's requested type
          #
          # @param [Question] question
          #   the question providing the conversion rule
          # @param [Object] value
          #   the value to convert
          #
          # @return [Array]
          #   the converted value, plus an error message on failure
          #
          # @api private
          def self.call(question, value)
            if question.convert? && !Utils.blank?(value)
              result = question.convert_result(value)
              if result == Const::Undefined
                tokens = {value: value, type: question.convert}
                [value, question.message_for(:convert?, tokens)]
              else
                [result]
              end
            else
              [value]
            end
          end
        end
      end # Checks
    end # Question
  end # Prompt
end # TTY
