# Arithmetic Operators

### Arithmetic operators are used to perform mathematical operations like addition, subtraction, multiplication, and division.

Common Operators:

- `+`: Addition (e.g., 5 + 3 results in 8)
- `-`: Subtraction (e.g., 10 - 4 results in 6)
- `*`: Multiplication (e.g., 7 * 2 results in 14)
- `/`: Division (e.g., 8 / 2 results in 4)
- `%`: Modulus (remainder of division, e.g., 10 % 3 results in 1)

### Usage Example in Shell Script

    #!/bin/bash
    
    num1=10
    num2=5
    
    sum=$((num1 + num2))
    difference=$((num1 - num2))
    product=$((num1 * num2))
    quotient=$((num1 / num2))
    remainder=$((num1 % num2))
    
    echo "Sum: $sum"
    echo "Difference: $difference"
    echo "Product: $product"
    echo "Quotient: $quotient"
    echo "Remainder: $remainder"

Comparison Operators
Comparison operators are used to compare two values and return a boolean result (true or false).

Common Operators:
    
    -eq: Equal to (e.g., [ $num1 -eq $num2 ] checks if num1 is equal to num2)
    -ne: Not equal to (e.g., [ $num1 -ne $num2 ] checks if num1 is not equal to num2)
    -lt: Less than (e.g., [ $num1 -lt $num2 ] checks if num1 is less than num2)
    -le: Less than or equal to (e.g., [ $num1 -le $num2 ] checks if num1 is less than or equal to num2)
    -gt: Greater than (e.g., [ $num1 -gt $num2 ] checks if num1 is greater than num2)
    -ge: Greater than or equal to (e.g., [ $num1 -ge $num2 ] checks if num1 is greater than or equal to num2)

Usage Example in Shell Script

    #!/bin/bash
    
    num1=10
    num2=5
    
    if [ $num1 -gt $num2 ]; then
        echo "$num1 is greater than $num2"
    else
        echo "$num1 is not greater than $num2"
    fi

## Logical Operators
Logical operators are used to combine multiple conditions and return true or false based on the combined result.

Common Operators:
        
        -a: Logical AND (e.g., [ $num1 -gt 5 -a $num2 -lt 10 ] checks if num1 is greater than 5 AND num2 is less than 10)
        -o: Logical OR (e.g., [ $num1 -gt 5 -o $num2 -lt 3 ] checks if num1 is greater than 5 OR num2 is less than 3)
        !: Logical NOT (e.g., ![ $num1 -eq 10 ] checks if num1 is NOT equal to 10)

Usage Example in Shell Script

    #!/bin/bash
    num1=10
    num2=5
    
    if [ $num1 -gt 5 ] && [ $num2 -lt 10 ]; then
        echo "$num1 is greater than 5 AND $num2 is less than 10"
    else
        echo "Condition not met"
    fi

### Exercises
Basic Arithmetic Operations Script
Write a script that prompts the user to input two numbers and then performs addition, subtraction, multiplication, and division on those numbers. Display the results for each operation.

    #!/bin/bash
    
    echo "Enter the first number:"
    read num1
    echo "Enter the second number:"
    read num2
    
    sum=$((num1 + num2))
    difference=$((num1 - num2))
    product=$((num1 * num2))
    quotient=$((num1 / num2))
    
    echo "Sum: $sum"
    echo "Difference: $difference"
    echo "Product: $product"
    echo "Quotient: $quotient"

Comparison Script
Write a script that asks the user for two numbers and then compares them using different comparison operators. Display messages based on the results of these comparisons.

    #!/bin/bash
    
    echo "Enter the first number:"
    read num1
    echo "Enter the second number:"
    read num2
    
    if [ $num1 -eq $num2 ]; then
        echo "The numbers are equal."
    else

  
