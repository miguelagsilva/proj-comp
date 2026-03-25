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
%type<node> Program Programs program_content MethodDecl FieldDecl Type MethodHeader FormalParams MethodBody VarDecl Statement MethodInvocation Assignment ParseArgs Expr

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

program: CLASS IDENTIFIER LBRACE program_content RBRACE                  { $$ = newnode(Program, Null);
                                                                           addchild($$, newnode(Identifier, $2));
                                                                           addchild($$, $4);    
    };

program_content:                            { $$ = newnode(Program_content, NULL); }
            | program_content MethodDecl    { $$ = $1;
                                              addchild($$, $2); }
            | program_content FieldDecl     { $$ = $1;
                                              addchild($$, $2); }
            | program_content SEMICOLON     { $$ = $1;          
    };


%%

/* START subroutines section */

// all needed functions are collected in the .l and ast.* files
