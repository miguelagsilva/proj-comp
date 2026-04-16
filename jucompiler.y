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
%type<node> program programs methodDecl type methodHeader methodParams methodBody statement methodInvocation assignment parseArgs expr paramDecl expr1
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

%locations

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
    | error SEMICOLON                               { $$ = newlist(); }
    ;

idList:
      IDENTIFIER                                    { $$ = newlist(); append($$, newnode_loc(Identifier, $1, @1.first_line, @1.first_column)); }
    | idList COMMA IDENTIFIER                       { $$ = $1; append($$, newnode_loc(Identifier, $3, @3.first_line, @3.first_column)); }
    ;

type:
      BOOL                                          { $$ = newnode(Bool, NULL); }
    | INT                                           { $$ = newnode(Int, NULL); }
    | DOUBLE                                        { $$ = newnode(Double, NULL); }
    ;

methodHeader:
      type IDENTIFIER LPAR methodParams RPAR        { $$ = newnode(MethodHeader, NULL);
                                                      addchild($$, $1);
                                                      addchild($$, newnode_loc(Identifier, $2, @2.first_line, @2.first_column));
                                                      addchild($$, $4); }
    | VOID IDENTIFIER LPAR methodParams RPAR        { $$ = newnode(MethodHeader, NULL);
                                                      addchild($$, newnode(Void, NULL));
                                                      addchild($$, newnode_loc(Identifier, $2, @2.first_line, @2.first_column));
                                                      addchild($$, $4); }
    ;

methodParams:
      /* empty */                                   { $$ = newnode(MethodParams, NULL); }
    | paramDecl paramDecl_list                      { $$ = newnode(MethodParams, NULL);
                                                      addchild($$, $1);
                                                      addchildren($$, $2); }
    | STRING LSQ RSQ IDENTIFIER                     { struct node *pd = newnode(ParamDecl, NULL);
                                                      addchild(pd, newnode(StringArray, NULL));
                                                      addchild(pd, newnode_loc(Identifier, $4, @4.first_line, @4.first_column));
                                                      $$ = newnode(MethodParams, NULL);
                                                      addchild($$, pd); }
    ;

paramDecl:
      type IDENTIFIER                               { $$ = newnode(ParamDecl, NULL);
                                                      addchild($$, $1);
                                                      addchild($$, newnode_loc(Identifier, $2, @2.first_line, @2.first_column)); }
    ;

paramDecl_list:
      /* empty */                                   { $$ = newlist(); }
    | paramDecl_list COMMA paramDecl                { $$ = $1; append($$, $3); }
    ;

methodBody:
      LBRACE methodBody_content RBRACE              { $$ = newnode(MethodBody, NULL); addchildren($$, $2); }
    ;

methodBody_content:
      /* empty */                                   { $$ = newlist(); }
    | methodBody_content statement                  { $$ = $1; if ($2 != NULL) append($$, $2); }
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
      LBRACE statement_list RBRACE                  { struct node_list *cur = $2->next;
                                                      int count = 0; struct node *single = NULL;
                                                      while (cur != NULL) { count++; single = cur->node; cur = cur->next; }
                                                      if (count == 1) { $$ = single; }
                                                      else if (count == 0) { $$ = NULL; }
                                                      else { $$ = newnode(Block, NULL); addchildren($$, $2); } }
    | IF LPAR expr RPAR statement %prec LOWER_THAN_ELSE
                                                    { $$ = newnode_loc(If, NULL, @1.first_line, @1.first_column);
                                                      addchild($$, $3); addchild($$, $5 != NULL ? $5 : newnode(Block, NULL)); addchild($$, newnode(Block, NULL)); }
    | IF LPAR expr RPAR statement ELSE statement    { $$ = newnode_loc(If, NULL, @1.first_line, @1.first_column);
                                                      addchild($$, $3); addchild($$, $5 != NULL ? $5 : newnode(Block, NULL)); addchild($$, $7 != NULL ? $7 : newnode(Block, NULL)); }
    | WHILE LPAR expr RPAR statement                { $$ = newnode_loc(While, NULL, @1.first_line, @1.first_column);
                                                      addchild($$, $3); addchild($$, $5 != NULL ? $5 : newnode(Block, NULL)); }
    | RETURN expr SEMICOLON                         { $$ = newnode_loc(Return, NULL, @1.first_line, @1.first_column); addchild($$, $2); }
    | RETURN SEMICOLON                              { $$ = newnode_loc(Return, NULL, @1.first_line, @1.first_column); }
    | methodInvocation SEMICOLON                    { $$ = $1; }
    | assignment SEMICOLON                          { $$ = $1; }
    | parseArgs SEMICOLON                           { $$ = $1; }
    | PRINT LPAR expr RPAR SEMICOLON                { $$ = newnode_loc(Print, NULL, @1.first_line, @1.first_column); addchild($$, $3); }
    | PRINT LPAR STRLIT RPAR SEMICOLON              { $$ = newnode_loc(Print, NULL, @1.first_line, @1.first_column); addchild($$, newnode_loc(StrLit, $3, @3.first_line, @3.first_column)); }
    | SEMICOLON                                     { $$ = NULL; }
    | error SEMICOLON                               { $$ = NULL; }
    ;

statement_list:
      /* empty */                                   { $$ = newlist(); }
    | statement_list statement                      { $$ = $1; if ($2 != NULL) append($$, $2); }
    ;

