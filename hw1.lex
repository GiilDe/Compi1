%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TAB   0x09
#define LF    0x0A
#define CR    0x0D

int comment_lines = 1;
char * curr_str = NULL;

static inline int is_printable_char(int hex) {
  return (hex >= 0x20 && hex <= 0x7E)
  || hex == TAB
  || hex == CR
  || hex == LF;
}

void show_comment_token() {
  printf("%d COMMENT %d\n", yylineno, comment_lines);
  // Reset the count for the next comment
  comment_lines = 1;
}

void show_token(char * name) {
  printf("%d %s %s\n", yylineno, name, yytext);
}

void append_curr_str(char * suffix) {
  // printf("Appending: %s\n", suffix);
  if (!curr_str) {
    curr_str = malloc(sizeof(char) * (strlen(suffix) + 1));
    strcpy(curr_str, suffix);
    curr_str[strlen(suffix)] = '\0';
    return;
  }
  char * prefix = curr_str;
  int len1 = strlen(suffix);
  int len2 = strlen(prefix);
  curr_str = malloc(sizeof(char) * (len1 + len2 + 1));
  curr_str[0] = '\0';
  strcat(curr_str, prefix);
  strcat(curr_str, suffix);
  free (prefix);
}

void append_escape_seq() {
  int hex = strtol(++yytext, NULL, 16);
  if (!is_printable_char(hex)) {
    return;
  }
  if (!curr_str) {
    curr_str = malloc(sizeof(char));
    curr_str[0] = hex;
    return;
  }
  char * prefix = curr_str;
  curr_str = malloc(sizeof(char) * (strlen(prefix) + 2));
  int len = strlen(prefix);
  strcpy(curr_str, prefix);
  curr_str[len] = (char) hex;
  curr_str[len + 1] = '\0';
}

void show_string() {
  if (!curr_str) {
    printf("%d STRING \n", yylineno);
    return;
  }
  int len = strlen(curr_str);
  // curr_str[len - 1] = 0;
  printf("%d STRING %s\n", yylineno, curr_str);
  curr_str = NULL;
}

void error(char * c_name) {
  printf("Error %s\n", c_name);
  exit(0);
}

static inline void show_comment_error() {
  printf("Warning nested comment\n");
  exit(0);
}

static inline void illegal_escape_sequence(){
    printf("Error undefined escape sequence %s\n", ++yytext);
    exit(0);
}

%}

%option yylineno
%option noyywrap

%x COMMENT
%x STRING_ONE
%x STRING_TWO

ws ([\r\n\t ])
hex_digit ([0-9a-fA-F])
hexadecimal_number ([\+\-]?0x{hex_digit}+)
printable_char ([\x20-\x7E\x09\x0A\x0D])
digit ([0-9])
identifier_char ([0-9a-zA-Z\-_])
ascii_escape_seq (\\({hex_digit}){1,6})
letter ([a-zA-Z])
num ({digit}+)
s_num ([\+\-]?{num})
rgb_num ({ws}*{s_num}{ws}*)
esc_seq_no_lf ((\\r)|(\\t)|(\\\\)|{ascii_escape_seq})
printable_inside_comment ([\x20-\x29\x2B-\x2E\x30-\x7E\t\r])
printable_string_char ([\x20-\x21\x23-\x5B\x5D-\x7E\x09])
printable_string_char_f ([\x20-\x26\x28-\x5B\x5D-\x7E\x09])
esc_seq ((\\n)|{esc_seq_no_lf})

%%
\/\*                                      BEGIN(COMMENT);
<COMMENT>\/\*                             show_comment_error();
<COMMENT>{printable_inside_comment}*      ;
<COMMENT>\n                               comment_lines++;
<COMMENT>\*\/                             BEGIN(INITIAL); show_comment_token();
<COMMENT>\*                               ;
<COMMENT>\/                               ;
<COMMENT>.                                error("/");
<COMMENT><<EOF>>                          error("unclosed comment");


\"                                        BEGIN(STRING_ONE);
<STRING_ONE>\"                            BEGIN(INITIAL); show_string();
<STRING_ONE>({printable_string_char}|{esc_seq})* append_curr_str(yytext);


\'                                        BEGIN(STRING_TWO);
<STRING_TWO>\'                            BEGIN(INITIAL); show_string();
<STRING_TWO>\\n                           append_curr_str("\n");
<STRING_TWO>\\t                           append_curr_str("\t");
<STRING_TWO>\\r                           append_curr_str("\r");
<STRING_TWO>\\\\                          append_curr_str("\\");
<STRING_TWO>{ascii_escape_seq}            append_escape_seq();
<STRING_ONE,STRING_TWO>\\{printable_string_char}  illegal_escape_sequence();
<STRING_TWO>{printable_string_char_f}*    append_curr_str(yytext);
<STRING_ONE,STRING_TWO><<EOF>>            error("unclosed string");

#((-?{letter})|{num}){identifier_char}*       show_token("HASHID");
@import                                       show_token("IMPORT");
!{ws}*[iI][mM][pP][oO][rR][tT][aA][nN][tT]    show_token("IMPORTANT");
[>\+~]                                        show_token("COMB");
:                                             show_token("COLON");
;                                             show_token("SEMICOLON");
\{                                            show_token("LBRACE");
\}                                            show_token("RBRACE");
\[                                            show_token("LBRACKET");
\]                                            show_token("RBRACKET");
=                                             show_token("EQUAL");
\*                                            show_token("ASTERISK");
\.                                            show_token("DOT");
({s_num}|{hexadecimal_number})                show_token("NUMBER");
(({digit}+)|({digit}*\.{digit}+))([a-z]+|%)   show_token("UNIT");
rgb\({rgb_num},{rgb_num},{rgb_num}\)          show_token("RGB");

rgb             error("in rgb parameters");
(\-)?[a-zA-Z]{identifier_char}* show_token("NAME");
{ws}            ;
.               error(yytext);
%%
