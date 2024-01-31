# Day 14: Introduction to Debugging Bash Scripts

## Introduction

Debugging is an essential skill for any programmer, and Bash scripting is no exception. This lesson covers various techniques and tools for debugging Bash scripts, helping you identify and fix issues more efficiently.

## Basic Debugging Techniques

### 1. Echo Statements

One of the simplest debugging techniques is to use `echo` statements to print variable values or indicate which parts of the script are being executed:


    echo "Debug: Variable value is $variable"
    echo "Debug: Entering function foo()"

2. Set -x Option
The set -x command enables a mode of the shell where all executed commands are printed to the terminal:


    #!/bin/bash
    set -x
    # Your script here

You can also enable it for a specific part of your script:


    set -x
    # Debugging starts here
    # ...
    set +x
    # Debugging ends here

3. Set -e Option
The set -e command causes the script to exit immediately if any command exits with a non-zero status:


    #!/bin/bash
    set -e
    # Your script here

Advanced Debugging Techniques
1. Using the 'trap' Command
The trap command allows you to catch signals and execute code when they occur:

    
    trap 'echo "Error on line $LINENO"' ERR

2. Bash Debug Mode
Run your script with bash's debug mode:

    
    bash -x your_script.sh

3. Using 'set -v'
The set -v command prints shell input lines as they are read:

    
    #!/bin/bash
    set -v
    # Your script here

4. Redirecting Debug Output
You can redirect debug output to a file:


    bash -x your_script.sh 2> debug.log

Debugging Tools
1. ShellCheck
ShellCheck is a static analysis tool for shell scripts. It gives warnings and suggestions for bash/sh shell scripts. Install ShellCheck:


    sudo apt-get install shellcheck  # On Ubuntu/Debian

Use ShellCheck:


    shellcheck your_script.sh

2. Bash Debug
- Bash Debug is an extension for Visual Studio Code that provides debugging and breakpoint support for Bash scripts.
    - Best Practices for Debugging


1. Use meaningful variable names and comments
2. Break your script into smaller functions
3. Test your script with different inputs
4. Use version control to track changes
5. Keep your scripts modular and reusable

## Exercises

1. Write a script with intentional errors, then use `set -x` to identify and fix the issues.

2. Create a script that uses `trap` to catch and display error messages, including the line number where the error occurred.

3. Write a script that includes debug echo statements, but only prints them when a DEBUG flag is set.

4. Use ShellCheck to analyze one of your existing scripts and fix any warnings it reports.

5. Write a script that demonstrates the difference between `set -e` and not using it. Include some commands that might fail.

## Additional Resources

- [Bash Manual: Debugging](https://www.gnu.org/software/bash/manual/html_node/Bash-POSIX-Mode.html#Bash-POSIX-Mode)
- [Advanced Bash-Scripting Guide: Debugging](https://tldp.org/LDP/abs/html/debugging.html)
- [ShellCheck User Guide](https://github.com/koalaman/shellcheck#user-content-gallery-of-bad-code)
