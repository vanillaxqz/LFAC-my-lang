%{
#include <iostream>
#include <vector>
#include "lang.h"
#include <cstring>
#include <cstdio>

using namespace std;

extern FILE* yyin;
extern char* yytext;
extern int yylineno;
extern int yylex();

vector<Parameter> globalParams;
class IdList ids;
string scope = "global";
string altscope;
vector<int> intVals;
vector<float> floatVals;
vector<char> charVals;
vector<bool> boolVals;
vector<Value> params;

void yyerror(const char * s);
%}
%union {
     char* string;
     int integer;
     int boolean;
     char character;
     float floatnum;
     class AST* ASTNode;
     class Parameter* param;
     class Variable* var;
}

%token VARS FUNCS CONSTRUCTS
%token CLASS CONST
%token NEQ GT GEQ LT LEQ AND OR NOT
%token IF ELSE WHILE FOR SWITCH CASE
%token ENTRY EXIT MAIN FNENTRY BREAK DEFAULT USRDEF GLOBALVAR GLOBALFUNC RETURN PRINT
%token<string> ID TYPE EVAL TYPEOF STRING
%token<integer> INT
%token<character> CHAR
%token<floatnum> FLOAT
%token<boolean> BOOL

%left OR 
%left AND
%left NOT
%left EQ NEQ
%left LEQ GEQ LT GT

%left '+' '-'
%left '*' '/' '%' 
%left '(' ')'
%start program

%type <ASTNode> arithm_expr bool_expr expression
%type <param> parameter
%type <var> fn_call

%%

program: ENTRY USRDEF user_defined_types GLOBALVAR global_variables GLOBALFUNC global_functions MAIN { scope = "main"; } '{' block '}' EXIT {printf("Program is correct!\n");}
       ;

user_defined_types: 
                  | user_defined_types user_defined_type
                  ;

user_defined_type: CLASS ID { if(ids.existsClass($2)) {printf("Error at line %d: the class \"%s\" is already defined.\n", yylineno, $2); return 1;} scope = $2; 
                        UserDefinedType type($2);
                        ids.addUsrDef(type);} 
                        '{' VARS field_variables FUNCS field_functions CONSTRUCTS field_constructors'}' ';' {
                        scope = "global";
}
                 ;

field_variables:  {}
               | field_variables variable_declaration {  }
               | field_variables array_declaration { }
	          ;

field_functions:  { }
               | field_functions function_declaration { }
	       ;

function_declaration: FNENTRY TYPE ID  {    altscope = scope;
                                            int result = ids.existsFunc($3, altscope);
                                            if( result == 1 ) {
                                                printf("Error at line %d: the function \"%s\" is already defined inside this scope: %s.\n", yylineno, $3, altscope.c_str());
                                                return 1;
                                            }
                                            else if ( result == 2 ) {
                                                printf("Error at line %d: return type specification for constructor invalid.\n", yylineno);
                                                return 1;
                                            }
                                            else if ( result == 3) {
                                                printf("Error at line %d: %s already exists as a class variable or array.\n", yylineno, $3);
                                                return 1;
                                            }
                                            Function func($3, $2, altscope); 
                                            ids.addFunc(func); 
                                            scope = $3; 
                                        } 
                        '(' parameter_list ')' '{' block '}' {
                                            Function &func = ids.getFunc(scope.c_str());
                                            func.params = globalParams;
                                            globalParams.clear();  
                                            scope = altscope;
                        } 
                        ;

field_constructors: { }
                  | field_constructors constructor_declaration { }
              ;

constructor_declaration: ID {               if (strcmp($1, scope.c_str())!= 0)
                                            {
                                                printf("Error at line %d: the constructor should have the same name as the class\n", yylineno);
                                                return 1;
                                            }
                                            altscope = scope;
                                            Function func($1, "none (CONSTRUCTOR)", altscope); 
                                            ids.addFunc(func); 
                                            scope = $1; 
                            }
                            '(' parameter_list ')' '{' constructor_block '}' { 
                                Function &func = ids.getFunc(scope.c_str());
                                func.params = globalParams;
                                globalParams.clear();
                                scope = altscope; } 
                        ;

constructor_block : block
                  | {}
                  ;

global_variables: 
                  | global_variables variable_declaration
                  | global_variables array_declaration
                  | global_variables class_var_declaration
                  ;

global_functions: 
                | global_functions function_declaration
                ;

parameter_list:  {}
               | parameter { } 
               | parameter_list ',' parameter  { } 
               ;


parameter: TYPE ID  { 
            for(const auto &param: globalParams)
            {
                if(param.name == $2)
                {
                    printf("Error at line %d: parameter \"%s\" declared more than once for this function.\n", yylineno, $2);
                    return 1;
                }
            }
    globalParams.push_back(Parameter($2, $1));} 
         | CONST TYPE ID { 
            for(const auto &param: globalParams)
            {
                if(param.name == $3)
                {
                    printf("Error at line %d: parameter \"%s\" declared more than once for this function.\n", yylineno, $3);
                return 1;
                }
            }
            Parameter param($3, $2);
            param.isConst = true; 
            globalParams.push_back(param);
         }
        ;

