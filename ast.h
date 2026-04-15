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

    BoolLit, 
    Reserved, 
    DecLit, 
    RealLit, 
    Identifier, 
    StrLit,

    And, Assign, Star, Div, Mul, Eq, Ge, Gt, Le, Lt, 
    Sub, Minus, Mod, Ne, Not, Or, Plus, Add, Arrow, Lshift, 
    Rshift, Xor, Length,
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
    "BoolLit", \
    "Reserved", \
    "Natural", \
    "Decimal", \
    "Identifier", \
    "StrLit", \
    "And", "Assign", "Star", "Div", "Mul", "Eq", "Ge", "Gt", "Le", "Lt", \
    "Sub", "Minus", "Mod", "Ne", "Not", "Or", "Plus", "Add", "Arrow", "Lshift", \
    "Rshift", "Xor", "Length", \
    "Comma", "Lbrace", "Lpar", "Lsq", "Rbrace", "Rpar", "Rsq", "Semicolon", \
    "Bool", "Double", "Else", "If", "Int", "Print", "Parseint", \
    "Public", "Return", "Static", "String", "Void", "While", \
    "Block", "Call", "StringArray", "ParamDecl" \
}

typedef enum {
    T_NONE,
    T_INT,
    T_DOUBLE,
    T_BOOLEAN,
    T_STRINGARRAY,
    T_VOID,
    T_UNDEF
} SemanticType;

struct node {
    enum category category;
    char *token;
    SemanticType type;
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
void appendlist(struct node_list *dst, struct node_list *src);
void free_ast(struct node *node);
#endif
