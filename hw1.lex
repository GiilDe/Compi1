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


void showStringToken();
void showCommentToken();
void showTokenMessage(char *, char *);
void showToken(char*);
void print_error(char*);
void print_escape_sequence_error();
void show_comment_error();
%}


%option yylineno
%option noyywrap

%x COMMENT

ws ([\r\n\t ])
hexadecimal_number ([\+\-]?0x[0-9a-fA-F]+)
printable_char ([\x20-\x7E\x09\x0A\x0D])
digit ([0-9])
identifier_char ([0-9a-zA-Z\-_])
escape_seq (\\(.+))
ascii_escape_seq (\\[0-9a-fA-F]{1,6})
letter ([a-zA-Z])
s_num ([\+\-]?[0-9]+)
number ([0-9]+)
printable_char_but_double_commas_slash_n ([\x20-\x21\x23-\x5B\x5D-\x7E\x09])
printable_char_but_commas ([\x20-\x26\x28-\x5B\x5D-\x7E\x09])
partial_escape_sequences ((\\n)|(\\r)|(\\t)|(\\\\)|(\\[0-9a-fA-F]{1,6}))


%%
\/\* BEGIN(COMMENT);
<COMMENT>\/\*      show_comment_error();
<COMMENT>{printable_char}*\*\/ BEGIN(INITIAL); showCommentToken();

#({letter}|{number}|(-{letter})){identifier_char}* showToken("HASHID");
(\"({printable_char_but_double_commas_slash_n}|{partial_escape_sequences})*\")|('({printable_char_but_commas}|{partial_escape_sequences})*') showStringToken();


@import showToken("IMPORT");
!{ws}*[iI][mM][pP][oO][rR][tT][aA][nN][tT]        showToken("IMPORTANT");
[>\+~]                                            showToken("COMB");
:                                                 showToken("COLON");
;                                                 showToken("SEMICOLON");
\{                                                showToken("LBRACE");
\}                                                showToken("RBRACE");
\[                                                showToken("LBRACKET");
\]                                                showToken("RBRACKET");
=                                                 showToken("EQUAL");
\*                                                showToken("ASTERISK");
\.                                                showToken("DOT");
({s_num}|{hexadecimal_number})                    showToken("NUMBER");
(({digit}+)|({digit}*\.{digit}+))([a-z]+|%)       showToken("UNIT");
rgb({ws}*{s_num}{ws}*,{ws}*{s_num}{ws}*,{ws}*{s_num}{ws}*) showToken("RGB");


\"              print_error("unclosed string");
{escape_seq}    print_error("undefined escape sequence");
rgb             print_error("in rgb parameters");
%               print_error("%");
!               print_error("%");
@               print_error("@");
{ws} ;
<COMMENT>.      print_error("unclosed comment");
(\-)?[a-zA-Z]{identifier_char}* showToken("NAME");
%%

static int is_printable_char(int hex) {
  return (hex >= 0x20 && hex <= 0x7E)
  || hex == TAB
  || hex == CR
  || hex == LF;
}

static void shift_string(char *src, int index, int len) {
  for (char * p = src + index; *p != '\0'; p++) {
    *p = *(p+len);
  }
}

// Given a string and the length of a hex-escaped character, find it's
// ASCII value
static int find_ascii(char * str, int size) {
  char* escape_seq = malloc(sizeof(char) * (size + 1));
  strncpy(escape_seq, str, size);
  escape_seq[size] = '\0';
  int hex = strtol(escape_seq, NULL, 16);
  free(escape_seq);
  return hex;
}


static int format_next_escape_str(char *src) {
  char no_escape_char = *(src+1);
  if(no_escape_char == '\0'){
    return 0;
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
    return 0;
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
    return 1;
  }
  return 0;
}

// Format a STRING lexme and replace all escaped characters
// With real characters
static void format_string(char * src) {
  while (*src != '\0') {
    if (*src == '\\') {
      src += format_next_escape_str(src);
    }
    src++;
  }
}

// Remove the brackets of a STRING lexme
static void remove_brackets(char * dest, char * str, int size) {
  if (size < 2) {
    // Should not happen
    return;
  }
  int new_size = size - 2;
  strcpy(dest, ++str);
  dest[new_size] = '\0';
}

void showStringToken() {
  char * formatted = malloc(sizeof(char) * (yyleng - 1));
  int should_format = 1;
  if (yytext[0] == '\"') {
    should_format = 0;
  }

  remove_brackets(formatted, yytext, yyleng);
  if (should_format) {
    format_string(formatted);
  }
  showTokenMessage("STRING", formatted);

  free (formatted);
}

void showCommentToken() {
  char * comment = yytext;
  int lines = 1;
  while (*comment != '\0') {
    if (*comment == '\n' && *(comment + 1) == '\r') {
      lines++;
      comment++;
    } else if(*comment == '\n' || *comment == '\r') {
      lines++;
    }
    comment++;
  }
  printf("%d COMMENT %d\n", yylineno, lines);
}

void showTokenMessage(char * token, char * message) {
  // TODO Implement properly
  printf("%d %s %s\n", yylineno, token, message);
}

void showToken(char * name) {
  showTokenMessage(name, yytext);
}

void print_error(char * c_name) {
  // TODO Implement
  printf("Error %s\n", c_name);
  exit(0);
}

void print_escape_sequence_error() {
  // TODO: Fix not showing sequence
  printf("Error undefined escape sequence %s\n", yytext);
}

void show_comment_error() {
  printf("Warning nested comment");
  exit(0);
}
