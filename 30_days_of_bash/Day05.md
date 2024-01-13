# Day 5: Loops - For and While Loops

## Introduction

Loops are essential programming constructs that allow you to execute a block of code repeatedly. In Bash, the two primary types of loops are `for` loops and `while` loops. Today, we'll explore how to use these loops effectively in your scripts.

## For Loops

The `for` loop is used to iterate over a sequence of values or elements.

### Basic Syntax


    for variable in list
    do
        # commands to execute
    done

Examples

- Iterating over a list of values:

    
    for fruit in apple banana orange
    do
        echo "I like $fruit"
    done

- Iterating over a range of numbers:

    
    for i in {1..5}
    do
        echo "Number: $i"
    done

- Iterating over files in a directory:

    
    for file in *.txt
    do
        echo "Processing $file"
    done

- C-style for loop:

    
    for ((i=0; i<5; i++))
    do
        echo "Iteration $i"
    done

- While Loops
    - The while loop executes a block of code as long as a condition is true.
Basic Syntax


    while [ condition ]
    do
        # commands to execute
    done

Examples

- Basic while loop:

    
    count=1
    while [ $count -le 5 ]
    do
        echo "Count: $count"
        ((count++))
    done

- Reading input:

    
    while read -p "Enter a name (or 'q' to quit): " name
    do
        if [ "$name" = "q" ]
        then
            break
        fi
        echo "Hello, $name!"
    done

- Infinite loop with break:

    
    while true
    do
        echo "This will run forever unless interrupted"
        sleep 1
        if [ "$RANDOM" -eq 0 ]
        then
            echo "Lucky break!"
            break
        fi
    done

- Loop Control

    - break: Exits the loop immediately
    - continue: Skips the rest of the current iteration and moves to the next

Example:

    
    for i in {1..10}
    do
        if [ $i -eq 5 ]
        then
            continue
        fi
        if [ $i -eq 8 ]
        then
            break
        fi
        echo "Number: $i"
    done


## Exercises

1. Write a script that uses a for loop to print the multiplication table for a given number (input by the user).

2. Create a script that uses a while loop to simulate a simple guessing game. Generate a random number between 1 and 10, and let the user guess until they get it right.

3. Write a script that uses a for loop to iterate through all the files in the current directory and print their names and sizes.

4. Create a script that uses a while loop to calculate the factorial of a number input by the user.

5. Write a script that uses nested for loops to create a simple multiplication table for numbers 1 through 5.

## Additional Resources

- [Bash For Loop Examples](https://www.cyberciti.biz/faq/bash-for-loop/)
- [Bash While Loop Examples](https://www.cyberciti.biz/faq/bash-while-loop/)
- [Advanced Bash-Scripting Guide: Loops](https://tldp.org/LDP/abs/html/loops1.html)
