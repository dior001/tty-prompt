# frozen_string_literal: true

require_relative "choices"

module TTY
  class Prompt
    # A class responsible for rendering expanding options
    # Used by {Prompt} to display key options question.
    #
    # @api private
    class Expander
      HELP_CHOICE = {
        key: "h",
        name: "print help",
        value: :help
      }.freeze

      # Names for delete keys
      DELETE_KEYS = %i[backspace delete].freeze

      # Create instance of Expander
      #
      # @api public
      def initialize(prompt, options = {})
        @prompt       = prompt
        @prefix       = options.fetch(:prefix) { @prompt.prefix }
        @default      = options.fetch(:default, 1)
        @auto_hint    = options.fetch(:auto_hint, false)
        @active_color = options.fetch(:active_color) { @prompt.active_color }
        @help_color   = options.fetch(:help_color) { @prompt.help_color }
        @quiet        = options.fetch(:quiet) { @prompt.quiet }
        @choices      = Choices.new
        @selected     = nil
        @done         = false
        @status       = :collapsed
        @hint         = nil
        @default_key  = false
      end

      # Check if the help menu is expanded
      #
      # @return [Boolean]
      #
      # @api private
      def expanded?
        @status == :expanded
      end

      # Check if the help menu is collapsed
      #
      # @return [Boolean]
      #
      # @api private
      def collapsed?
        @status == :collapsed
      end

      # Expand the help menu
      #
      # @api private
      def expand
        @status = :expanded
      end

      # Respond to submit event
      #
      # @api public
      def keyenter(_)
        if @input.nil? || @input.empty?
          @input = @choices[@default - 1].key
          @default_key = true
        end

        selected = select_choice(@input)

        if selected && selected.key.to_s == "h"
          expand
          @selected = nil
          @input = ""
        elsif selected
          @done = true
          @selected = selected
          @hint = nil
        else
          @input = ""
        end
      end
      alias keyreturn keyenter

      # Respond to key press event
      #
      # @api public
      def keypress(event)
        if DELETE_KEYS.include?(event.key.name)
          @input.chop! unless @input.empty?
        elsif event.value =~ /^[^\e\n\r]/
          @input += event.value
        end

        @selected = select_choice(@input)
        return unless @selected && !@default_key && collapsed?

        @hint = @selected.name
      end

      # Select choice by given key
      #
      # @return [Choice]
      #
      # @api private
      def select_choice(key)
        @choices.find_by(:key, key)
      end

      # Set default value.
      #
      # @api public
      def default(value = (not_set = true))
        return @default if not_set

        @default = value
      end

      # Set quiet mode.
      #
      # @api public
      def quiet(value)
        @quiet = value
      end

      # Add a single choice
      #
      # @api public
      def choice(value, &block)
        @choices << if block
                      value.update(value: block)
                    else
                      value
                    end
      end

      # Add multiple choices
      #
      # @param [Array[Object]] values
      #   the values to add as choices
      #
      # @api public
      def choices(values)
        values.each { |val| choice(val) }
      end

      # Execute this prompt
      #
      # @api public
      def call(message, possibilities, &block)
        choices(possibilities)
        @message = message
        block&.(self)
        setup_defaults
        choice(HELP_CHOICE)
        @prompt.subscribe(self) do
          render
        end
      end

      private

      # Create possible keys with current choice highlighted
      #
      # @return [String]
      #
      # @api private
      def possible_keys
        keys = @choices.pluck(:key)
        default_key = keys[@default - 1]
        if @selected
          index = keys.index(@selected.key)
          keys[index] = @prompt.decorate(keys[index], @active_color)
        elsif @input.to_s.empty? && default_key
          keys[@default - 1] = @prompt.decorate(default_key, @active_color)
        end
        keys.join(",")
      end

      # @api private
      def render
        @input = ""
        until @done
          question = render_question
          @prompt.print(question)
          read_input
          @prompt.print(refresh(question.lines.count))
        end
        @prompt.print(render_question) unless @quiet
        answer
      end

      # @api private
      def answer
        @selected.value
      end

      # Render message with options
      #
      # @return [String]
      #
      # @api private
      def render_header
        header = ["#{@prefix}#{@message} "]
        if @done
          selected_item = @selected.name.to_s
          header << @prompt.decorate(selected_item, @active_color)
        elsif collapsed?
          header << %[(enter "h" for help) ]
          header << "[#{possible_keys}] "
          header << @input
        end
        header.join
      end

      # Show hint for selected option key
      #
      # return [String]
      #
      # @api private
      def render_hint
        arrow = @prompt.decorate(">> ", @active_color)
        rewind = @prompt.cursor.forward(@prompt.strip(render_header).size)
        "\n#{arrow}#{@hint}#{@prompt.cursor.prev_line}#{rewind}"
      end

      # Render question with menu
      #
      # @return [String]
      #
      # @api private
      def render_question
        load_auto_hint if @auto_hint
        header = render_header
        header << render_hint if @hint
        header << "\n" if @done

        if !@done && expanded?
          header << render_menu
          header << render_footer
        end
        header
      end

      def load_auto_hint
        return unless @hint.nil? && collapsed?

        @hint = if @selected
                  @selected.name
                elsif @input.empty?
                  @choices[@default - 1].name
                else
                  "invalid option"
                end
      end

      def render_footer
        "  Choice [#{@choices[@default - 1].key}]: #{@input}"
      end

      def read_input
        @prompt.read_keypress
      end

      # Refresh the current input
      #
      # @param [Integer] lines
      #
      # @return [String]
      #
      # @api private
      def refresh(lines)
        if (@hint && (!@selected || @done)) || (@auto_hint && collapsed?)
          @hint = nil
          @prompt.clear_lines(lines, :down) +
            @prompt.cursor.prev_line
        elsif expanded?
          @prompt.clear_lines(lines)
        else
          @prompt.clear_line
        end
      end

      # Render help menu
      #
      # @api private
      def render_menu
        output = ["\n"]
        @choices.each do |choice|
          chosen = %(#{choice.key} - #{choice.name})
          if @selected && @selected.key == choice.key
            chosen = @prompt.decorate(chosen, @active_color)
          end
          output << "  #{chosen}\n"
        end
        output.join
      end

      def setup_defaults
        validate_choices
      end

      def validate_choices
        errors = []
        keys = []
        @choices.each do |choice|
          if choice.key.nil?
            errors << "Choice #{choice.name} is missing a :key attribute"
            next
          end
          if choice.key.length != 1
            errors << "Choice key `#{choice.key}` is more than one " \
                      "character long."
          end
          if choice.key.to_s == "h"
            errors << "Choice key `#{choice.key}` is reserved for help menu."
          end
          if keys.include?(choice.key)
            errors << "Choice key `#{choice.key}` is a duplicate."
          end
          keys << choice.key if choice.key
        end
        raise ConfigurationError, errors.first if errors.any?
      end
    end # Expander
  end # Prompt
end # TTY
