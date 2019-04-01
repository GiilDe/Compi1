%{
#include <stdio.h>
#include <stdlib.h>
void showToken(char*);
void doError(char*);
%}



ws ([\r\n\t ])
hexadecimal_number ([\+\-]?0x[0-9a-fA-F]+)
printable_char ([\x20-\x7E\x09\x0A\x0D])
digit ([0-9])
identifier_char ([0-9a-zA-Z\-_])
escape_seq (\\(.+))
ascii_escape_seq (\\[0-9a-fA-F]{1,6})
letter ([a-zA-Z])
s_num ([+-]?[0-9]+)
number ([0-9]+)
printable_char_but_double_commas_slash_n ([\x20-\x21\x23-\x5B\x5D-\x7E\x09])
printable_char_but_commas ([\x20-\x26\x28-\x5B\x5D-\x7E\x09])
partial_escape_sequences ((\\n)|(\\r)|(\\t)|(\\\\))




%%
/\*{printable_char}*\*/ showToken("COMMENT")
(\-)?[a-zA-Z]{identifier_char}* showToken("NAME")
#(letter|number|(\-letter)){identifier_char}* showToken("HASHID")
("{printable_char_but_double_commas_slash_n|partial_escape_sequences}*")|('{printable_char_but_commas|partial_escape_sequences}*') showToken("STRING")


@import showToken("IMPORT");
!{ws}*[iI][mM][pP][oO][rR][tT][aA][nN][tT]  showToken("IMPORTANT");

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
({s_num}|{hexadecimal_number})          showToken("NUMBER");
({digit}*(\.{digit}+)?)([a-z]+|%)       showToken("UNIT");
rgb({ws}*{s_num}{ws}*,{ws}*{s_num}{ws}*,{ws}*{s_num}{ws}*) showToken("RGB");
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
