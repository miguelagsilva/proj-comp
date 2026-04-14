%{
#include <stdarg.h>

#include "y.tab.h"
#include "ast.h"

/* C functions */
int yyparse(void);
void yyerror(char *);

/* C variables */
extern struct node *ast;

int line = 1;
int column = 1;
int print_tokens = 0;
int flag_l = 0;
int flag_e1 = 0;
int flag_t = 0;
int flag_e2 = 0;
int comment_start_line = 0;
int comment_start_col = 0;
int syn_line = -1, syn_column = -1;
int errors = 0;

/* C functions */
void process_command(int argc, char *argv[]) {
  if (argc > 2)
    printf("Usage: %s [-l|-e1|-t|-e2]\n", argv[0]);
  else if (argc == 2) {
    if      (strcmp(argv[1], "-l")  == 0) flag_l  = 1;
    else if (strcmp(argv[1], "-e1") == 0) flag_e1 = 1;
    else if (strcmp(argv[1], "-t")  == 0) flag_t  = 1;
    else if (strcmp(argv[1], "-e2") == 0) flag_e2 = 1;
    else {
      printf("Unknown option: %s\n", argv[1]);
      exit(1);
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
    if (yytext[0] == '\n' || yytext[0] == '\r') { \
      line++; \
      column = 1; \
    } else { \
      column += yyleng; \
    } \
  } while(0);
/* We use this to return the values of tokens to parser */
#define PASS_TOKEN() \
  yylval.lexeme = strdup(yytext);

%}

/* Define token patterns */
empty      [ \t\f\r]
letter     [a-zA-Z_$]
digit      [0-9]
not_zero   [1-9]

/* String Macros */
ESCAPE \\[^\n\r]
VAL_ESCAPE \\[fnrt"\\]
TEXT [^\"\n\r\\]

STRLIT_OK \"({TEXT}|{VAL_ESCAPE})*\"
STRLIT_BAD \"({TEXT}|{ESCAPE})*\"
STRLIT_OPEN \"({TEXT}|{ESCAPE})*\\?

/* Decimal Macros */
seq_digits {digit}(({digit}|_)*{digit})?
exponent ([eE][+-]?{seq_digits})
%X COMMENT

%%
{empty}                { }

"true"|"false"          { PASS_TOKEN(); print_token("BOOLLIT(%s)\n", yytext); return BOOLLIT; }
"&&"                    { print_token("AND\n"); return AND; }
"="                     { print_token("ASSIGN\n"); return ASSIGN; }
"*"                     { print_token("STAR\n"); return STAR; }
","                     { print_token("COMMA\n"); return COMMA; }
"/"                     { print_token("DIV\n"); return DIV; }
"=="                    { print_token("EQ\n"); return EQ; }
">="                    { print_token("GE\n"); return GE; }
">"                     { print_token("GT\n"); return GT; }
"{"                     { print_token("LBRACE\n"); return LBRACE; }
"<="                    { print_token("LE\n"); return LE; }
"("                     { print_token("LPAR\n"); return LPAR; }
"["                     { print_token("LSQ\n"); return LSQ; }
"<"                     { print_token("LT\n"); return LT; }
"-"                     { print_token("MINUS\n"); return MINUS; }
"%"                     { print_token("MOD\n"); return MOD; }
"!="                    { print_token("NE\n"); return NE; }
"!"                     { print_token("NOT\n"); return NOT; }
"||"                    { print_token("OR\n"); return OR; }
"+"                     { print_token("PLUS\n"); return PLUS; }
"}"                     { print_token("RBRACE\n"); return RBRACE; }
")"                     { print_token("RPAR\n"); return RPAR; }
"]"                     { print_token("RSQ\n"); return RSQ; }
";"                     { print_token("SEMICOLON\n"); return SEMICOLON; }
"->"                    { print_token("ARROW\n"); return ARROW; }
"<<"                    { print_token("LSHIFT\n"); return LSHIFT; }
">>"                    { print_token("RSHIFT\n"); return RSHIFT; }
"^"                     { print_token("XOR\n"); return XOR; }
"boolean"               { print_token("BOOL\n"); return BOOL; }
"class"                 { print_token("CLASS\n"); return CLASS; }
".length"               { print_token("DOTLENGTH\n"); return DOTLENGTH; }
"double"                { print_token("DOUBLE\n"); return DOUBLE; }
"else"                  { print_token("ELSE\n"); return ELSE; }
"if"                    { print_token("IF\n"); return IF; }
"int"                   { print_token("INT\n"); return INT; }
"System.out.print"      { print_token("PRINT\n"); return PRINT; }
"Integer.parseInt"      { print_token("PARSEINT\n"); return PARSEINT; }
"public"                { print_token("PUBLIC\n"); return PUBLIC; }
"return"                { print_token("RETURN\n"); return RETURN; }
"static"                { print_token("STATIC\n"); return STATIC; }
"String"                { print_token("STRING\n"); return STRING; }
"void"                  { print_token("VOID\n"); return VOID; }
"while"                 { print_token("WHILE\n"); return WHILE; }
"++"|"--"|"null"|"Integer"|"System"|"for"|"abstract"|"continue"|"switch"|"assert"|"default"|"package"|"synchronized"|"do"|"goto"|"private"|"new"|"this"|"break"|"implements"|"protected"|"throw"|"byte"|"import"|"throws"|"case"|"enum"|"instanceof"|"transient"|"catch"|"extends"|"short"|"try"|"char"|"final"|"interface"|"finally"|"long"|"strictfp"|"volatile"|"const"|"float"|"native"|"super" { PASS_TOKEN(); print_token("RESERVED(%s)\n", yytext); return RESERVED;}


"\n"                    { ; }
"\r\n"                  { ; }

0|({not_zero}(({digit}|"_")*{digit})?)               { PASS_TOKEN(); print_token("NATURAL(%s)\n", yytext); return NATURAL; } 

{seq_digits}"."{seq_digits}?{exponent}? |
"."{seq_digits}{exponent}?               |
{seq_digits}{exponent}               { PASS_TOKEN(); print_token("DECIMAL(%s)\n", yytext); return DECIMAL; }

{letter}({letter}|{digit})* { PASS_TOKEN(); print_token("IDENTIFIER(%s)\n", yytext); return IDENTIFIER; }


{STRLIT_OK} {
    PASS_TOKEN();
    print_token("STRLIT(%s)\n", yytext);
    return STRLIT;
}

{STRLIT_BAD} {
    int i, start_col = column - yyleng;
    for (i = 1; i < yyleng - 1; i++) {
        if (yytext[i] == '\\') {
            if (i == yyleng - 1) { 
                 printf("Line %d, col %d: invalid escape sequence (\\)\n", line, start_col + i);
            } else {
                char c = yytext[i+1];
                if (c != 'f' && c != 'n' && c != 'r' && c != 't' && c != '"' && c != '\\') {
                  printf("Line %d, col %d: invalid escape sequence (\\%c)\n", line, start_col + i, c);
                }
                i++;
            }
        }
    }
}

{STRLIT_OPEN} {
    int i, start_col = column - yyleng;
    for (i = 1; i < yyleng; i++) {
        if (yytext[i] == '\\') {
            if (i == yyleng - 1) { 
                 printf("Line %d, col %d: invalid escape sequence (\\)\n", line, start_col + i);
            } else {
                char c = yytext[i+1];
                if (c != 'f' && c != 'n' && c != 'r' && c != 't' && c != '"' && c != '\\') {
                    printf("Line %d, col %d: invalid escape sequence (\\%c)\n", line, start_col + i, c);
                }
                i++;
            }
        }
    }
    printf("Line %d, col %d: unterminated string literal\n", line, start_col);
}


"/*"                    { BEGIN(COMMENT); comment_start_line = line; comment_start_col = column - yyleng; }
<COMMENT>"*/"           { BEGIN(INITIAL); }
<COMMENT>\r\n           { }
<COMMENT>\r             { }
<COMMENT>\n             { }
<COMMENT>.              { }
<COMMENT><<EOF>>        { 
                          printf("Line %d, col %d: unterminated comment\n", comment_start_line, comment_start_col); 
                          BEGIN(INITIAL); 
                        }
"//"[^\r\n]*            { }

.                       { printf("Line %d, col %d: illegal character (%s)\n", line, column-yyleng, yytext);  }

%%
extern char *yytext;  /* the matched text */
extern int yyleng;
extern int yylex();


void yyerror(char *error) {
    errors++;
    printf("Found %s '%s' (%d,%d)\n", error, yytext, syn_line, syn_column);
}
int main(int argc, char *argv[]) {
  process_command(argc, argv);

  if (flag_l || flag_e1) {
    print_tokens = flag_l;  // only print tokens if -l
    while (yylex() != 0);   // run lexer only
    return 0;
  }

  // all other flags: run full parse
  yyparse();

  if ((flag_t) && errors == 0) {
    show(ast, 0);
  }

  // no flag: only errors were already printed by yyerror/lexer
  return 0;
}
int yywrap() {  /* called on EOF, return 1 to terminate */
  return 1;
}
