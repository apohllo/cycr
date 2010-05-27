module Cyc
  class Parser
    def initialize
      @lexer = SExpressionLexer.new
    end
    # Parses message received from server. +Message+ to parse.
    def parse(message)
      @lexer.scan_str(message)
      stack = [[]]
      while !(token = @lexer.next_token).nil?
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
        when :string
          stack[-1] << token[1]
        end
      end
      stack[0][0]
    rescue 
      puts "Error occured while parsing message:\n#{message}"
      nil
    end
  end
end
