# Day 24: Creating Interactive Scripts with the `read` Command

## Introduction

The `read` command in Bash is a powerful tool for creating interactive scripts. It allows you to accept user input, making your scripts more dynamic and user-friendly. This lesson covers various ways to use the `read` command effectively in your Bash scripts.

## Basic Usage of `read`

The simplest form of the `read` command:


    read variable_name

Example:

    
    echo "Enter your name:"
    read name
    echo "Hello, $name!"

Read Command Options
1. Prompt with -p


    read -p "Enter your age: " age

2. Silent Input with -s
Useful for passwords:

    
    read -sp "Enter password: " password
    echo

3. Timeout with -t


    read -t 5 -p "You have 5 seconds to answer: " answer

4. Read a Specific Number of Characters with -n

    
    read -n 1 -p "Do you agree? (y/n) " response

5. Using a Delimiter with -d

    
    read -d "," -p "Enter comma-separated values: " values

Reading Multiple Variables


    read -p "Enter first and last name: " first_name last_name
    echo "First Name: $first_name, Last Name: $last_name"

Reading from a File


    while IFS= read -r line
    do
      echo "$line"
    done < input.txt

### Practical Examples

Simple Calculator:


#!/bin/bash

    read -p "Enter first number: " num1
    read -p "Enter second number: " num2
    read -p "Enter operation (+, -, *, /): " operation
    
    case $operation in
      +) result=$(( num1 + num2 ));;
      -) result=$(( num1 - num2 ));;
      *) result=$(( num1 * num2 ));;
      /) result=$(( num1 / num2 ));;
      *) echo "Invalid operation"; exit 1;;
    esac
    
    echo "Result: $result"


Interactive Menu:


    #!/bin/bash
    
    while true; do
      echo "1. Option 1"
      echo "2. Option 2"
      echo "3. Exit"
      read -p "Select an option: " choice
      
      case $choice in
        1) echo "You selected Option 1";;
        2) echo "You selected Option 2";;
        3) echo "Exiting..."; exit 0;;
        *) echo "Invalid option";;
      esac
    done


## Exercises

1. Create a script that asks for a user's name, age, and favorite color, then prints a personalized message using this information.

2. Write a script that simulates a simple quiz game. Ask the user multiple-choice questions and keep track of their score.

3. Develop a script that reads a list of tasks from the user (one per line) until they enter an empty line, then saves these tasks to a file.

4. Create an interactive script that allows the user to manage a simple contact list (add, view, delete contacts).

5. Write a script that asks the user for system information (e.g., hostname, IP address) and uses this input to generate a simple configuration file.

## Additional Resources

- [Bash `read` Command](https://linuxize.com/post/bash-read/)
- [Advanced Bash-Scripting Guide: I/O Redirection](https://tldp.org/LDP/abs/html/io-redirection.html)
- [Bash Scripting Tutorial: User I