variable_declaration: TYPE ID ';' {
                        int result = ids.exists($2, scope);
                        if( result == 1 ){
                            printf("Error at line %d: \"%s\" already exists as a variable or array in this scope.\n", yylineno, $2);
                            return 1;
                        } 
                        else if (result == 2)
                        {
                            printf("Error at line %d: \"%s\" already exists as a function.\n", yylineno, $2);
                            return 1;
                        }
                        else if (result == 3)
                        {
                            printf("Error at line %d: \"%s\" already exists as a user defined type.\n", yylineno, $2);
                            return 1;
                        }
                        else {
                            Value val($1);
                            Variable var($2, val);
                            var.scope = scope;
                            ids.addVar(var);
                        }
                    }
                    | TYPE ID '=' CHAR ';' {
                        string type = "char";
                        int result = ids.exists($2, scope);
                        if( result == 1 ){
                            printf("Error at line %d: \"%s\" already exists as a variable or array in this scope.\n", yylineno, $2);
                            return 1;
                        } 
                        else if (result == 2)
                        {
                            printf("Error at line %d: \"%s\" already exists as a function.\n", yylineno, $2);
                            return 1;
                        }
                        else if (result == 3)
                        {
                            printf("Error at line %d: \"%s\" already exists as a user defined type.\n", yylineno, $2);
                            return 1;
                        }
                        else if ($1 == type){
                            Value val(type);
                            val.isCharSet = true;
                            val.charVal = $4;
                            Variable var($2, val);
                            var.scope = scope;
                            ids.addVar(var);
                        }  else {
                            printf("Error at line %d: Different types.1\n", yylineno);
                            return 1;
                        }                     
                    }
                    | TYPE ID '=' STRING ';' {
                        string type = "string";
                        int result = ids.exists($2, scope);
                        if( result == 1 ){
                            printf("Error at line %d: \"%s\" already exists as a variable or array in this scope.\n", yylineno, $2);
                            return 1;
                        } 
                        else if (result == 2)
                        {
                            printf("Error at line %d: \"%s\" already exists as a function.\n", yylineno, $2);
                            return 1;
                        }
                        else if (result == 3)
                        {
                            printf("Error at line %d: \"%s\" already exists as a user defined type.\n", yylineno, $2);
                            return 1;
                        } else if ($1 == type){
                            Value val(type);
                            val.isStringSet = true;
                            val.stringVal = $4;
                            Variable var($2, val);
                            var.scope = scope;
                            ids.addVar(var);
                        }  else {
                            printf("Error at line %d: Different types.2\n", yylineno);
                            return 1;
                        }                     
                    }
                    | TYPE ID '=' expression ';' {
                       int result = ids.exists($2, scope);
                        if( result == 1 ){
                            printf("Error at line %d: \"%s\" already exists as a variable or array in this scope.\n", yylineno, $2);
                            return 1;
                        } 
                        else if (result == 2)
                        {
                            printf("Error at line %d: \"%s\" already exists as a function.\n", yylineno, $2);
                            return 1;
                        }
                        else if (result == 3)
                        {
                            printf("Error at line %d: \"%s\" already exists as a user defined type.\n", yylineno, $2);
                            return 1;
                        }
                        if ($1 == $4->Eval().type) {
                            Value val($1);
                            if(val.type == "int") {
                                val.isIntSet = true;
                                val.intVal = $4->Eval().intVal;
                            } else if (val.type == "float") {
                                val.isFloatSet = true;
                                val.floatVal = $4->Eval().floatVal;
                            } else if (val.type == "bool") {
                                val.isBoolSet = true;
                                val.boolVal = $4->Eval().boolVal;
                            }        
                            Variable var($2, val);
                            var.scope = scope;
                            ids.addVar(var);
                        } else {
                            printf("Error at line %d: Different types.3\n", yylineno);
                            return 1;
                        }
                    } 
                    | CONST TYPE ID ';'  { 
                        int result = ids.exists($3, scope);
                        if( result == 1 ){
                            printf("Error at line %d: \"%s\" already exists as a variable or array in this scope.\n", yylineno, $3);
                            return 1;
                        } 
                        else if (result == 2)
                        {
                            printf("Error at line %d: \"%s\" already exists as a function.\n", yylineno, $3);
                            return 1;
                        }
                        else if (result == 3)
                        {
                            printf("Error at line %d: \"%s\" already exists as a user defined type.\n", yylineno, $3);
                            return 1;
                        }
                        else {
                            Value val($2);
                            val.isConst = true;
                            Variable var($3, val);
                            var.scope = scope;
                            ids.addVar(var);
                        }
                    }
                    | CONST TYPE ID '=' expression ';'  { 
                        int result = ids.exists($3, scope);
                        if( result == 1 ){
                            printf("Error at line %d: \"%s\" already exists as a variable or array in this scope.\n", yylineno, $3);
                            return 1;
                        } 
                        else if (result == 2)
                        {
                            printf("Error at line %d: \"%s\" already exists as a function.\n", yylineno, $3);
                            return 1;
                        }
                        else if (result == 3)
                        {
                            printf("Error at line %d: \"%s\" already exists as a user defined type.\n", yylineno, $3);
                            return 1;
                        }
                        if ($2 == $5->TypeOf()) {
                            Value val($2);
                            val.isConst = true;
                            if(val.type == "int") {
                                val.isIntSet = true;
                                val.intVal = $5->Eval().intVal;
                            } else if (val.type == "float") {
                                val.isFloatSet = true;
                                val.floatVal = $5->Eval().floatVal;
                            } else if (val.type == "bool") {
                                val.isBoolSet = true;
                                val.boolVal = $5->Eval().boolVal;
                            } 
                            Variable var($3, val);
                            var.scope = scope;
                            ids.addVar(var);
                        } else {
                            printf("Error at line %d: Different types.4\n", yylineno);
                            return 1;
                        }
                        
                    }
                    | CONST TYPE ID '=' CHAR ';'  { 
                        int result = ids.exists($3, scope);
                        if( result == 1 ){
                            printf("Error at line %d: \"%s\" already exists as a variable or array in this scope.\n", yylineno, $3);
                            return 1;
                        } 
                        else if (result == 2)
                        {
                            printf("Error at line %d: \"%s\" already exists as a function.\n", yylineno, $3);
                            return 1;
                        }
                        else if (result == 3)
                        {
                            printf("Error at line %d: \"%s\" already exists as a user defined type.\n", yylineno, $3);
                            return 1;
                        }
                       string type = "char";
                        if ( $2 == type) {
                            Value val($2);
                            val.isConst = true;
                            val.charVal = $5;
                            val.isCharSet = true;
                            Variable var($3, val);
                            var.scope = scope;
                            ids.addVar(var);
                        } else {
                            printf("Error at line %d: Different types.5\n",yylineno);
                            return 1;
                        }
                        
                    }
                    | CONST TYPE ID '=' STRING ';'  { 
                        int result = ids.exists($3, scope);
                        if( result == 1 ){
                            printf("Error at line %d: \"%s\" already exists as a variable or array in this scope.\n", yylineno, $3);
                            return 1;
                        } 
                        else if (result == 2)
                        {
                            printf("Error at line %d: \"%s\" already exists as a function.\n", yylineno, $3);
                            return 1;
                        }
                        else if (result == 3)
                        {
                            printf("Error at line %d: \"%s\" already exists as a user defined type.\n", yylineno, $3);
                            return 1;
                        }
                        string type = "string";
                        if ($2 == type) {
                            Value val($2);
                            val.isConst = true;
                            val.stringVal = $5;
                            val.isStringSet = true;
                            Variable var($3, val);
                            var.scope = scope;
                            ids.addVar(var);
                        } else {
                            printf("Error at line %d: Different types.6\n",yylineno);
                            return 1;
                        }
                        
                    }
                    ;


                                                        
