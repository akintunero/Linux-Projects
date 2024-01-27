# Day 12: Using `awk` for Data Extraction

## Introduction

`awk` is a powerful text-processing tool used for data extraction and reporting. It's particularly useful for working with structured data like CSV files or log files. This lesson covers the basics of `awk` and how to use it effectively in Bash scripts.

## Basic `awk` Syntax

The basic syntax of `awk` is:


    awk 'pattern { action }' file

If no file is specified, awk reads from standard input.
- Key Concepts in awk


    Fields: awk automatically splits each line into fields. By default, fields are separated by whitespace.
    Records: Each line of input is a record.
    Patterns: Determine which records to process.
    Actions: Specify what to do with the selected records.

Common awk Commands
1. Print Specific Fields
Print the first and third fields:


    awk '{ print $1, $3 }' file.txt

2. Using Field Separator
Specify a custom field separator:


    awk -F',' '{ print $2 }' file.csv

3. Conditional Printing
Print lines where the first field is greater than 10:


    awk '$1 > 10 { print $0 }' file.txt

4. Built-in Variables


    NF: Number of fields in the current record
    NR: Current record number
    FS: Field separator (default is whitespace)
    OFS: Output field separator

Example:


    awk '{ print NR ":", $1 }' file.txt

Advanced awk Usage
1. Using Regular Expressions
Print lines matching a pattern:


    awk '/pattern/ { print $0 }' file.txt

2. Begin and End Blocks
Perform actions before processing any lines and after processing all lines:


    awk 'BEGIN { print "Start" } { print $0 } END { print "End" }' file.txt

3. Arithmetic Operations
Perform calculations on fields:


    awk '{ sum += $1 } END { print "Sum:", sum }' file.txt

4. Functions
awk provides various built-in functions:


    awk '{ print toupper($1) }' file.txt

Practical Examples

Calculate average of numbers in a file:


    awk '{ sum += $1 } END { print "Average =", sum/NR }' numbers.txt

Extract specific columns from a CSV file:


    awk -F',' '{ print $2 "," $4 }' data.csv

Count occurrences of a word in a file:


    awk '/word/ { count++ } END { print "Count:", count }' file.txt

Format output of a command:


    ls -l | awk '{ print $9 ": " $5 " bytes" }'

## Exercises

1. Write an `awk` command to print all lines from a file where the second field is greater than 50.

2. Create a script that uses `awk` to calculate and print the sum and average of a column of numbers in a CSV file.

3. Use `awk` to extract and print all email addresses from a text file, assuming they follow the pattern user@domain.com.

4. Write an `awk` script that reads a log file and reports the number of occurrences of each unique IP address.

5. Create an `awk` script that reads a CSV file of student grades and prints out the name and grade of the student with the highest score.

## Additional Resources

- [GNU Awk User's Guide](https://www.gnu.org/software/gawk/manual/gawk.html)
- [Awk - A Tutorial and Introduction](https://www.grymoire.com/Unix/Awk.html)
- [Awk One-Liners Explained](https://catonmat.net/awk-one-liners-explained-part-one)