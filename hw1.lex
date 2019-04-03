%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TAB   0x09
#define LF    0x0A
#define CR    0x0D

void showStringToken();
void showTokenMessage(char *, char *);
void showToken(char*);
void doCharError(char*);
void doError(char*);
%}


%option yylineno

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
\/\*{printable_char}*\*\/ showToken("COMMENT");
(\-)?[a-zA-Z]{identifier_char}* showToken("NAME");
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

% doCharError("%");
! doCharError("%");
@ doCharError("@");
{ws}+ ;
. doError("ERROR");
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

static int check_slash(char *src) {
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
    while (len < 6
      && ((p[len] >= '0' && p[len] <= '9')
      || (p[len] >= 'a' && p[len] <= 'f')
      || (p[len] >= 'A' && p[len] <= 'F')
      )) {
      len++;
    }
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
static void formatString(char * src) {
  while (*src != '\0') {
    if (*src == '\\') {
      src += check_slash(src);
    }
    src++;
  }
}

// Remove the brackets of a STRING lexme
static void removeBrackets(char * dest, char * str, int size) {
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

  removeBrackets(formatted, yytext, yyleng);
  if (should_format) {
    formatString(formatted);
  }
  showTokenMessage("STRING", formatted);

  free (formatted);
}

void showTokenMessage(char * token, char * message) {
  // TODO Implement properly
  printf("%d %s %s\n", yylineno, token, message);
}

void showToken(char * name) {
  showTokenMessage(name, yytext);
}

void doCharError(char * c_name) {
  // TODO Implement
  printf("Error %s\n", c_name);
  exit(0);
}

void doError(char * message) {
  // TODO Implement
  printf("Error %s\n", message);
  exit(0);
}