methodInvocation:
      IDENTIFIER LPAR RPAR                          { $$ = newnode_loc(Call, NULL, @1.first_line, @1.first_column); addchild($$, newnode_loc(Identifier, $1, @1.first_line, @1.first_column)); }
    | IDENTIFIER LPAR expr_list RPAR                { $$ = newnode_loc(Call, NULL, @1.first_line, @1.first_column); addchild($$, newnode_loc(Identifier, $1, @1.first_line, @1.first_column)); addchildren($$, $3); }
    | IDENTIFIER LPAR error RPAR                    { $$ = NULL; }
    ;

assignment:
      IDENTIFIER ASSIGN expr                        { $$ = newnode_loc(Assign, NULL, @2.first_line, @2.first_column); addchild($$, newnode_loc(Identifier, $1, @1.first_line, @1.first_column)); addchild($$, $3); }
    ;

parseArgs:
      PARSEINT LPAR IDENTIFIER LSQ expr RSQ RPAR    { $$ = newnode_loc(ParseArgs, NULL, @1.first_line, @1.first_column); addchild($$, newnode_loc(Identifier, $3, @3.first_line, @3.first_column)); addchild($$, $5); }
    | PARSEINT LPAR error RPAR                      { $$ = NULL; }
    ;

expr:
      assignment                                    { $$ = $1; }
    | expr1                                         { $$ = $1; }
    ;

expr1:
      expr1 PLUS expr1                              { $$ = newnode_loc(Add, NULL, @2.first_line, @2.first_column); addchild($$, $1); addchild($$, $3); }
    | expr1 MINUS expr1                             { $$ = newnode_loc(Sub, NULL, @2.first_line, @2.first_column); addchild($$, $1); addchild($$, $3); }
    | expr1 STAR expr1                              { $$ = newnode_loc(Mul, NULL, @2.first_line, @2.first_column); addchild($$, $1); addchild($$, $3); }
    | expr1 DIV expr1                               { $$ = newnode_loc(Div, NULL, @2.first_line, @2.first_column); addchild($$, $1); addchild($$, $3); }
    | expr1 MOD expr1                               { $$ = newnode_loc(Mod, NULL, @2.first_line, @2.first_column); addchild($$, $1); addchild($$, $3); }
    | expr1 AND expr1                               { $$ = newnode_loc(And, NULL, @2.first_line, @2.first_column); addchild($$, $1); addchild($$, $3); }
    | expr1 OR expr1                                { $$ = newnode_loc(Or, NULL, @2.first_line, @2.first_column); addchild($$, $1); addchild($$, $3); }
    | expr1 RSHIFT expr1                            { $$ = newnode_loc(Rshift, NULL, @2.first_line, @2.first_column); addchild($$, $1); addchild($$, $3); }
    | expr1 LSHIFT expr1                            { $$ = newnode_loc(Lshift, NULL, @2.first_line, @2.first_column); addchild($$, $1); addchild($$, $3); }
    | expr1 XOR expr1                               { $$ = newnode_loc(Xor, NULL, @2.first_line, @2.first_column); addchild($$, $1); addchild($$, $3); }
    | expr1 EQ expr1                                { $$ = newnode_loc(Eq, NULL, @2.first_line, @2.first_column); addchild($$, $1); addchild($$, $3); }
    | expr1 NE expr1                                { $$ = newnode_loc(Ne, NULL, @2.first_line, @2.first_column); addchild($$, $1); addchild($$, $3); }
    | expr1 LT expr1                                { $$ = newnode_loc(Lt, NULL, @2.first_line, @2.first_column); addchild($$, $1); addchild($$, $3); }
    | expr1 LE expr1                                { $$ = newnode_loc(Le, NULL, @2.first_line, @2.first_column); addchild($$, $1); addchild($$, $3); }
    | expr1 GT expr1                                { $$ = newnode_loc(Gt, NULL, @2.first_line, @2.first_column); addchild($$, $1); addchild($$, $3); }
    | expr1 GE expr1                                { $$ = newnode_loc(Ge, NULL, @2.first_line, @2.first_column); addchild($$, $1); addchild($$, $3); }
    | PLUS expr1 %prec NOT                          { $$ = newnode_loc(Plus, NULL, @1.first_line, @1.first_column); addchild($$, $2); }
    | MINUS expr1 %prec NOT                         { $$ = newnode_loc(Minus, NULL, @1.first_line, @1.first_column); addchild($$, $2); }
    | NOT expr1                                     { $$ = newnode_loc(Not, NULL, @1.first_line, @1.first_column); addchild($$, $2); }
    | LPAR expr RPAR                                { $$ = $2; }
    | methodInvocation                              { $$ = $1; }
    | parseArgs                                     { $$ = $1; }
    | IDENTIFIER                                    { $$ = newnode_loc(Identifier, $1, @1.first_line, @1.first_column); }
    | IDENTIFIER DOTLENGTH                          { $$ = newnode_loc(Length, NULL, @2.first_line, @2.first_column); addchild($$, newnode_loc(Identifier, $1, @1.first_line, @1.first_column)); }
    | NATURAL                                       { $$ = newnode_loc(DecLit, $1, @1.first_line, @1.first_column); }
    | DECIMAL                                       { $$ = newnode_loc(RealLit, $1, @1.first_line, @1.first_column); }
    | BOOLLIT                                       { $$ = newnode_loc(BoolLit, $1, @1.first_line, @1.first_column); }
    | LPAR error RPAR                               { $$ = NULL; }
    ;

expr_list:
      expr                                          { $$ = newlist(); append($$, $1); }
    | expr_list COMMA expr                          { $$ = $1; append($$, $3); }
    ;
%%

/* START subroutines section */

// all needed functions are collected in the .l and ast.* files
