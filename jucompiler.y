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
%type<node> program programs program_content methodDecl fieldDecl type methodHeader formalParams methodBody varDecl statement methodInvocation assignment parseArgs expr

%left LOW
%left '+' '-'
%left '*' '/'

%union{
    char *lexeme;
    struct node *node;
}

/* START grammar rules section -- BNF grammar */

%%
programs: program                                                        { ast = $$ = $1;
                                                                           ast ->category = Program; }

program: CLASS IDENTIFIER LBRACE program_content RBRACE                  { $$ = newnode(Program, NULL);
                                                                           addchild($$, newnode(Identifier, $2));
                                                                           addchild($$, $4);    
    };

program_content:                            { $$ = newnode(Program_content, NULL); }
            | program_content methodDecl    { $$ = $1;
                                              addchild($$, $2); }
            | program_content fieldDecl     { $$ = $1;
                                              addchild($$, $2); }
            | program_content SEMICOLON     { $$ = $1;          
    };

methodDecl:     { $$ = NULL; } ;
fieldDecl:      { $$ = NULL; } ;
type:           { $$ = NULL; } ;
methodHeader:   { $$ = NULL; } ;
formalParams:   { $$ = NULL; } ;
methodBody:     { $$ = NULL; } ;
varDecl:        { $$ = NULL; } ;
statement:      { $$ = NULL; } ;
methodInvocation: { $$ = NULL; } ;
assignment:     { $$ = NULL; } ;
parseArgs:      { $$ = NULL; } ;
expr:           { $$ = NULL; } ;

%%

/* START subroutines section */

// all needed functions are collected in the .l and ast.* files
