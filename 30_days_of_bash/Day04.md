# Day 4: Control Flow - If Statements and Test Commands

## Introduction

Control flow structures allow you to make decisions in your scripts. Today, we'll focus on if statements and test commands, which are fundamental to creating conditional logic in Bash scripts.

## If Statements

The basic syntax of an if statement in Bash is:

    
    if [ condition ]
    then
        # commands to execute if condition is true
    fi

You can also use elif (else if) and else:

    
    if [ condition1 ]
    then
        # commands for condition1
    elif [ condition2 ]
    then
        # commands for condition2
    else
        # commands if no conditions are true
    fi

### Test Commands
The square brackets [ ] in if statements are actually a shorthand for the test command. You can use either:

    
    if [ condition ]
    if test condition

- Comparison Operators
    - For numeric comparisons:


    -eq: Equal to
    -ne: Not equal to
    -gt: Greater than
    -ge: Greater than or equal to
    -lt: Less than
    -le: Less than or equal to

- For string comparisons:


    =: Equal to
    !=: Not equal to
    -z: String is empty
    -n: String is not empty


- For file tests:


    -e file: File exists
    -f file: File is a regular file
    -d file: File is a directory
    -r file: File is readable
    -w file: File is writable
    -x file: File is executable

- Examples
    - Numeric comparison:

    
    #!/bin/bash
    age=18
    if [ $age -ge 18 ]
    then
        echo "You are an adult."
    else
        echo "You are a minor."
    fi

- String comparison:

    
    #!/bin/bash
    name="Alice"
    if [ "$name" = "Alice" ]
    then
        echo "Hello, Alice!"
    else
        echo "You're not Alice."
    fi


- File test:

    
    #!/bin/bash
    if [ -f "example.txt" ]
    then
        echo "example.txt exists."
    else
        echo "example.txt does not exist."
    fi

- Logical Operators


    &&: AND
    ||: OR
    !: NOT

- Example:
    
    
    if [ $age -ge 18 ] && [ "$name" = "Alice" ]
    then
        echo "Hello, adult Alice!"
    fi



## Exercises

1. Write a script that takes a number as input and tells if it's positive, negative, or zero.

2. Create a script that checks if a file exists. If it does, print its contents; if not, create it with some default text.

3. Write a script that compares two numbers provided as command-line arguments and prints whether the first number is greater than, less than, or equal to the second number.

4. Create a script that checks if the user running it has write permission for a specified file. Print an appropriate message based on the result.

5. Write a script that asks for a user's age and name. If the user is 18 or older and their name is "Admin", print "Access granted". Otherwise, print "Access denied".

## Additional Resources

- [Bash Conditional Statements](https://tldp.org/LDP/Bash-Beginners-Guide/html/sect_07_01.html)
- [Bash Test Command](https://tldp.org/LDP/abs/html/testconstructs.html)
- [Advanced Bash-Scripting Guide: Tests](https://tldp.org/LDP/abs/html/tests.html)