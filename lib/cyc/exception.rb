module Cyc
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT/X11 License
  #
  # Base class for exceptions raised by the library.
  class CycError < RuntimeError
  end

  # Error raised if the message sent to the server has
  # more opening parentheses than closing parentheses.
  class UnbalancedOpeningParenthesis < CycError
    # The number of unbalanced opening parentheses.
    attr_reader :count

    # Initialize the exception with the +count+ of unbalanced
    # opening parentheses.
    def initialize(count)
      super("There are #{count} unbalanced opening parentheses")
      @count = count
    end
  end

  # Error raised if the message sent to the server has
  # more closing parentheses than opening parentheses.
  class UnbalancedClosingParenthesis < CycError
  end

  # Exception raised by the parser if there is contents
  # that cannot be parsed.
  class ParserError < CycError
  end

  # Exception raised when there is a continuation sign,
  # at the end of the parsed message.
  class ContinueParsing < ParserError
    attr_reader :stack

    def initialize(stack)
      @stack = stack
    end
  end
  
  # Exception raised by the parser if data received from server
  # is not in expected format.
  class ProtocolError < CycError
  end

end
