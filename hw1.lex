%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TAB   0x09
#define LF    0x0A
#define CR    0x0D

#define IS_ASCII(char) \
  (((char) >= '0' && (char) <= '9') \
  || ((char) >= 'a' && (char) <= 'f') \
  || ((char) >= 'A' && (char) <= 'F') \
  )

int comment_lines = 1;
char * curr_str = NULL;

static inline int is_printable_char(int hex) {
  return (hex >= 0x20 && hex <= 0x7E)
  || hex == TAB
  || hex == CR
  || hex == LF;
}

static inline void shift_string(char *src, int index, int len) {
  for (char * p = src + index; *p != '\0'; p++) {
    *p = *(p+len);
  }
}

// Given a string and the length of a hex-escaped character, find it's
// ASCII value
static inline int find_ascii(char * str, int size) {
  char* escape_seq = malloc(sizeof(char) * (size + 1));
  strncpy(escape_seq, str, size);
  escape_seq[size] = '\0';
  int hex = strtol(escape_seq, NULL, 16);
  free(escape_seq);
  return hex;
}

static inline void format_next_escape_str(char *src) {
  char no_escape_char = *(src+1);
  if(no_escape_char == '\0'){
    return;
  }

  char escaped_char;
  int should_escape = 1;
  int is_hex = 0;
  // Handle case of a single-character escape
  switch (no_escape_char) {
    case 'n': escaped_char = '\n'; break;
    case 'r': escaped_char = '\r'; break;
    case 't': escaped_char = '\t'; break;
    case '\\': escaped_char = '\\'; break;
    default: should_escape = 0;
  }

  if(should_escape) {
    *src = escaped_char;
    for (char * p = src + 1; *p != '\0'; p++) {
      *p = *(p+1);
    }
  } else {
    // We assume it is a hex-escaped character
    char * p = src + 1;
    int len = 0;
    // Count the length of the escaped ascii string [1-6]
    while (len < 6 && IS_ASCII(p[len])) len++;
    int ascii = find_ascii(p, len);

    int src_offset;
    if (is_printable_char(ascii)) {
      // Print it
      *src = (char) ascii;
      src_offset = 0;
    } else {
      // Ignore it
      src_offset = 1;
      p--;
    }

    while (*(p + len - 1) != '\0') {
      *p = *(p + len + src_offset);
      p++;
    }
  }
}

// Format a STRING lexme and replace all escaped characters
// With real characters
static inline void format_string(char * src) {
  while (*src != '\0') {
    if (*src == '\\') {
      format_next_escape_str(src);
    }
    src++;
  }
}

// Remove the brackets of a STRING lexme
static inline void remove_brackets(char * dest, char * str, int size) {
  if (size < 2) {
    // Should not happen
    return;
  }
  int new_size = size - 2;
  strcpy(dest, ++str);
  dest[new_size] = '\0';
}

void show_string_token() {
  char * formatted = malloc(sizeof(char) * (yyleng - 1));
  int should_format = 1;
  if (yytext[0] == '\"') {
    should_format = 0;
  }

  remove_brackets(formatted, yytext, yyleng);
  if (should_format) {
    format_string(formatted);
  }
  printf("%d STRING %s\n", yylineno, formatted);
  free (formatted);
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
  if (!curr_str) {
    curr_str = suffix;
    return;
  }
  char * prefix = curr_str;
  int len1 = strlen(suffix);
  int len2 = strlen(prefix);
  curr_str = malloc(sizeof(char) * (len1 + len2 + 1));
  curr_str[0] = '\0';
  strcat(curr_str, prefix);
  strcat(curr_str, suffix);
}

void show_string() {
  if (!curr_str) {
    printf("%d STRING \n", yylineno);
    return;
  }
  int len = strlen(curr_str);
  curr_str[len - 1] = 0;
  printf("%d STRING %s\n", yylineno, curr_str);
}

void show_escape_seq() {
  // printf("\nESCAPE: %s\n", yytext);
  int hex = strtol(++yytext, NULL, 16);
  if (is_printable_char(hex)) printf("%c", (char)hex);
}

void error(char * c_name) {
  printf("Error %s\n", c_name);
  exit(0);
}

void unclosed_string(){
  printf("Error unclosed string\n");
  exit(0);
}

void show_comment_error() {
  printf("Warning nested comment\n");
  exit(0);
}

void illegal_escape_sequence(){
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
<STRING_ONE>({printable_string_char}|{esc_seq})* {
                                            curr_str = yytext;
                                          }


\'                                        BEGIN(STRING_TWO);
<STRING_TWO>\'                            BEGIN(INITIAL); show_string();
<STRING_TWO>\\n                           append_curr_str("\n");
<STRING_TWO>\\t                           append_curr_str("\t");
<STRING_TWO>\\r                           append_curr_str("\r");
<STRING_TWO>\\\\                          append_curr_str("\\");
<STRING_TWO>{ascii_escape_seq}            show_escape_seq();
<STRING_ONE,STRING_TWO>\\{printable_string_char}  illegal_escape_sequence();
<STRING_TWO>{printable_string_char_f}*    append_curr_str(yytext);

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
%               error("%");
!               error("!");
@               error("@");
(\-)?[a-zA-Z]{identifier_char}* show_token("NAME");
{ws} ;
.               error(yytext);
%%
