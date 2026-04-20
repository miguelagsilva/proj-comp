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

Symbol* search_local(SymbolTable *table, char *name) {
    Symbol *curr = table->first_symbol;
    while (curr != NULL) {
        if (strcmp(curr->name, name) == 0) return curr;
        curr = curr->next;
    }
    return NULL;
}

Symbol* insert_symbol(SymbolTable *table, char *name, SemanticType type, int is_method, int is_param, ParamList *params, struct node *node) {
    
    if (strcmp(name, "return") != 0 && search_local(table, name) != NULL) {
        printf("Line %d, col %d: Symbol %s already defined\n", node->line, node->column, name);
        semantic_errors++;
        return NULL; 
    }

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

Symbol* search_variable(SymbolTable *local, SymbolTable *global, char *name) {
    Symbol *sym;
    if (local != NULL) {
        sym = local->first_symbol;
        while (sym != NULL) {
            if (strcmp(sym->name, name) == 0 && sym->is_method == 0) return sym;
            sym = sym->next;
        }
    }
    if (global != NULL) {
        sym = global->first_symbol;
        while (sym != NULL) {
            if (strcmp(sym->name, name) == 0 && sym->is_method == 0) return sym;
            sym = sym->next;
        }
    }
    return NULL; 
}

Symbol* search_method(SymbolTable *global, char *name) {
    if (global != NULL) {
        Symbol *sym = global->first_symbol;
        while (sym != NULL) {
            if (strcmp(sym->name, name) == 0 && sym->is_method == 1) return sym;
            sym = sym->next;
        }
    }
    return NULL;
}

void check_expression(struct node *expr, SymbolTable *local_table, SymbolTable *global_table) {
    if (expr == NULL) return;

    struct node_list *child = expr->children->next;

    if (expr->category == Call && child != NULL) {
        child = child->next;
    }

    while (child != NULL) {
        check_expression(child->node, local_table, global_table);
        child = child->next;
    }

    switch (expr->category) {
        case DecLit:   expr->type = T_INT; break;
        case RealLit:  expr->type = T_DOUBLE; break;
        case BoolLit:  expr->type = T_BOOLEAN; break;

        case Identifier: {
            Symbol *sym = search_variable(local_table, global_table, expr->token);
            if (sym != NULL) {
                expr->type = sym->type;
            } else {
                expr->type = T_UNDEF;  
                printf("Line %d, col %d: Cannot find symbol %s\n", expr->line, expr->column, expr->token);
                semantic_errors++;
            }
            break;
        }

        case Assign: {
            struct node *left = getchild(expr, 0);
            struct node *right = getchild(expr, 1);
            if (left != NULL && right != NULL) {
                expr->type = left->type; 
                
                int compatible = 0;
                if (left->type != T_UNDEF && right->type != T_UNDEF) {
                    if (left->type == right->type) compatible = 1;
                    else if (left->type == T_DOUBLE && right->type == T_INT) compatible = 1;
                }
                
                if (!compatible) {
                    printf("Line %d, col %d: Operator = cannot be applied to types %s, %s\n", 
                           expr->line, expr->column, type_to_string(left->type), type_to_string(right->type));
                    semantic_errors++;
                }
            }
            break;
        }
        case Call: {
            struct node *id_node = getchild(expr, 0);
            if (id_node != NULL) {
                SemanticType arg_types[50];
                int num_args = 0;
                struct node_list *call_child = expr->children->next; 
                struct node_list *curr_arg = call_child->next;      
                
                while (curr_arg != NULL) {
                    arg_types[num_args++] = curr_arg->node->type;
                    curr_arg = curr_arg->next;
                }
                
                char args_str[512] = "";
                for(int i=0; i<num_args; i++) {
                    strcat(args_str, type_to_string(arg_types[i]));
                    if(i < num_args - 1) strcat(args_str, ",");
                }

                Symbol *exact_match = NULL;
                Symbol *compatible_match = NULL;
                int exact_count = 0;
                int compatible_count = 0;
                
                if (global_table != NULL) {
                    Symbol *sym = global_table->first_symbol;
                    while (sym != NULL) {
                        if (sym->is_method == 1 && strcmp(sym->name, id_node->token) == 0) {
                            int param_count = 0;
                            ParamList *p = sym->param_types;
                            int is_exact = 1, is_compatible = 1;
                            
                            while (p != NULL && param_count < num_args) {
                                if (p->type != arg_types[param_count]) {
                                    is_exact = 0;
                                    if (!(p->type == T_DOUBLE && arg_types[param_count] == T_INT)) {
                                        is_compatible = 0;
                                    }
                                }
                                p = p->next;
                                param_count++;
                            }
                            
                            if (p == NULL && param_count == num_args) { 
                                if (is_exact) {
                                    exact_match = sym;
                                    exact_count++;
                                } else if (is_compatible) {
                                    compatible_match = sym;
                                    compatible_count++;
                                }
                            }
                        }
                        sym = sym->next;
                    }
                }
                
                Symbol *resolved = NULL;
                if (exact_count == 1) {
                    resolved = exact_match;
                } else if (exact_count == 0 && compatible_count == 1) {
                    resolved = compatible_match;
                } else if (exact_count > 1 || compatible_count > 1) {
                    printf("Line %d, col %d: Reference to method %s is ambiguous\n", id_node->line, id_node->column, id_node->token);
                    semantic_errors++;
                } else {
                    printf("Line %d, col %d: Cannot find symbol %s(%s)\n", id_node->line, id_node->column, id_node->token, args_str);
                    semantic_errors++;
                }
                
                if (resolved != NULL) {
                    expr->type = resolved->type;
                    
                    char annot[512] = "(";
                    ParamList *p = resolved->param_types;
                    while (p != NULL) {
                        strcat(annot, type_to_string(p->type));
                        if (p->next != NULL) strcat(annot, ",");
                        p = p->next;
                    }
                    strcat(annot, ")");
                    id_node->annotated_type = strdup(annot); 
                    
                } else {
                    expr->type = T_UNDEF;
                    id_node->type = T_UNDEF;
                }
            }
            break;
        }

        case ParseArgs:
        case Length: {
            expr->type = T_INT;
            break;
        }

        case Add:
        case Sub:
        case Mul:
        case Div:
        case Mod: {
            struct node *left = getchild(expr, 0);
            struct node *right = getchild(expr, 1);
            if (left == NULL || right == NULL) break;

            if (left->type == T_INT && right->type == T_INT) {
                expr->type = T_INT;
            } else if ((left->type == T_DOUBLE && right->type == T_INT) ||
                       (left->type == T_INT && right->type == T_DOUBLE) ||
                       (left->type == T_DOUBLE && right->type == T_DOUBLE)) {
                expr->type = T_DOUBLE;
            } else {
                expr->type = T_UNDEF;
                
                char *op = "";
                if (expr->category == Add) op = "+";
                else if (expr->category == Sub) op = "-";
                else if (expr->category == Mul) op = "*";
                else if (expr->category == Div) op = "/";
                else if (expr->category == Mod) op = "%";
                
                printf("Line %d, col %d: Operator %s cannot be applied to types %s, %s\n", 
                       expr->line, expr->column, op, type_to_string(left->type), type_to_string(right->type));
                semantic_errors++;
            }
            break;
        }

        case Eq: case Ne: case Lt: case Gt: case Le: case Ge: {
            expr->type = T_BOOLEAN; 
            break;
        }

        case Return: {
            struct node *ret_expr = getchild(expr, 0);
            Symbol *ret_sym = search_local(local_table, "return");
            SemanticType expected_type = ret_sym ? ret_sym->type : T_VOID;

            if (ret_expr != NULL) {
                SemanticType actual_type = ret_expr->type;
                int compatible = 0;
                
                if (actual_type != T_UNDEF) {
                    if (expected_type == actual_type) compatible = 1;
                    else if (expected_type == T_DOUBLE && actual_type == T_INT) compatible = 1;
                }
                
                if (!compatible) {
                    printf("Line %d, col %d: Incompatible type %s in return statement\n", 
                           ret_expr->line, ret_expr->column, type_to_string(actual_type));
                    semantic_errors++;
                }
            } else {
                if (expected_type != T_VOID) {
                    printf("Line %d, col %d: Incompatible type void in return statement\n", 
                           expr->line, expr->column);
                    semantic_errors++;
                }
            }
            break;
        }

        default:
            break;
    }
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
    
    if (body != NULL && body->children != NULL) {
        struct node_list *body_child = body->children->next;
        while (body_child != NULL) {
            struct node *stmt = body_child->node;
            if (stmt != NULL) {
                if (stmt->category == VarDecl) {
                    struct node *v_type_node = getchild(stmt, 0);
                    struct node *v_id_node = getchild(stmt, 1);
                    insert_symbol(local_table, v_id_node->token, category_to_type(v_type_node->category), 0, 0, NULL, stmt);
                } else {
                    check_expression(stmt, local_table, global_table);
                }
            }
            body_child = body_child->next;
        }
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
            }else {
                printf("\t");
            }
            
            printf("%s", type_to_string(curr_sym->type));
            
            if (curr_sym->is_param) {
                printf("\tparam");
            }
            printf("\n");
            
            curr_sym = curr_sym->next;
        }
        
        printf("\n");
        
        curr_table = curr_table->next;
    }
}