# Conditional Statements

Conditional statements are one of the most basic fundamentals in programming; they allow a program to execute different code blocks based on certain conditions. This tutorial is designed to introduce you to very simple conditional statements and help you with some exercises for practice.



if Statements
An if statement tests a condition. If the condition is true, the block of code that follows will be executed:.

Syntax:
    
    if condition:
        # code to execute if condition is true

Example:



    x = 10
    if x > 5:
        print("x is greater than 5")

if-else Statements
The if-else statement is used to test a condition and execute one block of code if the condition is true, and another block of code if the condition is false.

Syntax:


    if condition:
        # code to execute if condition is true
    else:
        # code to execute if condition is false

Example:


    x = 3
    if x > 5:
        print("x is greater than 5")
    else:
        print("x is not greater than 5")

Nested if Statements
Nested if statements are if statements within other if or else blocks. They allow for more complex conditions and multiple decision paths.

Syntax:

    if condition1:
        # code to execute if condition1 is true
        if condition2:
            # code to execute if condition2 is also true
        else:
            # code to execute if condition1 is true and condition2 is false
    else:
        # code to execute if condition1 is false

Example:
    
    x = 10
    y = 20
    if x > 5:
        if y > 15:
            print("x is greater than 5 and y is greater than 15")
        else:
            print("x is greater than 5 but y is not greater than 15")
    else:
        print("x is not greater than 5")

Exercises
Exercise 1: Check if a Number is Positive, Negative, or Zero
Create a script that prompts the user to enter a number and then checks if the number is positive, negative, or zero.

Solution:



    # Get user input
    number = float(input("Enter a number: "))
    
    # Determine if the number is positive, negative or zero
    if number > 0:
        print("The number is positive.")
    elif number < 0:
        print("The number is negative.")
    else:
        print("The number is zero.")

This script uses if-elif-else to check the condition and give out the required print message.

Here are some additional resources for learning about conditional statements:

- [Python Documentation on Conditional Statements](https://docs.python.org/3/tutorial/controlflow.html#if-statements)
- [W3Schools - Python If...Else](https://www.w3schools.com/python/gloss_python_else.asp)
- [Real Python - Conditional Statements in Python](https://realpython.com/python-conditional-statements/)
