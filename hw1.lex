%{
#include <stdio.h>
void showToken(char*);
%}

identifier_char ([0-9a-zA-Z\-_])
escape_seq (\\(.+))
ascii_escape_seq (\\[0-9a-fA-F]{1,6})
%%

{identifier_char}+ showToken("IDENTIFIER");
. showToken("ERROR");
%%
void showToken(char * name) {
  printf("Lex found token %s, ", name);
  printf("The lexme is %s, ", yytext);
  printf("It's length is %d\n", yyleng);
}
