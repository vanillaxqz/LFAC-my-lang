#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <cstring>

using namespace std;

class Value
{
public:
    string type;
    int intVal;
    float floatVal;
    bool boolVal;
    char charVal;
    string stringVal;
    bool isIntSet, isFloatSet, isBoolSet, isCharSet, isStringSet, isConst = false;

    Value() : isIntSet(false), isFloatSet(false), isBoolSet(false), isCharSet(false), isStringSet(false) {}

    Value(string type) : type(type), isIntSet(false), isFloatSet(false), isBoolSet(false), isCharSet(false), isStringSet(false) {}

    Value(char *value, string type)
    {

        if (type == "int")
        {
            this->intVal = atoi(value);
            isIntSet = true;
        }
        else if (type == "float")
        {
            this->floatVal = atof(value);
            isFloatSet = true;
        }
        else if (type == "bool")
        {
            boolVal = (string(value) == "true");
            isBoolSet = true;
        }
        else if (type == "char")
        {
            this->charVal = value[0];
            isCharSet = true;
        }
        else if (type == "string")
        {
            this->stringVal = value;
            isStringSet = true;
        }

        this->type = type;
    }
};

class Variable
{
public:
    std::string name;
    Value val;
    string scope;

    Variable(const std::string &name, const Value &val)
        : name(name), val(val) {}

    Value Eval()
    {
        return this->val;
    }

    string TypeOf()
    {
        if (val.isBoolSet)
        {
            val.type = "bool";
            return "bool";
        }
        else if (val.isIntSet)
        {
            val.type = "int";
            return "int";
        }
        else if (val.isFloatSet)
        {
            val.type = "float";
            return "float";
        }
        else if (val.isCharSet)
        {
            val.type = "char";
            return "char";
        }
        else if (val.isStringSet)
        {
            val.type = "string";
            return "string";
        }
    }
};

class Parameter
{
public:
    string name;
    string type;
    bool isConst = false;
    Parameter(const string &name, const string &type)
        : name(name), type(type) {}
};

class Function
{
public:
    string name;
    string returnType;
    string scope;
    vector<Parameter> params;
    Function(const string &name, const string &returnType, const string &scope)
        : name(name), returnType(returnType), scope(scope) {}
};

class UserDefinedType
{
public:
    string name;
    UserDefinedType(const string &name)
        : name(name) {}
};

class Array
{
public:
    string name;
    string type;
    string scope;
    int capacity = 0;
    int index = 0;

    vector<Value> vals;
    Array(const string &name, int capacity, string type) : name(name), capacity(capacity), type(type) {}

    void push(Value val)
    {
        index++;
        if (index <= capacity)
        {
            vals.push_back(val);
        }
        else
        {
            printf("Segmentation fault.");
            return;
        }
    }

    void add(int ind, Value val)
    {
        if (ind < 0 || ind > capacity)
        {
            printf("Index out of bounds.\n");
            return;
        }
        else if (ind > index)
        {
            for (int i = 0; i < ind; i++)
            {
                vals.resize(ind + 1, Value());
            }
            vals.at(ind) = val;
            index = ind;
        }
        else if (index == ind)
        {
            vals.push_back(val);
            index++;
        }
        else
        {
            vals.at(ind) = val;
        }
    }

    Value getVal(int ind)
    {

        if (ind < 0 || ind > capacity || ind > index)
        {
            printf("Index out of bounds.\n");
            return Value();
        }
        else
        {
            return vals.at(ind);
        }
    }
};

class IdList
{
    vector<Variable> vars;
    vector<Function> funcs;
    vector<UserDefinedType> usrdefs;
    vector<Array> arrays;

public:
    bool existsClass(const char *name) // return true to check if the class exists
    {
        for (const auto &usrdef : usrdefs)
            if (usrdef.name == name)
                return true;

        return false;
    }

