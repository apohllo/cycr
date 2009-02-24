package pl.apohllo.lexicon.pwn.server;

import java.io.StringReader;
%% 

%class Lexer
%unicode
%line
%public
%type Symbol

%{
  StringBuffer string = new StringBuffer();

  public Lexer(String input){
    this.zzReader = new StringReader(input);
  }

  private Symbol symbol(int type) {
    return new Symbol(type, yyline, yycolumn);
  }
  private Symbol symbol(int type, String value) {
    return new Symbol(type, yyline, yycolumn, value);
  }
%}

LineTerminator = \r|\n|\r\n
InputCharacter = [^\r\n\"\(\):& ]
WhiteSpace     = {LineTerminator} | [ \t\f]

Symbol = : {InputCharacter}+

Atom = {InputCharacter}+

OpenPar = "("
ClosePar = ")"

%state STRING


%%

<YYINITIAL> {
  /* keywords */
  {OpenPar}			 { return symbol(Symbol.OPEN_PAR); }
  {ClosePar}			 { return symbol(Symbol.CLOSE_PAR); }

  /* identifiers */ 
  {Symbol}			 { return symbol(Symbol.SYMBOL,yytext()); }
  {Atom}			 { return symbol(Symbol.ATOM,yytext()); }


  /* literals */
  \"                             { string.setLength(0); yybegin(STRING); }

  /* whitespace */
  {WhiteSpace}                   { /* ignore */ }
}

<STRING> {
  \"                             { yybegin(YYINITIAL); 
                                   return symbol(Symbol.STRING_LITERAL, string.toString()); }
  [^\n\r\"\\]+                   { string.append( yytext() ); }
  \\t                            { string.append('\t'); }
  \\n                            { string.append('\n'); }

  \\r                            { string.append('\r'); }
  \\\"                           { string.append('\"'); }
  \\                             { string.append('\\'); }
}

/* error fallback */
.|\n                             { throw new Error("Illegal character <"+ yytext()+">"); }

