#ifndef _AST_H
#define _AST_H

enum category {
    Program, 
    MethodDecl, 
    FieldDecl, 
    Type, 
    MethodHeader, 
    MethodParams, 
    MethodBody, 
    VarDecl, 
    Statement, 
    MethodInvocation, 
    Assignment, 
    ParseArgs, 
    Expr,

    Boollit, 
    Reserved, 
    DecLit, 
    RealLit, 
    Identifier, 
    StrLit,

    And, Assign, Star, Div, Mul, Eq, Ge, Gt, Le, Lt, 
    Minus, Mod, Ne, Not, Or, Plus, Arrow, Lshift, 
    Rshift, Xor, Dotlength,
    Comma, Lbrace, Lpar, Lsq, Rbrace, Rpar, Rsq, Semicolon,
    Bool, Double, Else, If, Int, Print, Parseint, 
    Public, Return, Static, String, Void, While,

    Block, Call, StringArray, ParamDecl
};

#define names { \
    "Program", \
    "MethodDecl", \
    "FieldDecl", \
    "Type", \
    "MethodHeader", \
    "MethodParams", \
    "MethodBody", \
    "VarDecl", \
    "Statement", \
    "MethodInvocation", \
    "Assignment", \
    "ParseArgs", \
    "Expr", \
    "Boollit", \
    "Reserved", \
    "DecLit", \
    "RealLit", \
    "Id", \
    "StrLit", \
    "And", "Assign", "Star", "Div", "Mul", "Eq", "Ge", "Gt", "Le", "Lt", \
    "Minus", "Mod", "Ne", "Not", "Or", "Plus", "Arrow", "Lshift", \
    "Rshift", "Xor", "Dotlength", \
    "Comma", "Lbrace", "Lpar", "Lsq", "Rbrace", "Rpar", "Rsq", "Semicolon", \
    "Bool", "Double", "Else", "If", "Int", "Print", "Parseint", \
    "Public", "Return", "Static", "String", "Void", "While", \
    "Block", "Call", "StringArray", "ParamDecl" \
}

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
struct node *getchild(struct node *parent, int position);
int countchildren(struct node *node);
struct node_list *newlist();
void append(struct node_list *list, struct node *node);
void addchildren(struct node *node, struct node_list *list);
void show(struct node *node, int depth);
#endif
