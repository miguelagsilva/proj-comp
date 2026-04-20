#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>     
#include <errno.h>    
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
        case T_STRING: return "String"; 
        case T_STRINGARRAY: return "String[]";
        case T_VOID: return "void";
        case T_UNDEF: return "undef";
        case T_NONE: return "none"; 
        default: return "none";
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
    
    if (strcmp(name, "_") == 0) {
        if (is_param) return NULL; 
        printf("Line %d, col %d: Symbol _ is reserved\n", node->line, node->column);
        semantic_errors++;
        return NULL;
    }

    if (strcmp(name, "return") != 0) {
        Symbol *curr = table->first_symbol;
        int defined = 0;
        
        while (curr != NULL) {
            if (strcmp(curr->name, name) == 0) {
                if (curr->is_method && is_method) {
                    ParamList *p1 = curr->param_types;
                    ParamList *p2 = params;
                    int same_params = 1;
                    
                    while (p1 != NULL && p2 != NULL) {
                        if (p1->type != p2->type) {
                            same_params = 0; 
                            break;
                        }
                        p1 = p1->next;
                        p2 = p2->next;
                    }
                    if (p1 == NULL && p2 == NULL && same_params) {
                        defined = 1;
                        break;
                    }
                } 
                else if (!curr->is_method && !is_method) {
                    defined = 1;
                    break;
                }
            }
            curr = curr->next;
        }

        if (defined) {
            if (is_param) return NULL; 

            if (is_method) {
                char sig[512] = "";
                strcat(sig, name);
                strcat(sig, "(");
                ParamList *p = params;
                while (p != NULL) {
                    strcat(sig, type_to_string(p->type));
                    if (p->next != NULL) strcat(sig, ",");
                    p = p->next;
                }
                strcat(sig, ")");
                printf("Line %d, col %d: Symbol %s already defined\n", node->line, node->column, sig);
            } else {
                printf("Line %d, col %d: Symbol %s already defined\n", node->line, node->column, name);
            }
            semantic_errors++;
            return NULL; 
        }
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
        
        insert_symbol(local_table, id_node->token, p_type, 0, 1, NULL, id_node);
        
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

    if (expr->category == Lshift || expr->category == Rshift || expr->category == Xor) {
        expr->type = T_NONE;
        return; 
    }

    struct node_list *child = expr->children->next;

    if (expr->category == Call && child != NULL) {
        child = child->next;
    }

    while (child != NULL) {
        check_expression(child->node, local_table, global_table);
        child = child->next;
    }

    switch (expr->category) {
        
        case StrLit: {
            expr->type = T_STRING;
            break;
        }

        case DecLit: {
            expr->type = T_INT;
            
            char *clean_str = malloc(strlen(expr->token) + 1);
            int j = 0;
            for(int i=0; expr->token[i] != '\0'; i++) {
                if (expr->token[i] != '_') {
                    clean_str[j++] = expr->token[i];
                }
            }
            clean_str[j] = '\0';
            
            errno = 0;
            unsigned long long val = strtoull(clean_str, NULL, 10);
            
            if (errno == ERANGE || val > 2147483647ULL) {
                if (val != 2147483649ULL) {
                    printf("Line %d, col %d: Number %s out of bounds\n", expr->line, expr->column, expr->token);
                    semantic_errors++;
                }
            }
            free(clean_str);
            break;
        }

        case RealLit: {
            expr->type = T_DOUBLE;
            
            char *clean_str = malloc(strlen(expr->token) + 1);
            int j = 0;
            int has_nonzero = 0;
            int in_exponent = 0;
            
            for(int i=0; expr->token[i] != '\0'; i++) {
                if (expr->token[i] == 'e' || expr->token[i] == 'E') {
                    in_exponent = 1;
                }
                if (expr->token[i] != '_') {
                    clean_str[j++] = expr->token[i];
                }
                if (!in_exponent && expr->token[i] >= '1' && expr->token[i] <= '9') {
                    has_nonzero = 1;
                }
            }
            clean_str[j] = '\0';
            
            errno = 0;
            double val = strtod(clean_str, NULL);
            
            if (isinf(val) || (val == 0.0 && has_nonzero)) {
                printf("Line %d, col %d: Number %s out of bounds\n", expr->line, expr->column, expr->token);
                semantic_errors++;
            }
            
            free(clean_str);
            break;
        }

        case BoolLit:  
            expr->type = T_BOOLEAN; 
            break;

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
                    if (left->type == right->type && left->type != T_STRINGARRAY) {
                        compatible = 1;
                    }
                    else if (left->type == T_DOUBLE && right->type == T_INT) {
                        compatible = 1;
                    }
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
                    printf("Line %d, col %d: Reference to method %s(%s) is ambiguous\n", id_node->line, id_node->column, id_node->token, args_str);
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

        case ParseArgs: {
            expr->type = T_INT;
            struct node *id_node = getchild(expr, 0);
            struct node *idx_node = getchild(expr, 1);
            if (id_node != NULL && idx_node != NULL) {
                if (id_node->type != T_STRINGARRAY || idx_node->type != T_INT) {
                    printf("Line %d, col %d: Operator Integer.parseInt cannot be applied to types %s, %s\n", 
                           expr->line, expr->column, type_to_string(id_node->type), type_to_string(idx_node->type));
                    semantic_errors++;
                }
            }
            break;
        }

        case Length: {
            expr->type = T_INT;
            struct node *id_node = getchild(expr, 0);
            if (id_node != NULL) {
                if (id_node->type != T_STRINGARRAY) {
                    printf("Line %d, col %d: Operator .length cannot be applied to type %s\n", 
                           expr->line, expr->column, type_to_string(id_node->type));
                    semantic_errors++;
                }
            }
            break;
        }

        case Plus:
        case Minus: {
            struct node *child_node = getchild(expr, 0);
            if (child_node != NULL) {
                if (child_node->type == T_INT || child_node->type == T_DOUBLE) {
                    expr->type = child_node->type;
                } else {
                    expr->type = T_UNDEF;
                    char *op = expr->category == Plus ? "+" : "-";
                    printf("Line %d, col %d: Operator %s cannot be applied to type %s\n",
                           expr->line, expr->column, op, type_to_string(child_node->type));
                    semantic_errors++;
                }
            }
            break;
        }

        case Not: {
            struct node *child_node = getchild(expr, 0);
            if (child_node != NULL) {
                expr->type = T_BOOLEAN;
                if (child_node->type != T_BOOLEAN) {
                    printf("Line %d, col %d: Operator ! cannot be applied to type %s\n",
                           expr->line, expr->column, type_to_string(child_node->type));
                    semantic_errors++;
                }
            }
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

        case And:
        case Or: {
            struct node *left = getchild(expr, 0);
            struct node *right = getchild(expr, 1);
            expr->type = T_BOOLEAN; 
            if (left && right) {
                if (left->type != T_BOOLEAN || right->type != T_BOOLEAN) {
                    char *op = expr->category == And ? "&&" : "||";
                    printf("Line %d, col %d: Operator %s cannot be applied to types %s, %s\n",
                           expr->line, expr->column, op, type_to_string(left->type), type_to_string(right->type));
                    semantic_errors++;
                }
            }
            break;
        }

        case Eq:
        case Ne: {
            struct node *left = getchild(expr, 0);
            struct node *right = getchild(expr, 1);
            expr->type = T_BOOLEAN; 
            if (left && right) {
                int valid = 0;
                if ((left->type == T_INT || left->type == T_DOUBLE) &&
                    (right->type == T_INT || right->type == T_DOUBLE)) valid = 1;
                else if (left->type == T_BOOLEAN && right->type == T_BOOLEAN) valid = 1;

                if (!valid) {
                    char *op = expr->category == Eq ? "==" : "!=";
                    printf("Line %d, col %d: Operator %s cannot be applied to types %s, %s\n",
                           expr->line, expr->column, op, type_to_string(left->type), type_to_string(right->type));
                    semantic_errors++;
                }
            }
            break;
        }

        case Lt: case Gt: case Le: case Ge: {
            struct node *left = getchild(expr, 0);
            struct node *right = getchild(expr, 1);
            expr->type = T_BOOLEAN; 
            if (left && right) {
                int valid = 0;
                if ((left->type == T_INT || left->type == T_DOUBLE) &&
                    (right->type == T_INT || right->type == T_DOUBLE)) valid = 1;

                if (!valid) {
                    char *op = "";
                    if (expr->category == Lt) op = "<";
                    else if (expr->category == Gt) op = ">";
                    else if (expr->category == Le) op = "<=";
                    else if (expr->category == Ge) op = ">=";
                    printf("Line %d, col %d: Operator %s cannot be applied to types %s, %s\n",
                           expr->line, expr->column, op, type_to_string(left->type), type_to_string(right->type));
                    semantic_errors++;
                }
            }
            break;
        }

        case Print: {
            struct node *child_expr = getchild(expr, 0);
            if (child_expr != NULL) {
                SemanticType t = child_expr->type;
                if (child_expr->category != StrLit && t != T_BOOLEAN && t != T_INT && t != T_DOUBLE) {
                    printf("Line %d, col %d: Incompatible type %s in System.out.print statement\n", 
                           child_expr->line, child_expr->column, type_to_string(t));
                    semantic_errors++;
                }
            }
            break;
        }

        case If:
        case While: {
            struct node *cond = getchild(expr, 0);
            if (cond != NULL) {
                SemanticType t = cond->type;
                if (t != T_BOOLEAN) {
                    printf("Line %d, col %d: Incompatible type %s in %s statement\n", 
                           cond->line, cond->column, type_to_string(t), expr->category == If ? "if" : "while");
                    semantic_errors++;
                }
            }
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
                    if (expected_type != T_VOID && expected_type == actual_type) compatible = 1;
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
    
    if (body != NULL && body->children != NULL) {
        struct node_list *body_child = body->children->next;
        while (body_child != NULL) {
            struct node *stmt = body_child->node;
            if (stmt != NULL) {
                if (stmt->category == VarDecl) {
                    struct node *v_type_node = getchild(stmt, 0);
                    struct node *v_id_node = getchild(stmt, 1);
                    insert_symbol(local_table, v_id_node->token, category_to_type(v_type_node->category), 0, 0, NULL, v_id_node);
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
            insert_symbol(global_table, id_node->token, category_to_type(type_node->category), 0, 0, NULL, id_node);
        } 
        else if (decl->category == MethodDecl) {
            struct node *header = getchild(decl, 0);
            struct node *type_node = getchild(header, 0);
            struct node *id_node = getchild(header, 1);
            struct node *params_node = getchild(header, 2);
            
            SemanticType ret_type = category_to_type(type_node->category);
            
            ParamList *p_list = NULL, *tail = NULL;
            struct node_list *p_child = params_node->children->next;
            
            char *param_names[200];
            int param_count = 0;

            while (p_child != NULL) {
                struct node *param_decl = p_child->node;
                struct node *p_type_node = getchild(param_decl, 0); 
                struct node *p_id_node = getchild(param_decl, 1);
                SemanticType p_type = category_to_type(p_type_node->category);

                if (strcmp(p_id_node->token, "_") == 0) {
                    printf("Line %d, col %d: Symbol _ is reserved\n", p_id_node->line, p_id_node->column);
                    semantic_errors++;
                } else {
                    int dup = 0;
                    for(int k = 0; k < param_count; k++) {
                        if (strcmp(param_names[k], p_id_node->token) == 0) {
                            dup = 1; break;
                        }
                    }
                    if (dup) {
                        printf("Line %d, col %d: Symbol %s already defined\n", p_id_node->line, p_id_node->column, p_id_node->token);
                        semantic_errors++;
                    } else {
                        param_names[param_count++] = p_id_node->token;
                    }
                }
                
                ParamList *new_param = (ParamList*)malloc(sizeof(ParamList));
                new_param->type = p_type;
                new_param->next = NULL;
                
                if (p_list == NULL) { p_list = new_param; tail = new_param; }
                else { tail->next = new_param; tail = new_param; }
                
                p_child = p_child->next;
            }
            
            Symbol *sym = insert_symbol(global_table, id_node->token, ret_type, 1, 0, p_list, id_node);
            if (sym == NULL) {
                decl->type = T_UNDEF;
            }
        }
        
        child = child->next;
    }

    child = program->children->next; 
    while (child != NULL) {
        struct node *decl = child->node;
        
        if (decl->category == MethodDecl) {
            if (decl->type != T_UNDEF) {
                check_method(decl, global_table);
            } else {
                decl->type = T_NONE;
            }
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