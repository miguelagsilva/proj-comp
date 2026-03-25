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
%type<node> program programs methodDecl fieldDecl type methodHeader methodParams methodBody varDecl statement methodInvocation assignment parseArgs expr
%type<node_list> program_content fieldDecl_content methodParams_content methodBody_content


%left LOW
%left '+' '-'
%left '*' '/'

%union{
    char *lexeme;
    struct node *node;
    struct node_list *node_list;
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

methodHeader:       type IDENTIFIER LPAR methodParams RPAR              { $$ = newnode(MethodHeader, NULL); 
                                                                            addchild($$, $1);
                                                                            addchild($$, newnode(Identifier, $2));
                                                                            addchild($$, $4);
                                                                        }
                |   VOID IDENTIFIER LPAR methodParams RPAR              { $$ = newnode(MethodHeader, NULL); 
                                                                            addchild($$, newnode(Void, NULL));
                                                                            addchild($$, newnode(Identifier, $2));
                                                                            addchild($$, $4);
                                                                        };

methodParams:                                                           { $$ = newnode(MethodParams, NULL); }
                |   type IDENTIFIER methodParams_content                { $$ = newnode(MethodParams, NULL);
                                                                            addchild($$, $1);
                                                                            addchild($$, newnode(Identifier, $2));
                                                                            addchildren($$, $3);
                                                                        }  
                |   STRING LSQ RSQ IDENTIFIER                           { $$ = newnode(MethodParams, NULL);
                                                                            addchild($$, newnode(Identifier, $4));
                                                                        };    

methodParams_content:                                                   { $$ = newlist(); }
                |     methodParams_content COMMA type IDENTIFIER        { $$ = $1;
                                                                            append($$, $3);
                                                                            append($$, newnode(Identifier, $4));
                                                                        };

methodBody:     LBRACE methodBody_content RBRACE                        { $$ = newnode(MethodBody, NULL);
                                                                          addchildren($$, $2); } ;

methodBody_content:                                                     { $$ = newlist(); }
                | methodBody_content statement                          { $$ = $1;
                                                                          append($$, $2); }
                | methodBody_content varDecl                            { $$ = $1;
                                                                          append($$, $2); };

varDecl:        { $$ = NULL; } ;
statement:      { $$ = NULL; } ;
methodInvocation: { $$ = NULL; } ;
assignment:     { $$ = NULL; } ;
parseArgs:      { $$ = NULL; } ;
expr:           { $$ = NULL; } ;

%%

/* START subroutines section */

// all needed functions are collected in the .l and ast.* files
