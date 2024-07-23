# Conditional Statements

Conditional statements are one of the most basic fundamentals in programming; they allow a program to execute different code blocks based on certain conditions. This tutorial is designed to introduce you to very simple conditional statements and help you with some exercises for practice.

## if Statements
An if statement tests a condition. If the condition is true, the block of code that follows will be executed.

### Syntax:

        if condition; then
            # code to execute if condition is true
        fi

Example:

        
        x=10
        if [ $x -gt 5 ]; then
            echo "x is greater than 5"
        fi

if-else Statements

The if-else statement is used to test a condition and execute one block of code if the condition is true, and another block of code if the condition is false.
Syntax:

        
        
        if condition; then
            # code to execute if condition is true
        else
            # code to execute if condition is false
        fi

Example:
        
        x=3
        if [ $x -gt 5 ]; then
            echo "x is greater than 5"
        else
            echo "x is not greater than 5"
        fi

Nested if Statements

Nested if statements are if statements within other if or else blocks. They allow for more complex conditions and multiple decision paths.
Syntax:



        if condition1; then
            # code to execute if condition1 is true
            if condition2; then
                # code to execute if condition2 is also true
            else
                # code to execute if condition1 is true and condition2 is false
            fi
        else
            # code to execute if condition1 is false
        fi

Example:


        x=10
        y=20
        if [ $x -gt 5 ]; then
            if [ $y -gt 15 ]; then
                echo "x is greater than 5 and y is greater than 15"
            else
                echo "x is greater than 5 but y is not greater than 15"
            fi
        else
            echo "x is not greater than 5"
        fi

Exercises
Exercise : Check if a Number is Positive, Negative, or Zero

Create a script that prompts the user to enter a number and then checks if the number is positive, negative, or zero.
Solution:

        
        #!/bin/bash
        
        # Get user input
        read -p "Enter a number: " number
        
        # Determine if the number is positive, negative or zero
        if (( $(echo "$number > 0" | bc -l) )); then
            echo "The number is positive."
        elif (( $(echo "$number < 0" | bc -l) )); then
            echo "The number is negative."
        else
            echo "The number is zero."
        fi

Additional Study:

- [Bash If-Else Statement](https://www.freecodecamp.org/news/bash-if-statement-linux-shell-if-else-syntax-example/)
- [Linuxize - Bash If Statement](https://linuxize.com/post/bash-if-else-statement/)
- [TutorialsPoint - Unix Shell Scripting](https://www.tutorialspoint.com/unix/shell_scripting.htm)


