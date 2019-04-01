%{
#include <stdio.h>
void showToken(char*);
%}

whitespace ([\r\n\t ])
hexadecimal_number ([\+\-]?0x[0-9a-fA-F]+)
printable_char ([\x20-\x7E\x09\x0A\x0D])
identifier_char ([0-9a-zA-Z\-_])
escape_seq (\\(.+))
ascii_escape_seq (\\[0-9a-fA-F]{1,6})
letter ([a-zA-Z])
number ([0-9]+)



%%
/\*{printable_char}*\*/ showToken("comment")
{identifier_char}+ showToken("IDENTIFIER");

(\-)?[a-zA-Z]{identifier_char}* showToken("NAME")
#(letter|number|(\-letter)){identifier_char}* showToken("HASHID")



. showToken("ERROR");
%%



void showToken(char * name) {
  printf("Lex found token %s, ", name);
  printf("The lexme is %s, ", yytext);
  printf("It's length is %d\n", yyleng);
}
