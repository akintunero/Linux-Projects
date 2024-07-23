# Loops - Part 1

Loops are a crucial concept in programming that allows you to repeat a block of code multiple times. This repetition can be useful for tasks like processing items in a list, automating repetitive tasks, and more. In this lesson, we'll explore two types of loops in shell scripting: `for` loops and `while` loops.


### 1. `for` Loops
A `for` loop is used to iterate over a sequence (such as a list or a range) and execute a block of code for each item in the sequence. This type of loop is particularly useful when you know in advance how many times you want to execute a statement or a block of statements.

**Syntax:**

    for item in sequence; do
        # code to execute for each item
    done

Explanation:

    item: A variable that takes the value of the next element in the sequence each time through the loop.
    sequence: The collection of items (like a list or a range) that the loop will iterate over.

Example:

        for i in {1..10}; do
            echo $i
        done

In this example, the for loop iterates over a range of numbers from 1 to 10, printing each number.
2. while Loops

A while loop repeatedly executes a block of code as long as a given condition is true. This type of loop is useful when you do not know beforehand how many iterations you will need.

Syntax:

        while condition; do
            # code to execute while condition is true
        done

Explanation:

condition: An expression that is evaluated before each iteration of the loop. If the condition is true, the loop continues; if it is false, the loop stops.

Example:

        i=1
        while [ $i -le 10 ]; do
            echo $i
            i=$((i + 1))
        done

In this example, the while loop continues to print numbers from 1 to 10 as long as the condition i -le 10 is true. The variable i is incremented by 1 in each iteration to eventually break the loop when i becomes greater than 10.
Detailed Explanation and Examples
For Loops: Detailed Example

A common use case for 'for loops' is iterating over a list of items. For instance, if you have a list of names and you want to print a greeting for each name, you can use a for loop.

Example:

        names=("Alice" "Bob" "Charlie")
        for name in "${names[@]}"; do
            echo "Hello, $name!"
        done

In this example:

names is an array containing three strings.
The for loop iterates over each name in the array.
For each iteration, the loop prints a greeting that includes the current name.

While Loops: Detailed Example

A while loop is often used when the number of iterations is not known in advance. For example, you might want to keep asking the user for input until they enter a specific value.

Example:

        password=""
        while [ "$password" != "secret" ]; do
            read -sp "Enter the password: " password
            echo
        done
        echo "Access granted"

In this example:

The while loop continues to prompt the user for a password until they enter "secret".
When the correct password is entered, the loop terminates, and "Access granted" is printed.

Exercises
Exercise 1: Print Numbers from 1 to 10

Write a script that prints numbers from 1 to 10 using both for and while loops.

Solution using for Loop:

        for i in {1..10}; do
            echo $i
        done

Solution using while Loop:

        i=1
        while [ $i -le 10 ]; do
            echo $i
            i=$((i + 1))
        done

Exercise 2: Sum of a List

Write a script that calculates the sum of all numbers in a list using a for loop.

Solution:

        numbers=(1 2 3 4 5)
        total=0
        for number in "${numbers[@]}"; do
            total=$((total + number))
        done
        echo "The sum is: $total"

Exercise 3: Countdown Timer

Write a script that counts down from 10 to 1 using a while loop and then prints "Happy New Year!".

Solution:

        i=10
        while [ $i -gt 0 ]; do
            echo $i
            i=$((i - 1))
        done
        echo "Happy New Year!"


Additional documentation:

- [Bash If-Else Statement](https://www.freecodecamp.org/news/bash-if-statement-linux-shell-if-else-syntax-example/)
- [Linuxize - Bash If Statement](https://linuxize.com/post/bash-if-else-statement/)
- [TutorialsPoint - Unix Shell Scripting](https://www.tutorialspoint.com/unix/shell_scripting.htm)
