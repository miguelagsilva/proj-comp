/* START definitions section -- C code delimited by %{ ... %} and token declarations */

%{

#include <stdio.h>
#include "ast.h"

int yylex(void);
void yyerror(char *);

struct node *ast;

%}

%token AND ASSIGN STAR COMMA DIV EQ GE GT LBRACE LE LPAR LSQ LT MINUS MOD NE NOT OR PLUS RBRACE RPAR RSQ SEMICOLON ARROW LSHIFT RSHIFT XOR BOOL CLASS DOTLENGTH DOUBLE ELSE IF INT PRINT PARSEINT PUBLIC RETURN STATIC STRING VOID WHILE
%token<lexeme> BOOLLIT RESERVED NATURAL DECIMAL IDENTIFIER STRLIT
%type<node> Program MethodDecl FieldDecl Type MethodHeader FormalParams FormalParams MethodBody VarDecl Statement MethodInvocation Assignment ParseArgs Expr

%left LOW
%left '+' '-'
%left '*' '/'

%union{
    char *lexeme;
    struct node *node;
}

/* START grammar rules section -- BNF grammar */

%%

program: CLASS IDENTIFIER LBRACE program_content RBRACE                  { ast = $$ = $1; 
                                                                           ast->category = Program; }
    ;

program_content:                            { $$ = newnode(program_content, NULL); }
            | program_content MethodDecl    { $$ = $1;
                                              addchild($$, $2); }
            | program_content FieldDecl     { $$ = $1;
                                              addchild($$, $2); }
            | program_content SEMICOLON     { $$ = $1;
                                              addchild($$, $2); }
    ;

functions: function                 { $$ = newnode(Program, NULL); 
                                      addchild($$, $1); }
    | functions function            { $$ = $1; 
                                      addchild($$, $2); }
    ;

function: IDENTIFIER '(' parameters ')' '=' expression
                                    { $$ = newnode(Function, NULL);
                                      addchild($$, newnode(Identifier, $1));
                                      addchild($$, $3);
                                      addchild($$, $6); }
    ;

parameters: parameter               { $$ = newnode(Parameters, NULL);
                                      addchild($$, $1); }
    | parameters ',' parameter      { $$ = $1;
                                      addchild($$, $3); }
    ;

parameter: INTEGER IDENTIFIER       { $$ = newnode(Parameter, NULL);
                                      addchild($$, newnode(Integer, NULL));
                                      addchild($$, newnode(Identifier, $2)); }
    | DOUBLE IDENTIFIER             { $$ = newnode(Parameter, NULL);
                                      addchild($$, newnode(Double, NULL));
                                      addchild($$, newnode(Identifier, $2)); }
    ;

arguments: expression               { $$ = newnode(Arguments, NULL);
                                      addchild($$, $1); }
    | arguments ',' expression      { $$ = $1;
                                      addchild($$, $3); }
    ;

expression: IDENTIFIER              { $$ = newnode(Identifier, $1); }
    | NATURAL                       { $$ = newnode(Natural, $1); }
    | DECIMAL                       { $$ = newnode(Decimal, $1); }
    | IDENTIFIER '(' arguments ')'  { $$ = newnode(Call, NULL);
                                      addchild($$, newnode(Identifier, $1));
                                      addchild($$, $3); }
    | IF expression THEN expression ELSE expression  %prec LOW
                                    { $$ = newnode(If, NULL);
                                      addchild($$, $2);
                                      addchild($$, $4);
                                      addchild($$, $6); }
    | expression '+' expression     { $$ = newnode(Add, NULL); addchild($$, $1); addchild($$, $3); }
    | expression '-' expression     { $$ = newnode(Sub, NULL); addchild($$, $1); addchild($$, $3); }
    | expression '*' expression     { $$ = newnode(Mul, NULL); addchild($$, $1); addchild($$, $3); }
    | expression '/' expression     { $$ = newnode(Div, NULL); addchild($$, $1); addchild($$, $3); }
    | '(' expression ')'            { $$ = $2; }  
    ;

%%

/* START subroutines section */

// all needed functions are collected in the .l and ast.* files
