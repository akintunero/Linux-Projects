# Loops - Part 2

In this lesson, we'll explore `until` loops and loop control statements (`break` and `continue`). These concepts are essential for controlling the flow of your scripts and handling more complex looping scenarios.

## Topics

### 1. `until` Loops
An `until` loop is similar to a `while` loop, but it continues executing the block of code until the specified condition becomes true. In other words, the block of code runs as long as the condition is false.

**Syntax:**

    until condition; do
        # code to execute while condition is false
    done

Explanation:

    condition: An expression that is evaluated before each iteration of the loop. If the condition is false, the loop continues; if it is true, the loop stops.

Example:

    i=10
    until [ $i -lt 1 ]; do
        echo $i
        i=$((i - 1))
    done


In this example, the until loop counts down from 10 to 1, decrementing the variable i by 1 in each iteration.

2. Loop Control (break, continue)

Loop control statements are used to alter the flow of a loop. The two primary control statements in shell scripting are break and continue.
break Statement

The break statement is used to exit the loop prematurely, regardless of the loop's condition.

Syntax:


    break

Example:

    for i in {1..10}; do
        if [ $i -eq 7 ]; then
            break
        fi
        echo $i
    done

In this example, the loop prints numbers from 1 to 6. When i equals 7, the break statement exits the loop.
continue Statement

The continue statement skips the rest of the code inside the current iteration of the loop and jumps to the next iteration.

Syntax:

    continue

Example:

    for i in {1..10}; do
        if [ $i -eq 7 ]; then
            continue
        fi
        echo $i
    done

In this example, the loop prints numbers from 1 to 10, except for 7. When i equals 7, the continue statement skips the print statement for that iteration.

### Exercises
Exercise 1: Countdown Timer

Create a script that counts down from 10 to 1 using an until loop and then prints "Happy New Year!".

Solution:

    i=10
    until [ $i -lt 1 ]; do
        echo $i
        i=$((i - 1))
    done
    echo "Happy New Year!"

Exercise 2: Skip Number

Write a script that prints numbers from 1 to 10, but skips the number 5 using a for loop and the continue statement.

Solution:

    for i in {1..10}; do
        if [ $i -eq 5 ]; then
            continue
        fi
        echo $i
    done

Exercise 3: Exit Loop Early

Write a script that prints numbers from 1 to 10, but exits the loop if the number is greater than or equal to 8 using a while loop and the break statement.

Solution:

    i=1
    while [ $i -le 10 ]; do
        if [ $i -ge 8 ]; then
            break
        fi
        echo $i
        i=$((i + 1))
    done


Additional Resources

    Bash Until Loop
    Linuxize - Bash Break and Continue
    TutorialsPoint - Unix Shell Scripting
