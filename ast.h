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

    BOOLLIT, 
    RESERVED, 
    NATURAL, 
    DECIMAL, 
    IDENTIFIER, 
    STRLIT,

    AND, ASSIGN, STAR, DIV, EQ, GE, GT, LE, LT, 
    MINUS, MOD, NE, NOT, OR, PLUS, ARROW, LSHIFT, 
    RSHIFT, XOR, DOTLENGTH,
    COMMA, LBRACE, LPAR, LSQ, RBRACE, RPAR, RSQ, SEMICOLON,
    BOOL, CLASS, DOUBLE, ELSE, IF, INT, PRINT, PARSEINT, 
    PUBLIC, RETURN, STATIC, STRING, VOID, WHILE,
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
