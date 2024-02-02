# Day 15: Error Handling in Scripts

## Introduction

Proper error handling is crucial for creating robust and reliable Bash scripts. It helps in identifying issues, preventing unexpected behavior, and providing meaningful feedback to users. This lesson covers various techniques for implementing error handling in your Bash scripts.

## Basic Error Handling Techniques

### 1. Exit on Error

Use `set -e` to make your script exit immediately when a command fails:


    #!/bin/bash
    set -e

# Script continues only if all commands succeed

2. Checking Return Values
Always check the return value of commands:


    if ! command_that_might_fail; then
        echo "Error: Command failed"
        exit 1
    fi

3. Using || (OR) Operator
Execute a command if the previous one fails:


    command_that_might_fail || echo "Error: Command failed"

Advanced Error Handling
1. Custom Error Function
Create a function to handle errors consistently:


        error_exit() {
            echo "Error: $1" >&2
            exit 1
        }
    
    # Usage
    some_command || error_exit "Failed to execute some_command"

2. Trap Command
Use trap to catch signals and execute code when they occur:


    trap 'echo "Error: Script failed on line $LINENO"' ERR

3. Handling Specific Error Codes
Check for specific error codes:

    
    if ! some_command; then
        case $? in
            1) echo "Error: Type 1" ;;
            2) echo "Error: Type 2" ;;
            *) echo "Unknown error" ;;
        esac
    fi

Debugging Options
1. Set -x (Print Commands)
Print each command before executing:

    
    set -x

2. Set -v (Print Input)
Print input lines as they are read:

    
    set -v

3. Combining Options
You can combine multiple options:

    
    set -evx

### Best Practices for Error Handling

1. Always check for errors after critical operations
2. Provide meaningful error messages
3. Clean up temporary files or resources in case of errors
4. Use appropriate exit codes
5. Log errors for later analysis

### Practical Example
Here's a script that demonstrates various error handling techniques:


    #!/bin/bash
    
    set -e
    
    error_exit() {
        echo "Error: $1" >&2
        exit 1
    }
    
    cleanup() {
        echo "Cleaning up..."
        # Add cleanup code here
    }
    
    trap cleanup EXIT
    trap 'error_exit "Script failed on line $LINENO"' ERR
    
    # Example usage
    file="/path/to/file"
    
    if [ ! -f "$file" ]; then
        error_exit "File $file does not exist"
    fi
    
    content=$(cat "$file") || error_exit "Failed to read $file"
    
    echo "File content: $content"
    
    echo "Script completed successfully"

## Exercises

1. Write a script that attempts to create a directory and handle potential errors (e.g., directory already exists, no permissions).

2. Create a script that reads a file and handles various error scenarios (file doesn't exist, no read permissions, file is empty).

3. Modify an existing script to include proper error handling and meaningful error messages.

4. Write a script that uses `trap` to perform cleanup operations (e.g., deleting temporary files) even if the script exits due to an error.

5. Create a script that demonstrates the use of custom error codes and how to handle them in the calling environment.

## Additional Resources

- [Bash Manual: Bourne Shell Builtins](https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html)
- [Advanced Bash-Scripting Guide: Error Handling](https://tldp.org/LDP/abs/html/debugging.html)
- [Bash Pitfalls](http://mywiki.wooledge.org/BashPitfalls)