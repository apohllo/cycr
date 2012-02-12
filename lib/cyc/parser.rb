module Cyc
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT/X11 License
  #
  # The class used to parse the answer of the Cyc server.
  class Parser
    def initialize
      @lexer = SExpressionLexer.new
    end

    # Parses message received from server. Accepts
    # +message+ to parse and a +stack+ with a partial parse result.
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
          stack[-1] << ::Cyc::Symbol.new(token[1][1..-1])
        when :variable
          stack[-1] << ::Cyc::Variable.new(token[1][1..-1])
        when :term
          stack[-1] << token[1][2..-1].to_sym
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
        when :assertion_sep
          # ignore
        end
      end
      stack[0][0]
    rescue ContinueParsing => ex
      raise
    rescue Exception => ex
      raise ParserError.new("Exception #{ex} occurred when parsing message '#{message}'.")
    end
  end
end