class_var_declaration: CLASS ID ID ';' {
                            if(!ids.existsClass($2))
                            {
                                printf("Error at line %d: the class \"%s\" is not defined.\n", yylineno, $2);
                                return 1;
                            }
                            int result = ids.exists($3, scope);
                            if( result == 1 ){
                            printf("Error at line %d: \"%s\" already exists as a variable or array in this scope.\n", yylineno, $3);
                            return 1;
                            } 
                            else if (result == 2)
                            {
                                printf("Error at line %d: \"%s\" already exists as a function.\n", yylineno, $3);
                                return 1;
                            }
                            else if (result == 3)
                            {
                                printf("Error at line %d: \"%s\" already exists as a user defined type.\n", yylineno, $3);
                                return 1;
                            } else {
                                Value val($2);
                                Variable var($3, val);
                                var.scope = scope;
                                ids.addVar(var);
                            }
                            
                     }
                     | CLASS ID ID '=' ID ';' { 
                            if(!ids.existsClass($2))
                            {
                                printf("Error at line %d: the class \"%s\" is not defined.\n", yylineno, $2);
                                return 1;
                            }
                            int result = ids.exists($3, scope);
                            if( result == 1 ){
                            printf("Error at line %d: \"%s\" already exists as a variable or array in this scope.\n", yylineno, $3);
                            return 1;
                            } 
                            else if (result == 2)
                            {
                                printf("Error at line %d: \"%s\" already exists as a function.\n", yylineno, $3);
                                return 1;
                            }
                            else if (result == 3)
                            {
                                printf("Error at line %d: \"%s\" already exists as a user defined type.\n", yylineno, $3);
                                return 1;
                            } else {
                                
                                if ( !ids.exists($5) ){
                                printf("Error at line %d: No %s variable found.\n",yylineno, $5);
                                return 1;
                                }
                                
                                
                                if( ids.getVar($5).Eval().type != $2) {
                                    printf("Error at line %d: Different types between %s and %s.\n",yylineno, $3, $5);
                                    return 1;
                                }
                                Value val($2);
                                Variable var($3, val);
                                var.scope = scope;
                                ids.addVar(var);
                            }   
                     }
                     ;
                     
