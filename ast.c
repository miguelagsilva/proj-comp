#include <stdlib.h>
#include <stdio.h>
#include "ast.h"

struct node *newnode(enum category category, char *token) {
    struct node *new = malloc(sizeof(struct node));
    new->category = category;
    new->token = token;
    new->type = T_NONE;
    new->annotated_type = NULL; 
    new->line = 0;
    new->column = 0;
    new->children = malloc(sizeof(struct node_list));
    new->children->node = NULL;
    new->children->next = NULL;
    return new;
}

void addchild(struct node *parent, struct node *child) {
    struct node_list *new = malloc(sizeof(struct node_list));
    new->node = child;
    new->next = NULL;
    struct node_list *children = parent->children;
    while(children->next != NULL)
        children = children->next;
    children->next = new;
}

struct node *getchild(struct node *parent, int position) {
    struct node_list *children = parent->children;
    while((children = children->next) != NULL)
        if(position-- == 0)
            return children->node;
    return NULL;
}

int countchildren(struct node *node) {
    int i = 0;
    while(getchild(node, i) != NULL)
        i++;
    return i;
}

struct node_list *newlist() {
    struct node_list *new = malloc(sizeof(struct node_list));
    new->node = NULL;
    new->next = NULL;
    return new;
}

void append(struct node_list *list, struct node *node) {
    struct node_list *new = malloc(sizeof(struct node_list));
    new->node = node;
    new->next = NULL;
    while(list->next != NULL)
        list = list->next;
    list->next = new;
}

void addchildren(struct node *node, struct node_list *list) {
    struct node_list *children = node->children;
    while(children->next != NULL)
        children = children->next;
    children->next = list->next;
    free(list);
}

const char *category_names[] = names;

void show(struct node *node, int depth) {
    if (node == NULL) return;

    for (int i = 0; i < depth; i++) {
        printf("..");
    }

    printf("%s", category_names[node->category]);

    if (node->token != NULL) {
        printf("(%s)", node->token);
    }

    if (node->annotated_type != NULL) {
        printf(" - %s", node->annotated_type);
    } else if (node->type != T_NONE) {
        switch (node->type) {
            case T_INT: printf(" - int"); break;
            case T_DOUBLE: printf(" - double"); break;
            case T_BOOLEAN: printf(" - boolean"); break;
            case T_STRING: printf(" - String"); break;   
            case T_STRINGARRAY: printf(" - String[]"); break;
            case T_VOID: printf(" - void"); break;
            case T_UNDEF: printf(" - undef"); break;
            default: break;
        }
    }

    printf("\n");

    struct node_list *child_ptr = node->children->next;
    while (child_ptr != NULL) {
        show(child_ptr->node, depth + 1);
        child_ptr = child_ptr->next;
    }
}

void appendlist(struct node_list *dst, struct node_list *src) {
    struct node_list *cur = src->next;  
    while (cur != NULL) {
        append(dst, cur->node);
        cur = cur->next;
    }
}

void free_ast(struct node *node) {
  if (node == NULL) {
    return;
  }
  struct node_list *child = node->children;
  while (child != NULL) {
    if (child->node != NULL) {
      free_ast(child->node);
    }
    struct node_list *temp = child;
    child = child->next;
    free(temp);
  }
  
  if (node->token != NULL) {
    free(node->token);
  }
  if (node->annotated_type != NULL) {
    free(node->annotated_type);
  }
  free(node);
}

struct node *newnode_loc(enum category category, char *token, int line, int column) {
    struct node *new = newnode(category, token);
    new->line = line;
    new->column = column;
    return new;
}