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
%type<node> program programs methodDecl fieldDecl type methodHeader formalParams methodBody varDecl statement methodInvocation assignment parseArgs expr
%type<node_list> program_content


%left LOW
%left '+' '-'
%left '*' '/'

%union{
    char *lexeme;
    struct node *node;
}

/* START grammar rules section -- BNF grammar */

%%
programs: program                                                       { ast = $$ = $1;
                                                                            ast ->category = Program; }

program: CLASS IDENTIFIER LBRACE program_content RBRACE                 { $$ = newnode(Program, NULL);
                                                                            addchild($$, newnode(Identifier, $2));
                                                                            addchild($$, $4);    
    };

program_content:                                                        { $$ = newlist(); }
            | program_content methodDecl                                { $$ = $1;
                                                                            append($$, $2); }
            | program_content fieldDecl                                 { $$ = $1;
                                                                            append($$, $2); }
            | program_content SEMICOLON                                 { $$ = $1;          
    };

methodDecl: PUBLIC STATIC methodHeader methodBody                       { $$ = newnode(MethodDecl, NULL); 
                                                                            addchild($$, $3);
                                                                            addchild($$, $4); }; 
fieldDecl:  PUBLIC STATIC type IDENTIFIER fielDecl_content SEMICOLON    { $$ = newnode(FieldDecl, NULL);
                                                                            addchild($$, $3);
                                                                            addchild($$, newnode(Identifier, $4));
                                                                        } ;
fielDecl_content:                                                       { $$ = newnode(FieldDecl_content, NULL); }        
                |   COMMA IDENTIFIER                                    { $$ = $1;
                                                                            addchild($$, newnode(Identifier, $2)); 
                                                                        };
                                                                        
type:       BOOL                                                        { $$ = newnode(Type, NULL); 
                                                                            addchild($$, newnode(Bool, NULL)); }
        |   INT                                                         { $$ = newnode(Type, NULL); }
        |   DOUBLE                                                      { $$ = newnode(Type, NULL); }

methodHeader:       type IDENTIFIER LPAR formalParams RPAR              { $$ = newnode(MethodHeader, NULL); 
                                                                            addchild($$, $1);
                                                                            addchild($$, newnode(Identifier, $2));
                                                                            addchild($$, $4);
                                                                        };
                |   VOID IDENTIFIER LPAR formalParams RPAR              { $$ = newnode(MethodHeader, NULL); 
                                                                            addchild($$, newnode(Void, $1));
                                                                            addchild($$, newnode(Identifier, $2));
                                                                            addchild($$, $4);
                                                                        };
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