array_declaration: TYPE ID '[' INT ']' ';' {
                    int result = ids.exists($2, scope);
                        if( result == 1 ){
                            printf("Error at line %d: \"%s\" already exists as a variable or array in this scope.\n", yylineno, $2);
                            return 1;
                        } 
                        else if (result == 2)
                        {
                            printf("Error at line %d: \"%s\" already exists as a function.\n", yylineno, $2);
                            return 1;
                        }
                        else if (result == 3)
                        {
                            printf("Error at line %d: \"%s\" already exists as a user defined type.\n", yylineno, $2);
                            return 1;
                        } else {
                        Array arr($2, $4, $1);
                        arr.scope = scope;
                        ids.addArr(arr);
                    }
                 }
                 | TYPE ID '[' ']' '=' '[' int_values ']' ';' {
                   int result = ids.exists($2, scope);
                        if( result == 1 ){
                            printf("Error at line %d: \"%s\" already exists as a variable or array in this scope.\n", yylineno, $2);
                            return 1;
                        } 
                        else if (result == 2)
                        {
                            printf("Error at line %d: \"%s\" already exists as a function.\n", yylineno, $2);
                            return 1;
                        }
                        else if (result == 3)
                        {
                            printf("Error at line %d: \"%s\" already exists as a user defined type.\n", yylineno, $2);
                            return 1;
                        } else {
                        Array arr($2, static_cast<int>(intVals.size()), $1);
                        
                        for (const auto &element : intVals) {
                            char val[10];
                            sprintf(val, "%d", element);
                            arr.push(Value(val, "int"));
                        }

                        intVals.clear();
                        arr.scope = scope;
                        ids.addArr(arr);
                        
                    }
                 }
                 | TYPE ID '[' ']' '=' '[' float_values ']' ';' {
                    int result = ids.exists($2, scope);
                        if( result == 1 ){
                            printf("Error at line %d: \"%s\" already exists as a variable or array in this scope.\n", yylineno, $2);
                            return 1;
                        } 
                        else if (result == 2)
                        {
                            printf("Error at line %d: \"%s\" already exists as a function.\n", yylineno, $2);
                            return 1;
                        }
                        else if (result == 3)
                        {
                            printf("Error at line %d: \"%s\" already exists as a user defined type.\n", yylineno, $2);
                            return 1;
                        } else {
                        Array arr($2, static_cast<int>(floatVals.size()), $1);
                        
                        for (const auto &element : floatVals) {
                            char val[64];
                            sprintf(val, "%f", element);
                            arr.push(Value(val, "float"));
                        }
                        
                        arr.scope = scope;
                        ids.addArr(arr);
                        floatVals.clear();
                    }
                 }
                 | TYPE ID '[' ']' '=' '[' char_values ']' ';' {
                   int result = ids.exists($2, scope);
                        if( result == 1 ){
                            printf("Error at line %d: \"%s\" already exists as a variable or array in this scope.\n", yylineno, $2);
                            return 1;
                        } 
                        else if (result == 2)
                        {
                            printf("Error at line %d: \"%s\" already exists as a function.\n", yylineno, $2);
                            return 1;
                        }
                        else if (result == 3)
                        {
                            printf("Error at line %d: \"%s\" already exists as a user defined type.\n", yylineno, $2);
                            return 1;
                        } else {
                        Array arr($2, static_cast<int>(charVals.size()), $1);
                        
                        for (const auto &element : charVals) {
                            char val[10];
                            sprintf(val, "%c", element);
                            arr.push(Value(val, "char"));
                        }
                        
                        arr.scope = scope;
                        ids.addArr(arr);
                        charVals.clear();
                    }
                 }
                 | TYPE ID '[' ']' '=' '[' bool_values ']' ';' {
                    int result = ids.exists($2, scope);
                        if( result == 1 ){
                            printf("Error at line %d: \"%s\" already exists as a variable or array in this scope.\n", yylineno, $2);
                            return 1;
                        } 
                        else if (result == 2)
                        {
                            printf("Error at line %d: \"%s\" already exists as a function.\n", yylineno, $2);
                            return 1;
                        }
                        else if (result == 3)
                        {
                            printf("Error at line %d: \"%s\" already exists as a user defined type.\n", yylineno, $2);
                            return 1;
                        } else {
                        Array arr($2, static_cast<int>(boolVals.size()), $1);
                        
                        for (const auto &element : boolVals) { 
                            char val[6];
                            if (element){
                                strcpy(val, "true");
                            } else {
                                strcpy(val, "false");
                            }
                            arr.push(Value(val, "bool"));
                        }
                        arr.scope = scope;
                        ids.addArr(arr);
                        boolVals.clear();
                    }
                 }
                 ;
                 
int_values: int_values ',' INT {intVals.push_back($3);}
          | INT {intVals.push_back($1);}
          ;
          
float_values: float_values ',' FLOAT {floatVals.push_back($3);}
            | FLOAT {floatVals.push_back($1);}
            ;
            
bool_values: bool_values ',' BOOL {boolVals.push_back($3);}
           | BOOL {boolVals.push_back($1);}
           ;
           
char_values: char_values ',' CHAR {charVals.push_back($3);}
           | CHAR {charVals.push_back($1);}
           ;

block: statement
     | block statement
     ;

statement: variable_declaration
         | array_declaration
         | class_var_declaration
         | assignment_statement
         | control_statement 
         | fn_call ';'
         | RETURN expression ';' {
            if ( scope == "main" ) {
                if ( $2->Eval().type != "int" ){
                    printf("Error at line %d: Error at returning a non integer in main scope.\n", yylineno);
                    return 1;
                }

            } else {
                Function fn = ids.getFunc(scope.c_str());
                if( fn.returnType != $2->Eval().type ){
                    printf("Error at line %d: Different returning types in function: %s.\n", yylineno, fn.name.c_str());
                    return 1;
                } 
            }
         }
         | RETURN STRING ';' {
            if ( scope == "main") {
                printf("Error at line %d: Error at returning a non integer in main scope.\n",yylineno);
                return 1;
            } else {
                Function fn = ids.getFunc(scope.c_str());
                string type = "string";
                if( fn.returnType != type ){
                    printf("Error at line %d: Different returning types in function: %s.\n",yylineno, fn.name.c_str());
                    return 1;
                }
            }
         }
         | RETURN CHAR ';' {
            if ( scope == "main") {
                printf("Error at line %d: Error at returning a non integer in main scope.\n",yylineno);
                return 1;
            } else {
                Function fn = ids.getFunc(scope.c_str());
                string type = "char";
                if( fn.returnType != type ){
                    printf("Error at line %d: Different returning types in function: %s.\n",yylineno, fn.name.c_str());
                    return 1;
                }
            }
         }
         | TYPEOF '(' expression ')' ';' {
            printf("[Line : %d]Type of expression is %s.\n",yylineno, $3->Eval().type.c_str());
         }
         | EVAL '(' expression ')' ';' {
            string type = $3->TypeOf();
            if( type == "int" ) {
                printf("[Line : %d]Value of expression is %d.\n",yylineno, $3->Eval().intVal);
            } else if( type == "float" ) {
                printf("[Line : %d]Value of expression is %f.\n",yylineno, $3->Eval().floatVal);
            } else if( type == "char" ) {
                printf("[Line : %d]Value of expression is %c.\n",yylineno, $3->Eval().charVal);
            } else if( type == "bool" ) {
                if( $3->Eval().boolVal != 0 ){
                    printf("[Line : %d]Value of expression is true.\n",yylineno);
                } else {
                    printf("[Line : %d]Value of expression is false.\n",yylineno);
                } 
            }
         }
         ;

