%{
#include <stdarg.h>

/* C variables */
int line = 1;
int column = 1;
int print_tokens = 0;

/* C functions */
void process_command(int argc, char *argv[]) {
  if (argc > 2)        
    printf("Usage: %s [-l]\n", argv[0]);
  else if (argc == 2) {
    if (strcmp(argv[1], "-l") == 0) {
      print_tokens = 1;
    }
  } 
}
void print_token(const char* fmt, ...) {
  if (!print_tokens) return;
  va_list args;
  va_start(args, fmt);
  vprintf(fmt, args);
  va_end(args);
}

/* Track line and column for every token */
#define YY_USER_ACTION \
  do { \
    if (yytext[0] == '\n') { \
      line++; \
      column = 1; \
    } else { \
      column += yyleng; \
    } \
  } while(0);

%}

/* Define token patterns */
empty      [ \t\f\r]
letter     [a-zA-Z_$]
digit      [0-9]
not_zero   [1-9]
stringlit   ([^\\\"\n\r]|\\[fnrt\\\"])*

/* Decimal Macros */
seq_digits {digit}(({digit}|_)*{digit})?
exponent ([eE][+-]?{seq_digits})

%X COMMENT

%%
"true"|"false"          { print_token("BOOLLIT\n"); }
"&&"                    { print_token("AND\n"); }
"="                     { print_token("ASSIGN\n"); }
"*"                     { print_token("STAR\n"); }
","                     { print_token("COMMA\n"); }
"/"                     { print_token("DIV\n"); }
"=="                    { print_token("EQ\n"); }
">="                    { print_token("GE\n"); }
">"                     { print_token("GT\n"); }
"{"                     { print_token("LBRACE\n"); }
"<="                    { print_token("LE\n"); }
"("                     { print_token("LPAR\n"); }
"["                     { print_token("LSQ\n"); }
"<"                     { print_token("LT\n"); }
"-"                     { print_token("MINUS\n"); }
"%"                     { print_token("MOD\n"); }
"!="                    { print_token("NE\n"); }
"!"                     { print_token("NOT\n"); }
"||"                    { print_token("OR\n"); }
"+"                     { print_token("PLUS\n"); }
"}"                     { print_token("RBRACE\n"); }
")"                     { print_token("RPAR\n"); }
"]"                     { print_token("RSQ\n"); }
";"                     { print_token("SEMICOLON\n"); }
"->"                    { print_token("ARROW\n"); }
"<<"                    { print_token("LSHIFT\n"); }
">>"                    { print_token("RSHIFT\n"); }
"^"                     { print_token("XOR\n"); }
"boolean"               { print_token("BOOL\n"); }
"class"                 { print_token("CLASS\n"); }
".length"               { print_token("DOTLENGTH\n"); }
"double"                { print_token("DOUBLE\n"); }
"else"                  { print_token("ELSE\n"); }
"if"                    { print_token("IF\n"); }
"int"                   { print_token("INT\n"); }
"System.out.print"      { print_token("PRINT\n"); }
"Integer.parseInt"      { print_token("PARSEINT\n"); }
"public"                { print_token("PUBLIC\n"); }
"return"                { print_token("RETURN\n"); }
"static"                { print_token("STATIC\n"); }
"String"                { print_token("STRING\n"); }
"void"                  { print_token("VOID\n"); }
"while"                 { print_token("WHILE\n"); }
"++"|"--"|"null"|"Integer"|"System" { print_token("RESERVED\n"); }

{empty}                { ; }
"\n"                    { ; }

0|({not_zero}(({digit}|"_")*{digit})?)               { print_token("NATURAL(%s)\n", yytext); } /* 1____010 aceita? */

{seq_digits}"."{seq_digits}?{exponent}? |
"."{seq_digits}{exponent}?               |
{seq_digits}{exponent}               { print_token("DECIMAL(%s)\n", yytext); }

{letter}({letter}|{digit})*        { print_token("IDENTIFIER(%s)\n", yytext); }


\"{stringlit}\\[^fnrt\\\"\n\r]([^\\\"\n\r]|\\.)*\"  {
  int start_column = column - yyleng;
  for (int i = 1; i < yyleng - 1; i++) {
    if (yytext[i] == '\\') {
      char c = yytext[i+1];
      if (!(c=='f' || c=='n' || c=='r' || c=='t' || c=='\\' || c=='"')) {
        int pos = start_column + i;
        printf("Line %d, col %d: invalid escape sequence (\\%c)\n", line, pos, c);
        break;
      }
      i++;
    }
  }
}
\"{stringlit}\"  { print_token("STRLIT(%s)\n", yytext); }

"/*"                    { BEGIN(COMMENT); }
<COMMENT>.              { ECHO; }
<COMMENT>\n             { printf(" "); }
<COMMENT>"*/"           { BEGIN(INITIAL); }

.                       { printf("Line %d, col %d: unrecognized character (%s)\n", line, column-yyleng, yytext);  }

%%
extern char *yytext;  /* the matched text */
extern int yyleng;
extern int yylex();

int main(int argc, char *argv[]) {
  process_command(argc, argv);
  yylex();    /* run the lexical analysis automaton */
  return 0;
}
int yywrap() {  /* called on EOF, return 1 to terminate */
  return 1;
}