    bool existsVar(const char *type, string scope)
    {
        for (const auto &var : vars)
            if (var.val.type == type && var.scope == scope)
                return true;
        return false;
    }

    int existsArr(const char *name)
    {
        for (const auto &array : arrays)
            if (array.name == name)
                return 1;
        return 0;
    }

    int existsFunc(const char *name, string scope) // return 1 to check if array exists in scope
    {
        for (const auto &array : arrays)
            if (array.name == name && array.scope == scope)
                return 3; // same name array in the same scope
        for (const auto &var : vars)
            if (var.name == name && var.scope == scope)
                return 3; // same name variable in the same scope
        for (const auto &usrdef : usrdefs)
            if (usrdef.name == name && usrdef.name == scope)
                return 2; // return type specification for constructor invalid
        for (const auto &func : funcs)
            if (func.name == name && func.scope == scope)
                return 1; // same name functions in the same scope

        return 0;
    }

    bool exists(const char *name)
    {
        for (const auto &var : vars)
            if (var.name == name)
                return true;

        for (const auto &func : funcs)
            if (func.name == name)
                return true;

        for (const auto &usrdef : usrdefs)
            if (usrdef.name == name)
                return true;

        for (const auto &array : arrays)
            if (array.name == name)
                return true;

        return false;
    }

    int exists(const char *name, string scope) // return 1 to check if the var or array exists in a scope.
    {
        for (const auto &var : vars)
            if (var.name == name && var.scope == scope)
                return 1; // same name variable in the same scope

        for (const auto &array : arrays)
            if (array.name == name && array.scope == scope)
                return 1; // same name array in the same scope

        for (const auto &func : funcs)
            if (func.name == name && func.scope == scope)
                return 2; // same name functions in the same scope

        for (const auto &usrdef : usrdefs)
            if (usrdef.name == name)
                return 3; // same name as user defined type

        return 0;
    }

    Variable &getVar(const char *name)
    {

        for (auto &var : vars)
        {
            if (var.name == name)
            {
                return var;
            }
        }

        throw std::runtime_error("Variable not found: " + std::string(name));
    }

    Function &getFunc(const char *name)
    {
        for (auto &func : funcs)
            if (func.name == name)
                return func;

        throw std::runtime_error("Function not found: " + std::string(name));
    }

    UserDefinedType &getUDT(const char *name)
    {
        for (auto &udt : usrdefs)
            if (udt.name == name)
                return udt;

        throw std::runtime_error("Class not found: " + std::string(name));
    }

    Array &getArray(const char *name)
    {
        for (auto &array : arrays)
            if (array.name == name)
                return array;
        throw std::runtime_error("Array not found: " + std::string(name));
    }

    void addVar(const Variable &var)
    {
        vars.push_back(var);
    }

    void addFunc(const Function &func)
    {
        funcs.push_back(func);
    }

    void addUsrDef(const UserDefinedType &usrdef)
    {
        usrdefs.push_back(usrdef);
    }

    void addArr(const Array &array)
    {
        arrays.push_back(array);
    }

    void printVars()
    {
        if (vars.empty())
        {
            std::cout << "No variables to display." << std::endl;
            return;
        }

        std::cout << "Variables List:" << std::endl;
        for (const auto &var : vars)
        {
            std::cout << "Name: " << var.name << ", Type: " << var.val.type << ", Scope: " << var.scope;

            if (var.val.isIntSet)
                std::cout << ", Int Value: " << var.val.intVal;
            if (var.val.isFloatSet)
                std::cout << ", Float Value: " << var.val.floatVal;
            if (var.val.isBoolSet)
                std::cout << ", Bool Value: " << (var.val.boolVal ? "true" : "false");
            if (var.val.isCharSet)
                std::cout << ", Char Value: " << var.val.charVal;
            if (var.val.isStringSet)
                std::cout << ", String Value: " << var.val.stringVal;

            std::cout << ", is constant?:";
            if (var.val.isConst)
                std::cout << " Const";
            else
                std::cout << " Not Const";

            std::cout << std::endl;
        }
    }

