# Day 6: Functions - Defining and Calling Functions

## Introduction

Functions in Bash allow you to group commands into reusable units. They help in organizing code, improving readability, and reducing repetition. Today, we'll explore how to define, call, and work with functions in Bash scripts.

## Defining Functions

There are two common ways to define functions in Bash:

1. Using the `function` keyword:
    

    function function_name {
        # commands
    }
    
        Without the function keyword:
    
    bash
    function_name() {
        # commands
    }

Both methods are equivalent. Choose the one that you find more readable.
Calling Functions
To call a function, simply use its name:


    function_name

- Function Parameters
    - Functions can accept parameters, which are accessed using $1, $2, etc., similar to script arguments:

    
    greet() {
        echo "Hello, $1!"
    }
    
    greet "Funmi"  # Outputs: Hello, Funmi!

Return Values
Bash functions don't return values like in other programming languages. Instead, they can:

    Use the return command to exit the function with a status code:

    
    is_even() {
        if (( $1 % 2 == 0 )); then
            return 0  # Success (true)
        else
            return 1  # Failure (false)
        fi
    }


Echo a result that can be captured:

    
    get_square() {
        echo $(($1 * $1))
    }
    
    result=$(get_square 5)
    echo "The square is $result"

- Local Variables
    - Use the local keyword to declare variables that are local to the function:

    
    my_function() {
        local my_var="local value"
        echo "$my_var"
    }

Function Examples

Simple greeting function:

    
    greet() {
        echo "Hello, $1! Welcome to Bash scripting."
    }
    
    greet "Chuks"


Function with multiple parameters:

    
    calculate() {
        case $2 in
            +) echo $(($1 + $3));;
            -) echo $(($1 - $3));;
            *) echo $(($1 * $3));;
            /) echo $(($1 / $3));;
        esac
    }
    
    result=$(calculate 10 + 5)
    echo "Result: $result"


- Function using return value:

    
    is_file() {
        if [ -f "$1" ]; then
            return 0
        else
            return 1
        fi
    }
    
    if is_file "example.txt"; then
        echo "example.txt exists"
    else
        echo "example.txt does not exist"
    fi

## Exercises

1. Write a function that takes a string as input and returns the reverse of that string.

2. Create a script with a function that calculates the factorial of a given number. The function should use recursion.

3. Write a function that checks if a given number is prime. Then use this function in a script that finds all prime numbers between 1 and 100.

4. Create a function that takes a filename as an argument and prints the number of lines, words, and characters in the file. Use this function to analyze multiple files in a script.

5. Write a script with a function that generates a random password. The function should accept the password length as an argument and use a mix of uppercase, lowercase, numbers, and special characters.

## Additional Resources

- [Bash Functions](https://tldp.org/LDP/abs/html/functions.html)
- [Bash Scripting Tutorial: Functions](https://ryanstutorials.net/bash-scripting-tutorial/bash-functions.php)
- [Advanced Bash-Scripting Guide: Functions](https://tldp.org/LDP/abs/html/complexfunct.html)
