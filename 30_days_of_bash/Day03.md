# Day 3: Understanding Variables and Basic Data Types in Bash

## Introduction

Variables are fundamental to any programming language, including Bash. They allow you to store and manipulate data within your scripts. In this lesson, we'll explore how to work with variables and understand the basic data types in Bash.

## Variables in Bash

In Bash, variables are used to store data of various types. Here are some key points about variables:

- Variable names can contain letters, numbers, and underscores.
- They must start with a letter or underscore.
- Bash is case-sensitive, so `myVar` and `myvar` are different variables.
- When assigning values, there should be no spaces around the equals sign.

### Declaring and Using Variables

To declare a variable:


    my_variable="Hello, World!"
    
    To use a variable, prefix it with a $:
    
    bash
    echo $my_variable

You can also use curly braces to clearly define the variable name:


    echo ${my_variable}

Basic Data Types
Bash doesn't have explicit data types like some programming languages, but it does work with different types of data:
1. Strings
Strings are sequences of characters:


    name="Olumayowa Akin"
    echo "Hello, $name"

2. Integers
Bash can perform arithmetic operations on integers:

    
    age=21
    echo "In 5 years, you will be $((age + 5)) years old"

3. Arrays
Bash supports indexed and associative arrays:


# Indexed array
    fruits=("apple" "banana" "cherry")
    echo ${fruits}  # Outputs: banana

# Associative array 
    declare -A colors
    colors[red]="#FF0000"
    colors[green]="#00FF00"
    echo ${colors[red]}  # Outputs: #FF0000

Special Variables
Bash has several special variables:

    $0: The name of the script
    $1, $2, etc.: Command-line arguments passed to the script
    $#: The number of command-line arguments
    $@: All command-line arguments
    $?: The exit status of the last command
    $$: The process ID of the current script

Command Substitution
You can use the output of a command as a value:
    
    
    current_date=$(date +%Y-%m-%d)
    echo "Today is $current_date"
## Exercises

1. Create a script that asks for the user's name and age, stores them in variables, and then prints a greeting including this information.

2. Write a script that takes two numbers as command-line arguments, stores them in variables, and then performs and displays the results of addition, subtraction, multiplication, and division on these numbers.

3. Create an array of your favorite books. Write a script that prints out each book on a new line, preceded by its index in the array.

4. Write a script that uses command substitution to get the current user, current directory, and current date/time, and prints this information in a formatted manner.

5. Create a script that demonstrates the use of at least three special variables. For example, it could print the script name, the number of arguments passed to it, and all the arguments.

## Additional Resources

- [Bash Variables](https://tldp.org/LDP/abs/html/variables.html)
- [Bash Arrays](https://www.gnu.org/software/bash/manual/html_node/Arrays.html)
- [Special Parameters in Bash](https://www.gnu.org/software/bash/manual/html_node/Special-Parameters.html)