    void printFuncs()
    {
        if (funcs.empty())
        {
            std::cout << "No functions to display." << std::endl;
            return;
        }

        std::cout << "Functions List:" << std::endl;
        for (const auto &func : funcs)
        {
            std::cout << "Name: " << func.name << ", Return Type: " << func.returnType << ", Scope: " << func.scope << std::endl;
            if (!func.params.empty())
            {
                std::cout << "\tParameters: " << std::endl;
                for (const auto &param : func.params)
                {
                    std::cout << "\t\tName: " << param.name << ", Type: " << param.type;
                }
                std::cout << ", is constant?: ";
                if (func.params.back().isConst)
                    std::cout << "Const";
                else
                    std::cout << "Not Const";

                cout << std::endl;
            }
        }
    }

    void printUsrDefs()
    {
        if (usrdefs.empty())
        {
            std::cout << "No user defined types to display." << std::endl;
            return;
        }

        std::cout << "User Defined Types List:" << std::endl;
        for (const auto &usrdef : usrdefs)
        {
            std::cout << "Name: " << usrdef.name << std::endl;
        }
    }

    void printArrays()
    {
        if (arrays.empty())
        {
            std::cout << "No arrays to display." << std::endl;
            return;
        }

        std::cout << "Arrays List:" << std::endl;
        for (const auto &array : arrays)
        {
            std::cout << "Name: " << array.name << ", Type: " << array.type << ", Capacity: " << array.capacity << ", Scope: " << array.scope << std::endl;
            std::cout << "\tElements: ";
            for (auto &element : array.vals)
            {
                if (element.type == "char")
                {
                    cout << element.charVal << " ";
                }
                else if (element.type == "float")
                {
                    cout << element.floatVal << " ";
                }
                else if (element.type == "bool")
                {
                    cout << element.boolVal << " ";
                }
                else if (element.type == "int")
                {
                    cout << element.intVal << " ";
                }
            }
            std::cout << std::endl;
        }
    }

    void exportToFile(std::string fileName)
    {
        std::ofstream file(fileName);
        if (file.is_open())
        {
            file << "SYMBOL TABLE\n\n";
            file << "Variables List:\n";
            for (const auto &var : vars)
            {
                file << "Name: " << var.name << ", Type: " << var.val.type << ", Scope: " << var.scope;
                if (var.val.isIntSet)
                    file << ", Value: " << var.val.intVal;
                if (var.val.isFloatSet)
                    file << ", Value: " << var.val.floatVal;
                if (var.val.isBoolSet)
                    file << ", Value: " << (var.val.boolVal ? "true" : "false");
                if (var.val.isCharSet)
                    file << ", Value: " << var.val.charVal;
                if (var.val.isStringSet)
                    file << ", String Value: " << var.val.stringVal;
                file << ", Is Const?: " << (var.val.isConst ? "CONST" : "NOT CONST") << "\n";
            }

            file << "\nArrays List:\n";
            for (const auto &array : arrays)
            {
                file << "Name: " << array.name << ", Type: " << array.type << ", Capacity: " << array.capacity << ", Scope: " << array.scope;
                if (!array.vals.empty())
                {
                    file << "\n\tElements: ";
                    for (const auto &element : array.vals)
                    {
                        if (element.type == "char")
                        {
                            file << element.charVal << " ";
                        }
                        else if (element.type == "float")
                        {
                            file << element.floatVal << " ";
                        }
                        else if (element.type == "bool")
                        {
                            file << element.boolVal << " ";
                        }
                        else if (element.type == "int")
                        {
                            file << element.intVal << " ";
                        }
                    }
                    file << "\n";
                }
                else
                    file << ", Elements: None\n";
            }

            file << "\nFunctions List:\n";
            for (const auto &func : funcs)
            {
                file << "Name: " << func.name << ", Return Type: " << func.returnType << ", Scope: " << func.scope << "\n\tParameters:\n";
                for (const auto &param : func.params)
                {
                    file << "\t\tName: " << param.name << ", Type: " << param.type << ", Is Const?: " << (param.isConst ? "CONST" : "NOT CONST") << "\n";
                }
            }

            file << "\nUser Defined Types List:\n";
            for (const auto &typeName : usrdefs)
            {
                file << "Name: " << typeName.name << "\n";
            }
            file.close();
        }
        else
        {
            std::cerr << "Unable to open file for writing.\n";
        }
    }

