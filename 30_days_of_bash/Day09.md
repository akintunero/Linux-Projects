# Day 9: Working with Arrays

## Introduction

Arrays in Bash allow you to store multiple values in a single variable. They are useful for organizing and manipulating sets of data. This lesson covers the basics of creating, accessing, and manipulating arrays in Bash scripts.

## Creating Arrays

There are several ways to create arrays in Bash:

1. Explicit declaration:
   

    declare -a my_array

 Assigning values directly:

    
    my_array=(value1 value2 value3)

Assigning values individually:


    my_array="value1"
    my_array="value2"
    my_array="value3"

### Accessing Array Elements

Accessing a specific element:

    
    echo ${my_array}

Accessing all elements:


    echo ${my_array[@]}

Accessing a range of elements:


    echo ${my_array[@]:1:2}  # Start from index 1, get 2 elements

### Array Operations

Getting the length of an array:

    
    echo ${#my_array[@]}

Adding elements to an array:


    my_array+=(new_value)

Removing elements from an array:

    unset my_array

Copying an array:

    new_array=("${my_array[@]}")

### Iterating Over Arrays

Using a for loop:

    
    for element in "${my_array[@]}"
    do
        echo "$element"
    done

Using indices:

    
    for i in "${!my_array[@]}"
    do
    echo "Element $i is ${my_array[i]}"
    done

### Associative Arrays 
- Associative arrays use strings as keys instead of integers:

    
    declare -A assoc_array
    assoc_array[key1]="value1"
    assoc_array[key2]="value2"
    
    echo ${assoc_array[key1]}

### Practical Examples

Sorting an array:

    
    sorted_array=($(printf '%s\n' "${my_array[@]}" | sort))

Finding unique elements:


    unique_array=($(printf '%s\n' "${my_array[@]}" | sort -u))

Joining array elements:


    joined_string=$(IFS=", "; echo "${my_array[*]}")

## Exercises

1. Write a script that creates an array of your favorite foods and then prints each item in the array on a new line.

2. Create a script that takes command-line arguments and stores them in an array. Then, print the number of arguments and each argument's value.

3. Write a function that takes an array as input and returns a new array with only the unique elements.

4. Create a script that reads a file line by line into an array, then performs some operation on each line (e.g., converting to uppercase).

5. Write a script that uses an associative array to store and retrieve key-value pairs (e.g., country names and their capitals).

## Additional Resources

- [Bash Arrays](https://www.gnu.org/software/bash/manual/html_node/Arrays.html)
- [Advanced Bash-Scripting Guide: Arrays](https://tldp.org/LDP/abs/html/arrays.html)
- [Bash Associative Arrays](https://www.gnu.org/software/bash/manual/html_node/Associative-Arrays.html)