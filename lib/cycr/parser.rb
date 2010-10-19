module Cyc
  class Parser
    # Exception raised when there is a continuation sign,
    # at the end of the parsed message.
    class ContinueParsing < RuntimeError
      attr_reader :stack

      def initialize(stack)
        @stack = stack
      end
    end

    def initialize
      @lexer = SExpressionLexer.new
    end

    # Parses message received from server. +Message+ to parse.
    def parse(message,stack=nil)
      @lexer.scan_str(message)
      stack ||= [[]]
      while !(token = @lexer.next_token).nil?
        #p token
        case token[0]
        when :open_par
          stack.push []
        when :close_par
          top = stack.pop
          stack[-1].push top
        when :atom
          # FIXME find way to differentiate strings and atoms
          stack[-1] << token[1]
        when :cyc_symbol
          stack[-1] << token[1][2..-1].to_sym
        when :symbol
          stack[-1] << token[1][3..-1].to_sym
        when :string
          stack[-1] << token[1]
        when :open_as
          stack.push [:as]
        when :close_quote
          top = stack.pop
          if top[0] == :as
            as = Assertion.new(top[1],top[2])
            stack[-1].push as
          else
            stack.push top
          end
        when :continuation
          top = stack.pop
          stack[-1].push top
          raise ContinueParsing.new(stack[0][0])
        end
      end
      stack[0][0]
    rescue ContinueParsing => ex
      raise
    rescue Exception => ex
      puts "Error occured while parsing message:\n#{message}"
      puts ex
      nil
    end
  end
end