assignment_statement: ID '=' expression ';' {
                        if( ids.exists($1) ) {
                            Value result = $3->Eval();
                            Variable& var = ids.getVar($1);
                            if(var.val.isConst) {
                                printf("Error at line %d: Cannot assign value to a constant variable.\n", yylineno);
                                return 1;
                            }
                            if (var.scope == scope || var.scope == "global" || (ids.exists(scope.c_str()) && var.scope == ids.getFunc(scope.c_str()).scope) ) {
                                if (var.val.type == $3->TypeOf()){
                                if (var.val.type == "int") {
                                    var.val.isIntSet = true;
                                    var.val.intVal = result.intVal;
                                } else if (var.val.type == "float") {
                                    var.val.isFloatSet = true;
                                    var.val.floatVal = result.floatVal;
                                } else if (var.val.type == "bool") {
                                    var.val.isBoolSet = true;
                                    var.val.boolVal = result.boolVal;
                                }
                            } else {
                                printf("Error at line %d: Different types.\n", yylineno);
                                return 1;
                            } 
                            } else {
                                printf("Error at line %d: Variable not found in this scope.\n", yylineno);
                                return 1;
                            }                   
                        } else {
                            printf("Error at line %d: Variable not found.1\n", yylineno);
                            return 1;
                        }
                    }
                    | ID '=' CHAR ';' {
                        if( ids.exists($1) ) {

                            Variable& var = ids.getVar($1);
                            if(var.val.isConst) {
                                printf("Error at line %d: Cannot assign value to a constant variable.\n", yylineno);
                                return 1;
                            }
                            if (var.scope == scope || var.scope == "global" || (ids.exists(scope.c_str()) && var.scope == ids.getFunc(scope.c_str()).scope) ) {
                                if (var.val.type == "char"){
                                    var.val.isCharSet = true;
                                    var.val.charVal = $3;  
                                } else {
                                    printf("Error at line %d: Different types.7\n", yylineno);
                                    return 1;
                                }  
                            } else {
                                printf("Error at line %d: Variable not found in this scope.\n", yylineno);
                                return 1;
                            } 

                        } else {
                            printf("Error at line %d: Variable not found.2\n",yylineno);
                            return 1;
                        }
                    }
                    | ID '=' STRING ';' {
                        if( ids.exists($1) ) {
                            Variable& var = ids.getVar($1);
                            if(var.val.isConst) {
                                printf("Error at line %d: Cannot assign value to a constant variable.\n", yylineno);
                                return 1;
                            }
                            if (var.scope == scope || var.scope == "global" || (ids.exists(scope.c_str()) && var.scope == ids.getFunc(scope.c_str()).scope) ) {
                                if (var.val.type == "string"){
                                    var.val.isStringSet = true;
                                    var.val.stringVal = $3;  
                                } else {
                                    printf("Error at line %d: Different types.8\n", yylineno);
                                    return 1;
                                }  
                            } else {
                                printf("Error at line %d: Variable not found in this scope.\n", yylineno);
                                return 1;
                            }
                        } else {
                            printf("Error at line %d: Variable not found.3\n", yylineno);
                            return 1;
                        }
                    }
                    | ID '[' INT ']' '=' expression ';' {
                        Value result = $6->Eval();
                        if( ids.exists($1) ) {   
                            Array& arr = ids.getArray($1);
                            if (arr.scope == scope || arr.scope == "global" || (ids.exists(scope.c_str()) && arr.scope == ids.getFunc(scope.c_str()).scope) ) {
                                if (arr.type == result.type){
                                    arr.add($3, result);
                                } else {
                                    printf("Error at line %d: Different types.9\n",yylineno);
                                    return 1;
                                }   
                            } else {
                                printf("Error at line %d: Variable not found in this scope.\n", yylineno);
                                return 1;
                            }
                        } else {
                            printf("Error at line %d: Variable not found.4\n",yylineno);
                            return 1;
                        }
                    }
                    | ID '[' INT ']' '=' CHAR ';' {
                        if( ids.exists($1)) {
                            Array& arr = ids.getArray($1);
                            if (arr.scope == scope || arr.scope == "global" || (ids.exists(scope.c_str()) && arr.scope == ids.getFunc(scope.c_str()).scope) ) {
                                if (arr.type == "char"){
                                    Value val("char");
                                    val.charVal = $6;
                                    val.isCharSet = true;
                                    val.type = "char";
                                    arr.add($3, val);
                                } else {
                                    printf("Error at line %d: Different types.10\n", yylineno);
                                    return 1;
                                } 
                            } else {
                                printf("Error at line %d: Variable not found in this scope.\n", yylineno);
                                return 1;
                            }  

                        } else {
                            printf("Error at line %d: Variable not found.5\n", yylineno);
                            return 1;
                        }
                    }
                    | ID '[' ID ']' '=' expression ';' {
                        Value result = $6->Eval();
                        if( ids.exists($1) && ids.exists($3)) {
                            Array& arr = ids.getArray($1);
                            if (arr.scope == scope || arr.scope == "global" || (ids.exists(scope.c_str()) && arr.scope == ids.getFunc(scope.c_str()).scope) ) {
                                Value& val = ids.getVar($3).val;
                                if (arr.type == result.type && val.type == "int"){
                                    arr.add(val.intVal, result);
                                } else {
                                    printf("Error at line %d: Different types.11\n", yylineno);
                                    return 1;
                                }  
                            } else {
                                printf("Error at line %d: Variable not found in this scope.\n", yylineno);
                                return 1;
                            }  

                        } else {
                            printf("Error at line %d: Variable not found.6\n", yylineno);
                            return 1;
                        }
                    }
                    | ID '[' ID ']' '=' CHAR ';' {

                        if( ids.exists($1) && ids.exists($3)) {
                            Array& arr = ids.getArray($1);
                            if (arr.scope == scope  || arr.scope == "global" || (ids.exists(scope.c_str()) && arr.scope == ids.getFunc(scope.c_str()).scope) ) {
                                Value& val = ids.getVar($3).val;
                                if (arr.type == "char" && val.type == "int"){
                                    Value v("char");
                                    v.charVal = $6;
                                    v.isCharSet = true;
                                    v.type = "char";
                                    arr.add(val.intVal, v);
                                } else {
                                    printf("Error at line %d: Different types.12\n",yylineno);
                                    return 1;
                                }
                            } else {
                                printf("Error at line %d: Variable not found in this scope.\n", yylineno);
                                return 1;
                            }  

                        } else {
                            printf("Error at line %d: Variable not found.\n", yylineno);
                            return 1;
                        }
                    }
                    | ID '.' ID '=' expression';' {
                        if ( ids.exists($1) && ids.exists($3) && ids.getVar($3).scope == ids.getVar($1).val.type ){
                            Value result = $5->Eval();
                            Variable& var = ids.getVar($1);
                            if (var.scope == scope  || var.scope == "global" || (ids.exists(scope.c_str()) && var.scope == ids.getFunc(scope.c_str()).scope) ) {
                                Variable& var = ids.getVar($3);
                                if (var.val.type == $5->TypeOf()){
                                if (var.val.type == "int") {
                                    var.val.isIntSet = true;
                                    var.val.intVal = result.intVal;
                                } else if (var.val.type == "float") {
                                    var.val.isFloatSet = true;
                                    var.val.floatVal = result.floatVal;
                                } else if (var.val.type == "bool") {
                                    var.val.isBoolSet = true;
                                    var.val.boolVal = result.boolVal;
                                }
                            } else {
                                printf("Error at line %d: Different types.\n", yylineno);
                                return 1;
                            } 
                            } else {
                                printf("Error at line %d: Variable not found in this scope.\n", yylineno);
                                return 1;
                            } 
                        } else {
                            printf("Error at line %d: Variable not found.\n", yylineno);
                            return 1;
                        }

                    }
                    | ID '.' ID '=' CHAR';' {
                        if ( ids.exists($1) && ids.exists($3) && ids.getVar($3).scope == ids.getVar($1).val.type ){
                            Variable& var = ids.getVar($1);
                            if (var.scope == scope || var.scope == "global" || (ids.exists(scope.c_str()) && var.scope == ids.getFunc(scope.c_str()).scope) ) {
                                Variable& var = ids.getVar($3);
                                if (var.val.type == "char"){
                                    var.val.charVal = $5;
                                    var.val.isCharSet = true;
                                } else {
                                    printf("Error at line %d: Different types.\n", yylineno);
                                return 1;
                                }

                            } else {
                                printf("Error at line %d: Variable not found in this scope.\n", yylineno);
                                return 1;
                            } 
                        } else {
                            printf("Error at line %d: Variable not found.\n", yylineno);
                            return 1;
                        }
                    }
                    | ID '.' ID '=' STRING ';' {
                        if ( ids.exists($1) && ids.exists($3) && ids.getVar($3).scope == ids.getVar($1).val.type ){
                            Variable& var = ids.getVar($1);
                            if (var.scope == scope || var.scope == "global" || (ids.exists(scope.c_str()) && var.scope == ids.getFunc(scope.c_str()).scope) ) {
                                Variable& var = ids.getVar($3);
                                if (var.val.type == "string"){
                                    var.val.stringVal = $5;
                                    var.val.isStringSet = true;
                                } else {
                                    printf("Error at line %d: Different types.\n", yylineno);
                                return 1;
                                }
                                
                            } else {
                                printf("Error at line %d: Variable not found in this scope.\n", yylineno);
                                return 1;
                            } 
                        } else {
                            printf("Error at line %d: Variable not found.\n", yylineno);
                            return 1;
                        }
                    }
                    ;

