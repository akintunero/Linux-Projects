# Day 11: Using `sed` for Text Processing

## Introduction

`sed` (stream editor) is a powerful text processing tool in Unix-like operating systems. It's used for parsing and transforming text. This lesson covers the basics of `sed` and how to use it effectively in Bash scripts.

## Basic `sed` Syntax

The basic syntax of `sed` is:


    sed [options] 'command' file

If no file is specified, sed reads from standard input.
Common sed Commands

1. Substitution
Replace the first occurrence of a pattern in each line:


    sed 's/old/new/' file.txt

Replace all occurrences:


    sed 's/old/new/g' file.txt

2. Deletion
- Delete lines matching a pattern:


    sed '/pattern/d' file.txt

3. Insertion and Appending
- Insert a line before a match:


    sed '/pattern/i\New line' file.txt

Append a line after a match:


    sed '/pattern/a\New line' file.txt

4. Printing Specific Lines
- Print lines matching a pattern:


    sed -n '/pattern/p' file.txt

Advanced sed Usage
1. Using Regular Expressions
sed supports basic regular expressions by default:


    sed 's/[0-9]\+/NUMBER/' file.txt

For extended regular expressions, use the -E flag:


    sed -E 's/[0-9]+/NUMBER/' file.txt

2. Multiple Commands
Use -e for multiple commands:


    sed -e 's/old/new/' -e 's/foo/bar/' file.txt

3. In-place Editing
To edit files in-place, use the -i option:


    sed -i 's/old/new/g' file.txt

4. Using sed Variables
Use variables in sed commands:


    old="foo"
    new="bar"
    sed "s/$old/$new/g" file.txt

Practical Examples

Remove empty lines from a file:


    sed '/^$/d' file.txt

Add line numbers to a file:


    sed = file.txt | sed 'N;s/\n/\t/'

Convert Windows line endings to Unix:


    sed 's/\r$//' file.txt

Extract emails from a file:


    sed -n 's/.*$$[a-zA-Z0-9._%+-]\+@[a-zA-Z0-9.-]\+\.[a-zA-Z]\{2,\}$$.*/\1/p' file.txt

## Exercises

1. Write a `sed` command to replace all occurrences of "color" with "colour" in a file, but only for whole words (not parts of other words).

2. Create a script that uses `sed` to remove all HTML tags from a file.

3. Write a `sed` command to swap the first and second words of each line in a file.

4. Use `sed` to extract all phone numbers from a file, assuming they are in the format (xxxx) xxx-xxxx.

5. Create a script that uses `sed` to comment out all lines in a configuration file that start with a specific word (e.g., "DEBUG").

## Additional Resources

- [GNU sed Manual](https://www.gnu.org/software/sed/manual/sed.html)
- [Sed - An Introduction and Tutorial](https://www.grymoire.com/Unix/Sed.html)
- [Advanced Sed Commands](https://www.gnu.org/software/sed/manual/html_node/Advanced-sed-commands.html)
