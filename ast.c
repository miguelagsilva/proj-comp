#include <stdlib.h>
#include <stdio.h>
#include "ast.h"

// create a node of a given category with a given lexical symbol
struct node *newnode(enum category category, char *token) {
    struct node *new = malloc(sizeof(struct node));
    new->category = category;
    new->token = token;
    new->children = malloc(sizeof(struct node_list));
    new->children->node = NULL;
    new->children->next = NULL;
    return new;
}

// append a node to the list of children of the parent node
void addchild(struct node *parent, struct node *child) {
    struct node_list *new = malloc(sizeof(struct node_list));
    new->node = child;
    new->next = NULL;
    struct node_list *children = parent->children;
    while(children->next != NULL)
        children = children->next;
    children->next = new;
}

const char *category_names[] = {
    // Não-terminais
    "Program", 
    "MethodDecl", 
    "FieldDecl", 
    "Type", 
    "MethodHeader", 
    "FormalParams", 
    "MethodBody", 
    "VarDecl", 
    "Statement", 
    "MethodInvocation", 
    "Assignment", 
    "ParseArgs", 
    "Expr",

    // Literais
    "BOOLLIT", 
    "RESERVED", 
    "NATURAL", 
    "DECIMAL", 
    "IDENTIFIER", 
    "STRLIT",

    // Operadores
    "AND", "ASSIGN", "STAR", "DIV", "EQ", "GE", "GT", "LE", "LT", 
    "MINUS", "MOD", "NE", "NOT", "OR", "PLUS", "ARROW", "LSHIFT", 
    "RSHIFT", "XOR", "DOTLENGTH",
    
    "COMMA", "LBRACE", "LPAR", "LSQ", "RBRACE", "RPAR", "RSQ", "SEMICOLON",
    
    // Palavras-chave / Tipos
    "BOOL", "CLASS", "DOUBLE", "ELSE", "IF", "INT", "PRINT", "PARSEINT", 
    "PUBLIC", "RETURN", "STATIC", "STRING", "VOID", "WHILE"
};
void show(struct node *node, int depth) {
    if (node == NULL) return;

    for (int i = 0; i < depth; i++) {
        printf("__");
    }

    printf("%s  [%d]", category_names[node->category], node->category);

    if (node->token != NULL) {
        printf("(%s)", node->token);
    }
    printf("\n");

    struct node_list *child_ptr = node->children->next;
    while (child_ptr != NULL) {
        show(child_ptr->node, depth + 1);
        child_ptr = child_ptr->next;
    }
}
