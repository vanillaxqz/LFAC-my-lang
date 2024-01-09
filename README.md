## What is this?
A custom programming language designed using YACC/BISON with grammar rules coded in C++ for a university assignment.

## Features

### 1. Language Structure and Syntax
- **Type Declarations:**
  - Predefined Types: `int`, `float`, `char`, `string`, `bool`.
  - Array Types.
  - User-Defined Data Types: Syntax for initialization and usage of variables, accessing fields and methods.

- **Variable Declarations/Definitions, Constant Definitions, Function Definitions.**

- **Control Statements:** Includes `if`, `for`, `while`, etc.

- **Assignment Statements:** Follows the format `left_value = expression`.

- **Arithmetic and Boolean Expressions:** Support for complex expressions with true and false values.

- **Function Calls:** Allows expressions, other function calls, identifiers, constants, etc., as parameters.

- **Predefined Functions:**
  - `Eval(arg)`: Evaluates arithmetic or boolean expressions, or variables/literals of type float, bool, or int.
  - `TypeOf(arg)`: Returns the type of the argument.

- **Program Structure:**
  1. User Defined Data Types Section.
  2. Global Variables Section.
  3. Global Function Definitions Section.
  4. Main Section.

### 2. Symbol Table Creation
- **Variables/Constants:** Includes type, name, value, and definition context (function or class).
- **Functions:** Details about name, return type, parameter types, and definition context.
- **Printable:** The table is exported to a text file.

### 3. Semantic Analysis
Ensures that:
- **Variable and Function Definitions:** Checks for prior definitions.
- **Unique Variable Declarations:** Prevents redeclaration.
- **Type Consistency in Expressions:** Enforces same-type operands, without casting.
- **Assignment Type Matching:** Ensures type alignment between left and right sides of an assignment.
- **Function Call Parameter Types:** Validates against the function definition.
- **Detailed Error Messages:** Provided for any violations.

### 4. Expression Evaluation and Type Evaluation
- **AST for Arithmetic and Boolean Expressions:**
  - Class representation of an AST.
  - Member functions for evaluating AST with different return values.
  - Evaluation logic based on the AST structure.
- **Implementation of `Eval(expr)` and `TypeOf`:**
  - `Eval(expr)`: Prints the actual value of the expression.
  - `TypeOf`: Returns the expression type and checks for semantic errors.

## How to run your own input
In a terminal:
First, clone the repository from GitHub:
```bash
git clone https://github.com/vanillaxqz/LFAC-my-lang.git
```
Change the permissions of the compile script and run it:
```bash
chmod u+x compile.sh
./compile.sh lang
```
To run your own program written in this custom language (replace src.txt with the path to your source file):
```bash
./lang src.txt
```