control_statement: if_statement 
                 | SWITCH expression'{' case_block DEFAULT ':' block '}'
                 | SWITCH STRING'{' case_block DEFAULT ':' block '}'
                 | SWITCH CHAR'{' case_block DEFAULT ':' block '}'
                 | WHILE bool_expr '{' block '}'
                 | FOR '(' assignment_statement  bool_expr ';' arithm_expr ')' '{' block '}'
                 ;

                 
if_statement: IF bool_expr '{' block '}' ELSE '{' block '}' 
            | IF bool_expr '{' block '}' ELSE if_statement
            ;
            

case_block: CASE value ':' block BREAK ';'
          | case_block CASE value ':' block BREAK ';'
          ;

value: INT
     | FLOAT
     | BOOL
     | fn_call
     | STRING
     ;
            

expression: arithm_expr { $$ = $1; }
          | bool_expr { $$ = $1; }
          ;

 
        
arithm_expr: arithm_expr '+' arithm_expr {
               if($1->Eval().type == "bool" || $3->Eval().type == "bool"){
                    printf("Error at line %d: Invalid operation between bools.\n", yylineno);
                    return 1;
               }
               if($1->Eval().type == "string" || $3->Eval().type == "string"){
                    printf("Error at line %d: Invalid operation between strings.\n", yylineno);
                    return 1;
               }
               if ($1->Eval().type == $3->Eval().type)
                $$ = new AST($1, "+", $3);                
                   
               else{
                    printf("Error at line %d: Different types between: %s and %s.\n", yylineno,$1->Eval().type.c_str(), $3->Eval().type.c_str());            
                    return 1;
               }

           }
           | arithm_expr '-' arithm_expr {
                if($1->Eval().type == "bool" || $3->Eval().type == "bool"){
                    printf("Error at line %d: Invalid operation between bools.\n", yylineno);
                    return 1;
               }
               if($1->Eval().type == "string" || $3->Eval().type == "string"){
                    printf("Error at line %d: Invalid operation between strings.\n", yylineno);
                    return 1;
               }
               if ($1->Eval().type == $3->Eval().type)
                   $$ = new AST($1, "-", $3); 
               else {
                    printf("Error at line %d: Different types between: %s and %s.\n", yylineno,$1->Eval().type.c_str(), $3->Eval().type.c_str());
                    return 1;
               }
           }
           | arithm_expr '/' arithm_expr {
            if($1->Eval().type == "bool" || $3->Eval().type == "bool"){
                    printf("Error at line %d: Invalid operation between bools.\n", yylineno);
                    return 1;
               }
               if($1->Eval().type == "string" || $3->Eval().type == "string"){
                    printf("Error at line %d: Invalid operation between strings.\n", yylineno);
                    return 1;
               }
               if ($1->Eval().type == $3->Eval().type)
                   $$ = new AST($1, "/", $3); 
               else {
                    printf("Error at line %d: Different types between: %s and %s.\n", yylineno,$1->Eval().type.c_str(), $3->Eval().type.c_str());            
                    return 1;
               }
           }
           | arithm_expr '*' arithm_expr {
            if($1->Eval().type == "bool" || $3->Eval().type == "bool"){
                    printf("Error at line %d: Invalid operation between bools.\n", yylineno);
                    return 1;
               }
               if($1->Eval().type == "string" || $3->Eval().type == "string"){
                    printf("Error at line %d: Invalid operation between strings.\n", yylineno);
                    return 1;
               }
               if ($1->Eval().type == $3->Eval().type)
                   $$ = new AST($1, "*", $3); 
               else {
                    printf("Error at line %d: Different types between: %s and %s.\n", yylineno,$1->Eval().type.c_str(), $3->Eval().type.c_str());            
                    return 1;
               }
           }
           | arithm_expr '%' arithm_expr {
            if($1->Eval().type == "bool" || $3->Eval().type == "bool"){
                    printf("Error at line %d: Invalid operation between bools.\n", yylineno);
                    return 1;
               }
               if($1->Eval().type == "string" || $3->Eval().type == "string"){
                    printf("Error at line %d: Invalid operation between strings.\n", yylineno);
                    return 1;
               }
               if ($1->Eval().type == $3->Eval().type)
                   $$ = new AST($1, "%", $3); 
               else {
                    printf("Error at line %d: Different types between: %s and %s.\n", yylineno, $1->Eval().type.c_str(), $3->Eval().type.c_str());            
                    return 1;
               }
                    
           }
           | '-' arithm_expr {
                $$ = new AST($2, "-", NULL);
           }
           | '(' arithm_expr ')' {
                $$ = $2;
           }
           | INT {
               char* identifierText = strdup(yytext);
               $$ = new AST(new Value(identifierText, "int")); 
           }
           | FLOAT {
               char* identifierText = strdup(yytext);
               $$ = new AST(new Value(identifierText, "float")); 
           }
           | fn_call {

                $$ = new AST($1->val);
               
            }
           | ID {
                if( ids.exists($1) ) {
                    Variable var = ids.getVar($1);
                    if (var.scope == scope || var.scope == "global" || (ids.exists(scope.c_str()) && var.scope == ids.getFunc(scope.c_str()).scope)){
                        Value val = var.Eval();
                        $$ = new AST(val);
                    }else {
                        printf("Error at line %d: Variable not found in this scope.\n", yylineno);
                        return 1;
                    }
                    
                } else {
                    printf("Error at line %d: Variable not found.\n", yylineno);
                    return 1;
                }
           }
           | ID '.' ID { 
                if( ids.exists($1) ) {
                    Variable obj = ids.getVar($1);
                    if (obj.scope == scope || obj.scope == "global" || (ids.exists(scope.c_str()) && obj.scope == ids.getFunc(scope.c_str()).scope)){
                        if( ids.exists($3) ) {
                            Variable var = ids.getVar($3);
                            if( var.scope == obj.val.type ){
                                $$ = new AST(var.val);
                            } else {
                                printf("Error at line %d: No %s member in class %s.\n",yylineno, $3, $1);
                                return 0;
                            }
                                
                        } else {
                            printf("Error at line %d: No %s member in class %s.\n",yylineno, $3, $1);
                            return 0;
                        }

                    } else {
                        printf("Error at line %d: Variable not found in this scope.\n", yylineno);
                        return 1;
                    }
                } else {
                    printf("Error at line %d: Class %s not found.\n",yylineno, $1);
                    return 1;
                }
           } 
           | ID '.' fn_call {
                if( ids.exists($1) ) {
                    Variable obj = ids.getVar($1);
                    if (obj.scope == scope || obj.scope == "global" || (ids.exists(scope.c_str()) && obj.scope == ids.getFunc(scope.c_str()).scope)){

                        Function fn = ids.getFunc($3->name.c_str());

                        if( obj.val.type == fn.scope ){
                            $$ = new AST($3->val);
                        } else {
                            printf("Error at line %d: No %s method found in class variable %s.", yylineno, $3->name.c_str(), $1);
                            return 0;
                        }
                        
                    } else {
                        printf("Error at line %d: Variable not found in this scope.\n", yylineno);
                        return 1;
                    }
                    
                } else {

                    printf("Error at line %d: Variable %s not found.\n",yylineno, $1);
                    return 1;

                }
           }
           | ID '[' ID ']' {
                if( ids.exists($1) && ids.exists($3)) {
                    Array arr = ids.getArray($1);
                    if (arr.scope == scope || arr.scope == "global" || (ids.exists(scope.c_str()) && arr.scope == ids.getFunc(scope.c_str()).scope)){
                        Value val = ids.getVar($3).Eval();
                        if( val.type == "int" )
                            $$ = new AST(arr.getVal(val.intVal));
                        else {
                            printf("Error at line %d: Invalid index type.\n", yylineno);
                        }
                    } else {
                        printf("Error at line %d: Variable not found in this scope.\n", yylineno);
                        return 1;
                    }
                } else {
                    printf("Error at line %d: Variable not found.\n", yylineno);
                    return 1;
                }
           }
           | ID '[' INT ']' {
                if( ids.exists($1) ) {
                    Array arr = ids.getArray($1);
                    if (arr.scope == scope || arr.scope == "global" || (ids.exists(scope.c_str()) && arr.scope == ids.getFunc(scope.c_str()).scope)){
                        $$ = new AST(arr.getVal($3));
                    } else {
                        printf("Error at line %d: Variable not found in this scope.\n", yylineno);
                        return 1;
                    }
                    
                }else {
                    printf("Error at line %d: Variable not found.\n", yylineno);
                }

           }
           | ID '[' fn_call ']' {
                if( ids.exists($1)) {
                    Array arr = ids.getArray($1);
                    if (arr.scope == scope || arr.scope == "global" || (ids.exists(scope.c_str()) && arr.scope == ids.getFunc(scope.c_str()).scope)){
                        if( $3->val.type == "int" )
                            $$ = new AST(arr.getVal($3->val.intVal));
                        else {
                            printf("Error at line %d: Invalid index type.\n", yylineno);
                        }
                    }
                } else {
                    printf("Error at line %d: Variable not found.\n", yylineno);
                    return 1;
                }
           }
           ;   
               
      
