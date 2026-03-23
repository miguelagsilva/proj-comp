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
    "Program", "Function", "Parameters", "Parameter", "Arguments", 
    "Integer", "Double", "Identifier", "Natural", "Decimal", 
    "Call", "If", "Add", "Sub", "Mul", "Div"
};

void show(struct node *node, int depth) {
    if (node == NULL) return;

    for (int i = 0; i < depth; i++) {
        printf("__");
    }

    printf("%s", category_names[node->category]);

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