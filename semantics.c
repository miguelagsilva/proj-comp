#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "semantics.h"

SymbolTable *table_root = NULL; 
int semantic_errors = 0;

SemanticType category_to_type(enum category cat) {
    switch (cat) {
        case Int: return T_INT;
        case Double: return T_DOUBLE;
        case Bool: return T_BOOLEAN;
        case StringArray: return T_STRINGARRAY;
        case Void: return T_VOID;
        default: return T_NONE;
    }
}

const char* type_to_string(SemanticType type) {
    switch (type) {
        case T_INT: return "int";
        case T_DOUBLE: return "double";
        case T_BOOLEAN: return "boolean";
        case T_STRINGARRAY: return "String[]";
        case T_VOID: return "void";
        case T_UNDEF: return "undef";
        default: return "";
    }
}

SymbolTable* create_table(const char *name) {
    SymbolTable *new_table = (SymbolTable*)malloc(sizeof(SymbolTable));
    new_table->name = strdup(name);
    new_table->first_symbol = NULL;
    new_table->next = NULL;
    
    if (table_root == NULL) {
        table_root = new_table;
    } else {
        SymbolTable *curr = table_root;
        while (curr->next != NULL) curr = curr->next;
        curr->next = new_table;
    }
    return new_table;
}

Symbol* insert_symbol(SymbolTable *table, char *name, SemanticType type, int is_method, int is_param, ParamList *params, struct node *node) {
    
    Symbol *new_sym = (Symbol*)malloc(sizeof(Symbol));
    new_sym->name = strdup(name);
    new_sym->type = type;
    new_sym->is_method = is_method;
    new_sym->is_param = is_param;
    new_sym->param_types = params;
    new_sym->node = node;
    new_sym->next = NULL;
    
    if (table->first_symbol == NULL) {
        table->first_symbol = new_sym;
    } else {
        Symbol *curr = table->first_symbol;
        while (curr->next != NULL) curr = curr->next;
        curr->next = new_sym;
    }
    return new_sym;
}

ParamList* check_parameters(struct node *params_node, SymbolTable *local_table) {
    ParamList *head = NULL, *tail = NULL;
    
    struct node_list *child = params_node->children->next;
    while (child != NULL) {
        struct node *param_decl = child->node;           
        struct node *type_node = getchild(param_decl, 0); 
        struct node *id_node = getchild(param_decl, 1);   
        
        SemanticType p_type = category_to_type(type_node->category);
        
        ParamList *new_param = (ParamList*)malloc(sizeof(ParamList));
        new_param->type = p_type;
        new_param->next = NULL;
        if (head == NULL) { head = new_param; tail = new_param; }
        else { tail->next = new_param; tail = new_param; }
        
        insert_symbol(local_table, id_node->token, p_type, 0, 1, NULL, param_decl);
        
        child = child->next;
    }
    return head;
}

void check_method(struct node *method_decl, SymbolTable *global_table) {
    struct node *header = getchild(method_decl, 0);
    struct node *body = getchild(method_decl, 1);
    
    struct node *type_node = getchild(header, 0);
    struct node *id_node = getchild(header, 1);
    struct node *params_node = getchild(header, 2);
    
    SemanticType ret_type = category_to_type(type_node->category);
    
    SymbolTable *local_table = create_table("TEMP"); 
    
    insert_symbol(local_table, "return", ret_type, 0, 0, NULL, type_node);
    
    ParamList *p_list = check_parameters(params_node, local_table);
    
    char method_signature[512] = "";
    sprintf(method_signature, "Method %s(", id_node->token);
    ParamList *curr = p_list;
    while (curr != NULL) {
        strcat(method_signature, type_to_string(curr->type));
        if (curr->next != NULL) strcat(method_signature, ",");
        curr = curr->next;
    }
    strcat(method_signature, ")");
    
    free(local_table->name);
    local_table->name = strdup(method_signature);
    
    insert_symbol(global_table, id_node->token, ret_type, 1, 0, p_list, method_decl);
    
    struct node_list *body_child = body->children->next;
    while (body_child != NULL) {
        struct node *stmt = body_child->node;
        if (stmt->category == VarDecl) {
            struct node *v_type_node = getchild(stmt, 0);
            struct node *v_id_node = getchild(stmt, 1);
            insert_symbol(local_table, v_id_node->token, category_to_type(v_type_node->category), 0, 0, NULL, stmt);
        }
        body_child = body_child->next;
    }
}

void check_program(struct node *program) {
    if (program == NULL || program->category != Program) return;

    struct node *class_id = getchild(program, 0);
    
    char class_table_name[256];
    sprintf(class_table_name, "Class %s", class_id->token);
    SymbolTable *global_table = create_table(class_table_name);

    struct node_list *child = program->children->next; 
    while (child != NULL) {
        struct node *decl = child->node;
        
        if (decl->category == FieldDecl) {
            struct node *type_node = getchild(decl, 0);
            struct node *id_node = getchild(decl, 1);
            insert_symbol(global_table, id_node->token, category_to_type(type_node->category), 0, 0, NULL, decl);
        } 
        else if (decl->category == MethodDecl) {
            check_method(decl, global_table);
        }
        
        child = child->next;
    }
}

void print_symbol_tables() {
    SymbolTable *curr_table = table_root;
    while (curr_table != NULL) {
        printf("===== %s Symbol Table =====\n", curr_table->name);
        
        Symbol *curr_sym = curr_table->first_symbol;
        while (curr_sym != NULL) {
            printf("%s\t", curr_sym->name);
            
            if (curr_sym->is_method) {
                printf("(");
                ParamList *p = curr_sym->param_types;
                while (p != NULL) {
                    printf("%s", type_to_string(p->type));
                    if (p->next != NULL) printf(",");
                    p = p->next;
                }
                printf(")\t");
            }
            
            printf("%s", type_to_string(curr_sym->type));
            
            if (curr_sym->is_param) {
                printf("\tparam");
            }
            printf("\n");
            
            curr_sym = curr_sym->next;
        }
        
        if (curr_table->next != NULL) {
            printf("\n");
        }
        curr_table = curr_table->next;
    }
}