bool_expr: bool_expr AND bool_expr {
               $$ = new AST($1, "and", $3); 
         }
         | bool_expr OR bool_expr {
               $$ = new AST($1, "or", $3); 
           }
         | NOT bool_expr {
               $$ = new AST($2, "not", NULL); 
         }
         | '(' bool_expr ')' {
            $$ = $2;
         }
         | BOOL { 
            char* identifierText = strdup(yytext);
            $$ = new AST(new Value(identifierText, "bool"));
          }
         | arithm_expr GT arithm_expr {
               if ($1->Eval().type == $3->Eval().type)
                   $$ = new AST($1, "gt", $3); 
               else {
                    printf("Error at line %d: Different types between: %s and %s\n", yylineno, $1->Eval().type.c_str(), $3->Eval().type.c_str());            
                    return 1;
               }
           }
         | arithm_expr LT arithm_expr {
               if ($1->Eval().type == $3->Eval().type)
                   $$ = new AST($1, "lt", $3); 
               else{
                    printf("Error at line %d: Different types between: %s and %s\n", yylineno, $1->Eval().type.c_str(), $3->Eval().type.c_str());            
                    return 1;
               }
           }
         | arithm_expr GEQ arithm_expr {
               if ($1->Eval().type == $3->Eval().type)
                   $$ = new AST($1, "geq", $3); 
               else {
                    printf("Error at line %d: Different types between: %s and %s\n", yylineno, $1->Eval().type.c_str(), $3->Eval().type.c_str());            
                    return 1;
               }
           }
         | arithm_expr LEQ arithm_expr {
               if ($1->Eval().type == $3->Eval().type)
                   $$ = new AST($1, "leq", $3); 
               else {
                    printf("Error at line %d: Different types.\n", yylineno);
                    return 1;
               }
                    
           }
         | arithm_expr EQ arithm_expr {
               if ($1->Eval().type == $3->Eval().type)
                   $$ = new AST($1, "eq", $3); 
               else {
                    printf("Error at line %d: Different types.\n", yylineno);
                    return 1;
               }
           }
         | arithm_expr NEQ arithm_expr {
               if ($1->Eval().type == $3->Eval().type)
                   $$ = new AST($1, "neq", $3); 
               else {
                    printf("Error at line %d: Different types.\n", yylineno);
                    return 1;
               }
           }
         ;


