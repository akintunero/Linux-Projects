# Day 8: Input/Output Redirection

## Introduction

Input/Output (I/O) redirection is a powerful feature in Bash that allows you to control where input comes from and where output goes. This lesson covers the basics of I/O redirection and how to use it effectively in your scripts.

## Standard Streams

In Unix-like operating systems, there are three standard streams:

1. Standard Input (stdin) - Stream for input, file descriptor 0
2. Standard Output (stdout) - Stream for output, file descriptor 1
3. Standard Error (stderr) - Stream for error messages, file descriptor 2

## Basic Redirection Operators

- `>`: Redirect stdout to a file (overwrite)
- `>>`: Redirect stdout to a file (append)
- `<`: Redirect stdin from a file
- `2>`: Redirect stderr to a file
- `&>`: Redirect both stdout and stderr to a file

## Examples of Redirection

### Redirecting Output

    
    # Overwrite
    echo "Hello, World!" > output.txt
    
    # Append
    echo "Another line" >> output.txt
    
    

Redirecting Input

    sort < unsorted_list.txt

Redirecting Error

    ls non_existent_directory 2> error.log

Redirecting Both Output and Error

    command &> output_and_error.log

- Piping
    - The pipe operator | allows you to send the output of one command as input to another.


    ls -l | grep ".txt"

### Here Documents
A here document allows you to pass multiple lines of input to a command.


    cat << EOF > myfile.txt
    This is line 1
    This is line 2
    EOF


### Practical Examples

- Combining stdout and stderr:


    (ls /existing_dir; ls /non_existent_dir) &> output.log

- Discarding output:


    command > /dev/null 2>&1

- Using tee to write to a file and stdout:


    echo "Hello, World!" | tee output.txt


## Exercises

1. Write a script that takes user input and appends it to a file. If the file doesn't exist, create it.

2. Create a script that reads a list of numbers from a file, sorts them, and writes the sorted list to a new file.

3. Write a script that executes a command, redirects its output to a file, and also displays the output on the screen.

4. Create a script that uses a here document to generate a simple HTML file.

5. Write a script that redirects errors to a log file, but still displays normal output on the screen.

## Additional Resources

- [Bash Redirections](https://www.gnu.org/software/bash/manual/html_node/Redirections.html)
- [I/O Redirection in the Shell](https://www.tldp.org/LDP/abs/html/io-redirection.html)
- [Advanced Bash-Scripting Guide: I/O Redirection](https://tldp.org/LDP/abs/html/io-redirection.html)