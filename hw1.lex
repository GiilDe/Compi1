%{
#include <stdio.h>
#include <stdlib.h>
void showToken(char*);
void doError(char*);
%}

digit ([0-9])
identifier_char ([0-9a-zA-Z\-_])
escape_seq (\\(.+))
ascii_escape_seq (\\[0-9a-fA-F]{1,6})
signed_number ([+-]?[0-9]+)
%%

@import showToken("IMPORT");
!{whitespace}*[iI][mM][pP][oO][rR][tT][aA][nN][tT]  showToken("IMPORTANT");

[>\+~]                                  showToken("COMB");
:                                       showToken("COLON")
;                                       showToken("SEMICOLON");
\{                                      showToken("LBRACE");
\}                                      showToken("RBRACE");
\[                                      showToken("LBRACKET");
\]                                      showToken("RBRACKET");
=                                       showToken("EQUAL");
\*                                      showToken("ASTERISK");
\.                                      showToken("DOT");
({signed_number}|{hexadecimal_number})  showToken("NUMBER");
({digit}*(\.{digit}+)?)([a-z]+|%)       showToken("UNIT");
rgb({whitespace}*{signed_number}{whitespace}*,{whitespace}*{signed_number}{whitespace}*,{whitespace}*{signed_number}{whitespace}*)
. doError();
%%

void showToken(char * name) {
  // TODO Implement properly
  printf("%d %s %s\n", yylineno, name, yytext);
}

void doError() {
  // TODO Implement
  exit(0);
}
