# Day 16: Using Command-Line Arguments

## Introduction

Command-line arguments allow users to pass information to a script when it is executed. This makes scripts more flexible and reusable. Today, we'll explore how to work with command-line arguments in Bash scripts.

## Basic Command-Line Arguments

In Bash, command-line arguments are accessible through special variables:

- `$0`: The name of the script itself
- `$1`, `$2`, `$3`, etc.: The first, second, third, etc. arguments
- `$#`: The number of arguments passed to the script
- `$@`: All the arguments passed to the script

Example:


    #!/bin/bash
    
    echo "Script name: $0"
    echo "First argument: $1"
    echo "Second argument: $2"
    echo "Number of arguments: $#"
    echo "All arguments: $@"

Handling Multiple Arguments
To process all arguments, you can use a loop:


    #!/bin/bash

    for arg in "$@"
    do
        echo "Argument: $arg"
    done

- Shift Command
    - The shift command moves the arguments to the left, discarding the first argument:

    
    #!/bin/bash
    
    while [ "$1" != "" ]; do
        echo "Processing: $1"
        shift
    done

- Handling Options and Flags
    - For more complex argument handling, you can use getopts:

    
    #!/bin/bash
    
    while getopts "a:b:" opt; do
        case $opt in
            a) echo "Option -a was triggered, Parameter: $OPTARG" ;;
            b) echo "Option -b was triggered, Parameter: $OPTARG" ;;
            \?) echo "Invalid option: -$OPTARG" ;;
        esac
    done

- Default Values for Arguments
    - You can provide default values for arguments:

    
    #!/bin/bash
    
    name=${1:-"World"}
    echo "Hello, $name!"

- Checking for Required Arguments
    - To ensure required arguments are provided:

    
    #!/bin/bash
    
    if [ $# -eq 0 ]; then
        echo "No arguments provided"
        exit 1
    fi

- Practical Example: File Processor
    - Here's a script that processes files based on command-line arguments:

    
    #!/bin/bash
    
    usage() {
        echo "Usage: $0 [-r] [-t TYPE] file [file...]"
        echo "  -r: Process files recursively"
        echo "  -t TYPE: Specify file type (default: txt)"
        exit 1
    }
    
    recursive=false
    type="txt"
    
    while getopts "rt:" opt; do
        case $opt in
            r) recursive=true ;;
            t) type=$OPTARG ;;
            ?) usage ;;
        esac
    done
    
    shift $((OPTIND-1))
    
    if [ $# -eq 0 ]; then
        usage
    fi
    
    process_file() {
        echo "Processing file: $1"
        # Add file processing logic here
    }
    
    if [ "$recursive" = true ]; then
        find . -type f -name "*.$type" | while read file; do
            process_file "$file"
        done
    else
        for file in "$@"; do
            if [[ $file == *.$type ]]; then
                process_file "$file"
            else
                echo "Skipping $file: not a .$type file"
            fi
        done
    fi


## Exercises

1. Write a script that takes two numbers as command-line arguments and prints their sum, difference, product, and quotient.

2. Create a script that accepts a directory path as an argument and lists all files in that directory. If no argument is provided, it should use the current directory.

3. Modify the file processor example to add an option for specifying an output directory for processed files.

4. Write a script that can take multiple flags (-v for verbose mode, -d for debug mode) and acts accordingly.

5. Create a script that takes a variable number of arguments and sorts them alphabetically.

## Additional Resources

- [Bash Guide for Beginners: Command line arguments](https://tldp.org/LDP/Bash-Beginners-Guide/html/sect_08_02.html)
- [Advanced Bash-Scripting Guide: Command-Line Options](https://tldp.org/LDP/abs/html/options.html)
- [GNU Bash Manual: Special Parameters](https://www.gnu.org/software/bash/manual/html_node/Special-Parameters.html)