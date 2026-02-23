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
"("                     { printf("(\n"); }
")"                     { printf(")\n"); }
"="                     { printf("=\n"); }
","                     { printf(",\n"); }
"*"                     { printf("*\n"); }
"/"                     { printf("/\n"); }
"+"                     { printf("+\n"); }
"-"                     { printf("-\n"); }

{empty}                 { ; }
"\n"                    { ; }

"integer"               { printf("INTEGER\n"); }
"double"                { printf("DOUBLE\n"); }
"if"                    { printf("IF\n"); }
"then"                  { printf("THEN\n"); }
"else"                  { printf("ELSE\n"); }

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
