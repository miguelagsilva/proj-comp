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
%type<node> program programs methodDecl type methodHeader methodParams methodBody statement methodInvocation assignment parseArgs expr paramDecl
%type<node_list> program_content fieldDecl paramDecl_list methodBody_content statement_list expr_list varDecl idList

%right ASSIGN
%left OR
%left XOR
%left AND
%left EQ NE
%left LT LE GT GE
%left LSHIFT RSHIFT
%left PLUS MINUS
%left STAR DIV MOD
%right NOT
%left DOTLENGTH

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%union {
    char *lexeme;
    struct node *node;
    struct node_list *node_list;
}

/* START grammar rules section -- BNF grammar */

%%

programs:
      program                                       { ast = $$ = $1;
                                                      ast->category = Program; }
    ;

program:
      CLASS IDENTIFIER LBRACE program_content RBRACE
                                                    { $$ = newnode(Program, NULL);
                                                      addchild($$, newnode(Identifier, $2));
                                                      addchildren($$, $4); }
    ;

program_content:
      /* empty */                                   { $$ = newlist(); }
    | program_content methodDecl                    { $$ = $1; append($$, $2); }
    | program_content fieldDecl                     { $$ = $1; appendlist($$, $2); }
    | program_content SEMICOLON                     { $$ = $1; }
    ;

methodDecl:
      PUBLIC STATIC methodHeader methodBody         { $$ = newnode(MethodDecl, NULL);
                                                      addchild($$, $3);
                                                      addchild($$, $4); }
    ;

fieldDecl:
      PUBLIC STATIC type idList SEMICOLON           { struct node_list *res = newlist();
                                                      struct node_list *current = $4->next;
                                                      while (current != NULL) {
                                                          struct node *new_field = newnode(FieldDecl, NULL);
                                                          struct node *new_type = newnode($3->category, NULL);
                                                          addchild(new_field, new_type);
                                                          addchild(new_field, current->node);
                                                          append(res, new_field);
                                                          current = current->next;
                                                      }
                                                      $$ = res; }
    | error SEMICOLON                 { $$ = newlist(); }
    ;

idList:
      IDENTIFIER                                    { $$ = newlist(); append($$, newnode(Identifier, $1)); }
    | idList COMMA IDENTIFIER                       { $$ = $1; append($$, newnode(Identifier, $3)); }
    ;

type:
      BOOL                                          { $$ = newnode(Bool, NULL); }
    | INT                                           { $$ = newnode(Int, NULL); }
    | DOUBLE                                        { $$ = newnode(Double, NULL); }
    ;

methodHeader:
      type IDENTIFIER LPAR methodParams RPAR        { $$ = newnode(MethodHeader, NULL);
                                                      addchild($$, $1);
                                                      addchild($$, newnode(Identifier, $2));
                                                      addchild($$, $4); }
    | VOID IDENTIFIER LPAR methodParams RPAR        { $$ = newnode(MethodHeader, NULL);
                                                      addchild($$, newnode(Void, NULL));
                                                      addchild($$, newnode(Identifier, $2));
                                                      addchild($$, $4); }
    ;

methodParams:
      /* empty */                                   { $$ = newnode(MethodParams, NULL); }
    | paramDecl paramDecl_list                      { $$ = newnode(MethodParams, NULL);
                                                      addchild($$, $1);
                                                      addchildren($$, $2); }
    | STRING LSQ RSQ IDENTIFIER                     { struct node *pd = newnode(ParamDecl, NULL);
                                                      addchild(pd, newnode(StringArray, NULL));
                                                      addchild(pd, newnode(Identifier, $4));
                                                      $$ = newnode(MethodParams, NULL);
                                                      addchild($$, pd); }
    ;

paramDecl:
      type IDENTIFIER                               { $$ = newnode(ParamDecl, NULL);
                                                      addchild($$, $1);
                                                      addchild($$, newnode(Identifier, $2)); }
    ;

paramDecl_list:
      /* empty */                                   { $$ = newlist(); }
    | paramDecl_list COMMA paramDecl                { $$ = $1; append($$, $3); }
    ;

methodBody:
      LBRACE methodBody_content RBRACE              { $$ = newnode(MethodBody, NULL);
                                                      addchildren($$, $2); }
    ;

methodBody_content:
      /* empty */                                   { $$ = newlist(); }
    | methodBody_content statement                  { $$ = $1; append($$, $2); }
    | methodBody_content varDecl                    { $$ = $1; appendlist($$, $2); }
    ;

varDecl:
      type idList SEMICOLON                         { struct node_list *result = newlist();
                                                      struct node_list *current = $2->next;
                                                      while (current != NULL) {
                                                          struct node *new_field = newnode(VarDecl, NULL);
                                                          struct node *new_type = newnode($1->category, NULL);
                                                          addchild(new_field, new_type);
                                                          addchild(new_field, current->node);
                                                          append(result, new_field);
                                                          current = current->next;
                                                      }
                                                      $$ = result; }
    ;

