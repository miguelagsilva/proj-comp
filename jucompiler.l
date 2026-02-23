%{
/* C variables */
int line = 1;
int column = 1;

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
empty      [ \t]
letter     [a-zA-Z_$]
digit      [0-9]
not_zero   [1-9]
stringlit   ([^\\\"\n\r]|\\[fnrt\\\"])*

/* Decimal Macros */
seq_digits {digit}(({digit}|_)*{digit})?
exponent ([eE][+-]?{seq_digits})

%X COMMENT

%%
"true"|"false"          { printf("BOOLLIT\n"); }
"&&"                    { printf("AND\n"); }
"="                     { printf("ASSIGN\n"); }
"*"                     { printf("STAR\n"); }
","                     { printf("COMMA\n"); }
"/"                     { printf("DIV\n"); }
"=="                    { printf("EQ\n"); }
">="                    { printf("GE\n"); }
">"                     { printf("GT\n"); }
"{"                     { printf("LBRACE\n"); }
"<="                    { printf("LE\n"); }
"("                     { printf("LPAR\n"); }
"["                     { printf("LSQ\n"); }
"<"                     { printf("LT\n"); }
"-"                     { printf("MINUS\n"); }
"%"                     { printf("MOD\n"); }
"!="                    { printf("NE\n"); }
"!"                     { printf("NOT\n"); }
"||"                    { printf("OR\n"); }
"+"                     { printf("PLUS\n"); }
"}"                     { printf("RBRACE\n"); }
")"                     { printf("RPAR\n"); }
"]"                     { printf("RSQ\n"); }
";"                     { printf("SEMICOLON\n"); }
"->"                    { printf("ARROW\n"); }
"<<"                    { printf("LSHIFT\n"); }
">>"                    { printf("RSHIFT\n"); }
"^"                     { printf("XOR\n"); }
"boolean"               { printf("BOOL\n"); }
"class"                 { printf("CLASS\n"); }
".length"               { printf("DOTLENGTH\n"); }
"double"                { printf("DOUBLE\n"); }
"else"                  { printf("ELSE\n"); }
"if"                    { printf("IF\n"); }
"int"                   { printf("INT\n"); }
"System.out.print"      { printf("PRINT\n"); }
"Integer.parseInt"      { printf("PARSEINT\n"); }
"public"                { printf("PUBLIC\n"); }
"return"                { printf("RETURN\n"); }
"static"                { printf("STATIC\n"); }
"String"                { printf("STRING\n"); }
"void"                  { printf("VOID\n"); }
"while"                 { printf("WHILE\n"); }
"++"|"--"|"null"|"Integer"|"System" { printf("RESERVERD\n"); }

{empty}                 { ; }
"\n"                    { ; }

0|({not_zero}(({digit}|"_")*{digit})?)               { printf("NATURAL(%s)\n", yytext); } /* 1____010 aceita? */


{seq_digits}"."{seq_digits}?{exponent}? |
"."{seq_digits}{exponent}?               |
{seq_digits}{exponent}               { printf("DECIMAL(%s)\n", yytext); }


{letter}({letter}|{digit})*        { printf("IDENTIFIER(%s)\n", yytext); }


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
\"{stringlit}\"  { printf("STRLIT(%s)\n", yytext); }

"/*"                    { BEGIN(COMMENT); }
<COMMENT>.              { ECHO; }
<COMMENT>\n             { printf(" "); }
<COMMENT>"*/"           { BEGIN(INITIAL); }

.                       { printf("Line %d, col %d: unrecognized character (%s)\n", line, column-yyleng, yytext);  }

%%
extern char *yytext;  /* the matched text */
extern int yyleng;
extern int yylex();

int main() {
    yylex();    /* run the lexical analysis automaton */
    return 0;
}
int yywrap() {  /* called on EOF, return 1 to terminate */
    return 1;
}