fn_call: ID '(' argument_list ')' { 
            
            if( ids.exists($1) ) {
                Function fn = ids.getFunc($1);
                if (fn.scope == scope || fn.scope == "global" || ids.existsVar(fn.scope.c_str(), scope) ){
                        if ( params.size() != fn.params.size() ){
                        printf("Error at line %d: The %s function call has inapropriate number of parameters.\n", yylineno, fn.name.c_str());
                        return 1;
                    } else {
                        for( int i = 0; i < params.size(); i++ ) {
                            if (params.at(i).type != fn.params.at(i).type){
                                printf("Error at line %d: Illegal call params.\n", yylineno);
                                return 1;
                            }
                        }
                        params.clear();

                        Value result(fn.returnType);
                        if( result.type == "int" ){
                            result.intVal = 0;
                            result.isIntSet = true;
                        } else if( result.type == "float" ){
                            result.floatVal = 0.0;
                            result.isFloatSet = true;
                        } else if( result.type == "bool" ){
                            result.boolVal = true;
                            result.isIntSet = true;
                        } else if( result.type == "char" ){
                            result.charVal = '\0';
                            result.isCharSet = true;
                        } else if( result.type == "string" ){
                            result.stringVal = "";
                            result.isStringSet = true;
                        }

                        $$ = new Variable(fn.name.c_str(), result);

                    }
                } else {
                    printf("Error at line %d: Function not found in this scope.\n", yylineno);
                    return 1;
                }

                
            }
        }
        ;


argument_list: 
             | expression { params.push_back($1->Eval());}
             | argument_list ',' expression { params.push_back($3->Eval());}
             ;

%%
void yyerror(const char * s) {
    std::cerr << "error: " << s << " at line:" << yylineno << std::endl;
}

int main(int argc, char** argv) {
    yyin = fopen(argv[1], "r");
    yyparse();

    /* ids.printVars();
    ids.printFuncs();
    ids.printUsrDefs();
    ids.printArrays(); */
    ids.exportToFile("symbol_table.txt");
    return 0;
}