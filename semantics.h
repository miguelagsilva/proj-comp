#ifndef _SEMANTICS_H
#define _SEMANTICS_H

#include "ast.h"

typedef struct ParamList {
    SemanticType type;
    struct ParamList *next;
} ParamList;

typedef struct Symbol {
    char *name;
    SemanticType type;        
    int is_method;           
    int is_param;             
    ParamList *param_types;   
    struct node *node;        
    struct Symbol *next;
} Symbol;

typedef struct SymbolTable {
    char *name;               
    Symbol *first_symbol;
    struct SymbolTable *next;
} SymbolTable;

void check_program(struct node *program);
void print_symbol_tables();

#endif