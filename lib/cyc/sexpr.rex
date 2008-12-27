class SExpressionLexer

option
  independent

macro 
  LINE_TERMINATOR       \r|\n|\r\n
  INPUT_CHARACTER       [^\r\n\"\(\):& ]
  WHITE_SPACE           [\ \t\f\r\n] | \r\n
  SYMBOL                :[^\r\n\"\(\):&\ ]+
  CYC_SYMBOL            \#\$[a-zA-Z0-9-]+
  ATOM                  [^\r\n\"\(\):&\ ]+
  OPEN_PAR              \(
  CLOSE_PAR             \)
  QUOTE                 \"
  OPEN_LIST_QUOTE       \#<
  CLOSE_LIST_QUOTE      >
  DOT                   \.


rule
                        # lists
                        {OPEN_LIST_QUOTE}   #ignore
                        {CLOSE_LIST_QUOTE}  #ignore
                        {DOT}               #ignore
                        # keywords 
                        {OPEN_PAR}			  { [:open_par,text] }
                        {CLOSE_PAR}			  { [:close_par,text] }
                        NIL               { [:nil,text] }
                        # identifiers 
                        {SYMBOL}			    { [:symbol,text] }
                        {CYC_SYMBOL}			{ [:cyc_symbol,text] }
                        {ATOM}			      { [:atom,text] }
                        # literals 
                        {QUOTE}           { state = :STRING; @str = ""; [:in_string] }
                        # whitespace 
                        {WHITE_SPACE}     # ignore 
  :STRING               {QUOTE}           { state = nil; [:string,@str] }
  :STRING               [^\n\r\"\\]+      { @str << text; [:in_string]}
  :STRING               \t               { @str << '\t'; [:in_string] }
  :STRING               \n               { @str << '\n'; [:in_string] }
  :STRING               \r               { @str << '\r'; [:in_string] }
  :STRING               \\"              { @str << '\"'; [:in_string] }
  :STRING               \\                { @str << '\\'; [:in_string] }
  # error fallback 
                        .|\n              { raise "Illegal character <#{text}>" }
inner
  def do_parse
#    while !(token = next_token).nil?
#      print " #{token[0]}:#{token[1]}" unless token[0] == :in_string
#    end
  end
end
