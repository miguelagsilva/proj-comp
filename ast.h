#ifndef _AST_H
#define _AST_H

enum category {
    Program, 
    MethodDecl, 
    FieldDecl, 
    Type, 
    MethodHeader, 
    FormalParams, 
    MethodBody, 
    VarDecl, 
    Statement, 
    MethodInvocation, 
    Assignment, 
    ParseArgs, 
    Expr,
    Program_content,

    Boollit, 
    Reserved, 
    Natural, 
    Decimal, 
    Identifier, 
    Strlit,

    And, Assign, Star, Div, Eq, Ge, Gt, Le, Lt, 
    Minus, Mod, Ne, Not, Or, Plus, Arrow, Lshift, 
    Rshift, Xor, Dotlength,
    Comma, Lbrace, Lpar, Lsq, Rbrace, Rpar, Rsq, Semicolon,
    Bool, Double, Else, If, Int, Print, Parseint, 
    Public, Return, Static, String, Void, While,
};

struct node {
    enum category category;
    char *token;
    struct node_list *children;
};

struct node_list {
    struct node *node;
    struct node_list *next;
};

struct node *newnode(enum category category, char *token);
void addchild(struct node *parent, struct node *child);
void show(struct node *node, int depth);
#endif
