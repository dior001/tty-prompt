# frozen_string_literal: true

require "stringio"

require_relative "../prompt"

module TTY
  # Used for initializing test cases
  class Prompt
    # Patches a StringIO input so it can stand in for a real terminal IO
    # object in tests, providing the minimal IO-like interface that
    # TTY::Reader expects.
    #
    # @api private
    module StringIOExtensions
      # Duck-types IO#wait_readable, which TTY::Reader::Console calls on
      # the input stream; the name must match, so it can't end in `?`.
      def wait_readable(*) # rubocop:disable Naming/PredicateMethod
        true
      end

      # Duck-types IO#ioctl, used by TTY::Reader to query terminal size
      #
      # @api private
      def ioctl(*)
        80
      end
    end

    # A {Prompt} subclass wired up with in-memory StringIO input/output,
    # so specs can feed simulated keystrokes and assert on rendered
    # output without a real terminal.
    #
    # @example
    #   prompt = TTY::Prompt::Test.new
    #   prompt.input << "yes\n"
    #   prompt.input.rewind
    #
    # @api public
    class Test < TTY::Prompt
      # Create a Test prompt with StringIO input/output streams
      #
      # @api public
      def initialize(**options)
        @input = StringIO.new
        @input.extend(StringIOExtensions)
        @output = StringIO.new

        options.merge!({
          input: @input,
          output: @output,
          env: {"TTY_TEST" => true},
          enable_color: options.fetch(:enable_color, true)
        })
        super
      end
    end # Test
  end # Prompt
end # TTY
