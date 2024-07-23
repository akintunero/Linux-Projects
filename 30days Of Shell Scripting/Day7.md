# Functions - Part 1

In this lesson, we'll explore functions in shell scripting. Functions allow you to group a set of commands into a single unit, making your scripts more modular and reusable. 

## Topics

### 1. Defining and Calling Functions

A function is a block of code that can be reused multiple times throughout your script. Defining a function involves specifying its name and the commands it will execute. Once defined, you can call the function by its name, which will execute the block of code contained within it.

**Syntax:**
    
    function_name() {
        # commands to be executed
    }
    
Example:

    greet() {
        echo "Hello, World!"
    }
    
    # Call the function
    greet

In this example, we define a function named greet that prints "Hello, World!" to the terminal. After defining the function, we call it by simply writing its name, which executes the code inside the function.
Detailed Explanation and Examples
Defining a Function

To define a function, you use the function name followed by parentheses and curly braces. Inside the curly braces, you write the commands that should be executed when the function is called.


    say_hello() {
        echo "Hello, everyone!"
    }

In this example, we define a function named say_hello that prints a greeting message.
Calling a Function

After defining a function, you can call it by simply using its name.

    say_hello

When you call say_hello, the function executes the commands inside its block, printing "Hello, everyone!" to the terminal.
Passing Arguments to Functions

Functions can also accept arguments, which allows you to pass data to the function when you call it.

Syntax:

    function_name() {
        # $1, $2, etc. are the arguments passed to the function
        echo "Argument 1: $1"
        echo "Argument 2: $2"
    }
    
    # Call the function with arguments
    function_name "First" "Second"

Example:


    greet_person() {
        echo "Hello, $1!"
    }
    
    # Call the function with an argument
    greet_person "Alice"

In this example, we define a function named greet_person that accepts one argument and prints a personalized greeting. When we call the function with the argument "Alice", it prints "Hello, Alice!".
Exercises
Exercise 1: Write a Script with a Function that Prints a Message

Task:
Write a script that defines a function named print_message which prints a custom message to the terminal.

Solution:

    #!/bin/bash
    
    print_message() {
        echo "This is a custom message from the function."
    }
    
    # Call the function
    print_message

Exercise 2: Function with Arguments

Task:
Write a script that defines a function named greet_user which takes a user's name as an argument and prints a personalized greeting.

Solution:

    #!/bin/bash
    
    greet_user() {
        echo "Hello, $1! Welcome to the shell scripting tutorial."
    }
    
    # Call the function with an argument
    greet_user "John"

Exercise 3: Function with Multiple Arguments

Task:
Write a script that defines a function named add_numbers which takes two numbers as arguments, adds them, and prints the result.

Solution:

    #!/bin/bash
    
    add_numbers() {
        sum=$(( $1 + $2 ))
        echo "The sum of $1 and $2 is: $sum"
    }
    
    # Call the function with arguments
    add_numbers 5 7

Additional References:


- [Bash If-Else Statement](https://www.freecodecamp.org/news/bash-if-statement-linux-shell-if-else-syntax-example/)
- [Linuxize - Bash If Statement](https://linuxize.com/post/bash-if-else-statement/)
- [TutorialsPoint - Unix Shell Scripting](https://www.tutorialspoint.com/unix/shell_scripting.htm)