    ~IdList() {}
};

class AST
{

public:
    string type = "";
    Value val;
    string root;
    AST *left;
    AST *right;

    AST(AST *left, string root, AST *right) : root(root), left(left), right(right) {}

    AST(Value *val) : val(*val)
    {
        if (val->type == "int")
        {
            type = "int";
        }
        else if (val->type == "float")
        {
            type = "float";
        }
        else if (val->type == "bool")
        {
            type = "bool";
        }
        else if (val->type == "char")
        {
            type = "char";
        }
        else if (val->type == "string")
        {
            type = "string";
        }
    }

    AST(Value val) : val(val)
    {
        if (val.type == "int")
        {
            type = "int";
        }
        else if (val.type == "float")
        {
            type = "float";
        }
        else if (val.type == "bool")
        {
            type = "bool";
        }
        else if (val.type == "char")
        {
            type = "char";
        }
        else if (val.type == "string")
        {
            type = "string";
        }
    }

    Value Eval()
    {

        if (root.empty())
        {
            return val;
        }
        else if (left && right && left->TypeOf() == right->TypeOf())
        {

            Value leftResult = left->Eval();
            Value rightResult = right->Eval();
            Value result;

            if (left->type == "int")
            {

                result.type = "int";
                result.isIntSet = true;

                if (root == "+")
                {
                    result.intVal = leftResult.intVal + rightResult.intVal;
                    return result;
                }
                else if (root == "-")
                {
                    result.intVal = leftResult.intVal - rightResult.intVal;
                    return result;
                }
                else if (root == "*")
                {
                    result.intVal = leftResult.intVal * rightResult.intVal;
                    return result;
                }
                else if (root == "/")
                {
                    result.intVal = leftResult.intVal / rightResult.intVal;
                    return result;
                }
                else if (root == "%")
                {
                    result.intVal = leftResult.intVal % rightResult.intVal;
                    return result;
                }

                result.type = "bool";
                result.isIntSet = false;
                result.isBoolSet = true;

                if (root == "gt")
                {
                    result.boolVal = leftResult.intVal > rightResult.intVal;
                }
                else if (root == "lt")
                {
                    result.boolVal = leftResult.intVal < rightResult.intVal;
                }
                else if (root == "geq")
                {
                    result.boolVal = leftResult.intVal >= rightResult.intVal;
                }
                else if (root == "leq")
                {
                    result.boolVal = leftResult.intVal <= rightResult.intVal;
                }
                else if (root == "eq")
                {
                    result.boolVal = leftResult.intVal == rightResult.intVal;
                }
                else if (root == "neq")
                {
                    result.boolVal = leftResult.intVal != rightResult.intVal;
                }

                return result;
            }
            else if (left->type == "float")
            {

                result.type = "float";
                result.isFloatSet = true;

                if (root == "+")
                {
                    result.floatVal = leftResult.floatVal + rightResult.floatVal;
                    return result;
                }
                else if (root == "-")
                {
                    result.floatVal = leftResult.floatVal - rightResult.floatVal;
                    return result;
                }
                else if (root == "*")
                {
                    result.floatVal = leftResult.floatVal * rightResult.floatVal;
                    return result;
                }
                else if (root == "/")
                {
                    result.floatVal = leftResult.floatVal / rightResult.floatVal;
                    return result;
                }

                result.type = "bool";
                result.isFloatSet = false;
                result.isBoolSet = true;

                if (root == "gt")
                {
                    result.boolVal = leftResult.floatVal > rightResult.floatVal;
                }
                else if (root == "lt")
                {
                    result.boolVal = leftResult.floatVal < rightResult.floatVal;
                }
                else if (root == "geq")
                {
                    result.boolVal = leftResult.floatVal >= rightResult.floatVal;
                }
                else if (root == "leq")
                {
                    result.boolVal = leftResult.floatVal <= rightResult.floatVal;
                }
                else if (root == "eq")
                {
                    result.boolVal = leftResult.floatVal == rightResult.floatVal;
                }
                else if (root == "neq")
                {
                    result.boolVal = leftResult.floatVal != rightResult.floatVal;
                }

                return result;
            }
            else if (left->type == "bool")
            {

                result.type = "bool";
                result.isBoolSet = true;

                if (root == "or")
                {
                    result.boolVal = leftResult.boolVal || rightResult.boolVal;
                }
                else if (root == "and")
                {
                    result.boolVal = leftResult.boolVal && rightResult.boolVal;
                }
                else if (root == "gt")
                {
                    result.boolVal = leftResult.boolVal > rightResult.boolVal;
                }
                else if (root == "lt")
                {
                    result.boolVal = leftResult.boolVal < rightResult.boolVal;
                }
                else if (root == "geq")
                {
                    result.boolVal = leftResult.boolVal >= rightResult.boolVal;
                }
                else if (root == "leq")
                {
                    result.boolVal = leftResult.boolVal <= rightResult.boolVal;
                }
                else if (root == "eq")
                {
                    result.boolVal = leftResult.boolVal == rightResult.boolVal;
                }
                else if (root == "neq")
                {
                    result.boolVal = leftResult.boolVal != rightResult.boolVal;
                }
            }

            return result;
        }
        else if (left && root == "not")
        {
            Value result;
            result.isBoolSet = true;
            result.boolVal = !left->Eval().boolVal;
            result.type = "bool";
            return result;
        }
        else if (left && root == "-")
        {
            Value result;
            if (left->type == "float")
            {
                result.isFloatSet = true;
                result.floatVal = -(left->Eval().floatVal);
                result.type = "int";
            }
            else
            {
                result.isIntSet = true;
                result.intVal = -(left->Eval().intVal);
                result.type = "int";
            }
            return result;
        }
        else
        {
            return val;
        }
    }