statement:
      LBRACE statement_list RBRACE                  { $$ = newnode(Block, NULL);
                                                      addchildren($$, $2); }
    | IF LPAR expr RPAR statement %prec LOWER_THAN_ELSE
                                                    { $$ = newnode(If, NULL);
                                                      addchild($$, $3);
                                                      addchild($$, $5 != NULL ? $5 : newnode(Block, NULL));
                                                      addchild($$, newnode(Block, NULL)); }
    | IF LPAR expr RPAR statement ELSE statement    { $$ = newnode(If, NULL);
                                                      addchild($$, $3);
                                                      addchild($$, $5 != NULL ? $5 : newnode(Block, NULL));
                                                      addchild($$, $7 != NULL ? $7 : newnode(Block, NULL)); }
    | WHILE LPAR expr RPAR statement                { $$ = newnode(While, NULL);
                                                      addchild($$, $3);
                                                      addchild($$, $5); }
    | RETURN expr SEMICOLON                         { $$ = newnode(Return, NULL);
                                                      addchild($$, $2); }
    | RETURN SEMICOLON                              { $$ = newnode(Return, NULL); }
    | methodInvocation SEMICOLON                    { $$ = $1; }
    | assignment SEMICOLON                          { $$ = $1; }
    | parseArgs SEMICOLON                           { $$ = $1; }
    | PRINT LPAR expr RPAR SEMICOLON                { $$ = newnode(Print, NULL);
                                                      addchild($$, $3); }
    | PRINT LPAR STRLIT RPAR SEMICOLON              { $$ = newnode(Print, NULL);
                                                      addchild($$, newnode(StrLit, $3)); }
    | error SEMICOLON                               { $$ = NULL; }
    ;

statement_list:
      /* empty */                                   { $$ = newlist(); }
    | statement_list statement                      { $$ = $1; append($$, $2); }
    ;

methodInvocation:
      IDENTIFIER LPAR RPAR                          { $$ = newnode(Call, $1);
                                                      addchild($$, newnode(Identifier, $1)); }
    | IDENTIFIER LPAR expr_list RPAR                { $$ = newnode(Call, NULL);
                                                      addchild($$, newnode(Identifier, $1));
                                                      addchildren($$, $3); }
    | IDENTIFIER LPAR error RPAR                    { $$ = NULL; }
    ;

assignment:
      IDENTIFIER ASSIGN expr                        { $$ = newnode(Assign, NULL);
                                                      addchild($$, newnode(Identifier, $1));
                                                      addchild($$, $3); }
    ;

parseArgs:
      PARSEINT LPAR IDENTIFIER LSQ expr RSQ RPAR    { $$ = newnode(ParseArgs, NULL);
                                                      addchild($$, newnode(Identifier, $3));
                                                      addchild($$, $5); }
    | PARSEINT LPAR error RPAR                      { $$ = NULL; }
    ;

expr:
      expr PLUS expr                                { $$ = newnode(Plus, NULL); addchild($$, $1); addchild($$, $3); }
    | expr MINUS expr                               { $$ = newnode(Minus, NULL); addchild($$, $1); addchild($$, $3); }
    | expr STAR expr                                { $$ = newnode(Mul, NULL); addchild($$, $1); addchild($$, $3); }
    | expr DIV expr                                 { $$ = newnode(Div, NULL); addchild($$, $1); addchild($$, $3); }
    | expr MOD expr                                 { $$ = newnode(Mod, NULL); addchild($$, $1); addchild($$, $3); }
    | expr AND expr                                 { $$ = newnode(And, NULL); addchild($$, $1); addchild($$, $3); }
    | expr OR expr                                  { $$ = newnode(Or, NULL); addchild($$, $1); addchild($$, $3); }
    | expr RSHIFT expr                              { $$ = newnode(Rshift, NULL); addchild($$, $1); addchild($$, $3); }
    | expr LSHIFT expr                              { $$ = newnode(Lshift, NULL); addchild($$, $1); addchild($$, $3); }
    | expr XOR expr                                 { $$ = newnode(Xor, NULL); addchild($$, $1); addchild($$, $3); }
    | expr EQ expr                                  { $$ = newnode(Eq, NULL); addchild($$, $1); addchild($$, $3); }
    | expr NE expr                                  { $$ = newnode(Ne, NULL); addchild($$, $1); addchild($$, $3); }
    | expr LT expr                                  { $$ = newnode(Lt, NULL); addchild($$, $1); addchild($$, $3); }
    | expr LE expr                                  { $$ = newnode(Le, NULL); addchild($$, $1); addchild($$, $3); }
    | expr GT expr                                  { $$ = newnode(Gt, NULL); addchild($$, $1); addchild($$, $3); }
    | expr GE expr                                  { $$ = newnode(Ge, NULL); addchild($$, $1); addchild($$, $3); }
    | PLUS expr                                     { $$ = newnode(Plus, NULL); addchild($$, $2); }
    | MINUS expr                                    { $$ = newnode(Minus, NULL); addchild($$, $2); }
    | NOT expr                                      { $$ = newnode(Not, NULL); addchild($$, $2); }
    | LPAR expr RPAR                                { $$ = $2; }
    | methodInvocation                              { $$ = $1; }
    | assignment                                    { $$ = $1; }
    | parseArgs                                     { $$ = $1; }
    | IDENTIFIER                                    { $$ = newnode(Identifier, $1); }
    | IDENTIFIER DOTLENGTH                          { $$ = newnode(Dotlength, NULL); addchild($$, newnode(Identifier, $1)); }
    | NATURAL                                       { $$ = newnode(DecLit, $1); }
    | DECIMAL                                       { $$ = newnode(RealLit, $1); }
    | BOOLLIT                                       { $$ = newnode(BoolLit, $1); }
    | LPAR error RPAR                               { $$ = NULL; }
    ;

expr_list:
      expr                                          { $$ = newlist(); append($$, $1); }
    | expr_list COMMA expr                          { $$ = $1; append($$, $3); }
    ;

%%

/* START subroutines section */

// all needed functions are collected in the .l and ast.* files
