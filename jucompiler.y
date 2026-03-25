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
%type<node_list> program_content fieldDecl_content formalParams_content


%left LOW
%left '+' '-'
%left '*' '/'

%union{
    char *lexeme;
    struct node *node;
    struct node_list *node_list
}

/* START grammar rules section -- BNF grammar */

%%
programs: program                                                       { ast = $$ = $1;
                                                                            ast ->category = Program; }

program: CLASS IDENTIFIER LBRACE program_content RBRACE                 { $$ = newnode(Program, NULL);
                                                                            addchild($$, newnode(Identifier, $2));
                                                                            addchildren($$, $4);    
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
fieldDecl:  PUBLIC STATIC type IDENTIFIER fieldDecl_content SEMICOLON    { $$ = newnode(FieldDecl, NULL);
                                                                            addchild($$, $3);
                                                                            addchild($$, newnode(Identifier, $4));
                                                                            addchildren($$, $5);
                                                                        };
fieldDecl_content:                                                       { $$ = newlist(); }       
                |   fieldDecl_content COMMA IDENTIFIER                  {
                                                                              $$ = $1;    
                                                                            append($$, newnode(Identifier, $3)); 
                                                                        };
                                                                        
type:       BOOL                                                        { $$ = newnode(Bool, NULL); }
        |   INT                                                         { $$ = newnode(Int, NULL); }
        |   DOUBLE                                                      { $$ = newnode(Double, NULL); };

methodHeader:       type IDENTIFIER LPAR formalParams RPAR              { $$ = newnode(MethodHeader, NULL); 
                                                                            addchild($$, $1);
                                                                            addchild($$, newnode(Identifier, $2));
                                                                            addchild($$, $4);
                                                                        }
                |   VOID IDENTIFIER LPAR formalParams RPAR              { $$ = newnode(MethodHeader, NULL); 
                                                                            addchild($$, newnode(Void, NULL));
                                                                            addchild($$, newnode(Identifier, $2));
                                                                            addchild($$, $4);
                                                                        };

formalParams:       type IDENTIFIER formalParams_content                { $$ = newnode(FormalParams, NULL);
                                                                            addchild($$, $1);
                                                                            addchild($$, newnode(Identifier, $2));
                                                                            addchildren($$, $3);
                                                                        }  
                |   STRING LSQ RSQ IDENTIFIER                           { $$ = newnode(FormalParams, NULL);
                                                                            addchild($$, newnode(Identifier, $4));
                                                                        };    

formalParams_content:                                                   { $$ = newlist(); }
                |     formalParams_content COMMA type IDENTIFIER        { $$ = $1;
                                                                            append($$, $3);
                                                                            append($$, newnode(Identifier, $4));
                                                                        }  

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