    string TypeOf()
    {
        if (!root.empty())
        {
            if (left && right)
            {
                string leftType = left->TypeOf();
                string rightType = right->TypeOf();

                if (!leftType.empty() && !rightType.empty())
                {
                    if (leftType == rightType)
                    {
                        if (root == "+" || root == "-" || root == "/" || root == "*" || root == "%")
                        {
                            this->type = leftType;
                            return leftType;
                        }
                        else
                        {
                            return "bool";
                        }
                    }
                    else
                    {
                        cout << "Different types: operation " << this->root << " between " << leftType << " and " << rightType << endl;
                        return "Error";
                    }
                }
            }
            else
            {
                return left->TypeOf();
            }
        }

        return type;
    }

    void printAst()
    {

        if (left != NULL)
            this->left->printAst();

        // Print current node's data
        if (!root.empty())
        {
            cout << root << " ";
        }
        else
        {
            if (val.isIntSet)
            {
                cout << val.intVal << " ";
            }
            else if (val.isFloatSet)
            {
                cout << val.floatVal << " ";
            }
            else if (val.isBoolSet)
            {
                cout << val.boolVal << " ";
            }
            else if (val.isCharSet)
            {
                cout << val.charVal << " ";
            }
            else if (val.isStringSet)
            {
                cout << val.stringVal << " ";
            }
        }

        if (right != NULL)
            this->right->printAst();
    }
};