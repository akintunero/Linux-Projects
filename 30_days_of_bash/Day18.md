# Day 18: Environment Variables

## Introduction

Environment variables are dynamic values that affect the processes or programs on a computer. In Bash scripting, they allow scripts to access specific configurations or settings that can change the behavior of the shell or its programs.

## Purpose of Environment Variables

1. **Configuration**: They define the environment in which processes run, allowing for personalized settings.
2. **Sharing information**: Programs can access environment variables to get information from the shell.
3. **Control**: They can dictate how scripts and applications behave at runtime.

## Accessing Environment Variables

To access an environment variable, use the `$` symbol followed by the variable name:


    echo $HOME
    echo $PATH

### Setting Environment Variables

You can set environment variables in several ways:

- For the current session:

    
    export MY_VARIABLE="Hello, World!"

- In your .bashrc or .bash_profile:


    echo 'export MY_VARIABLE="Hello, World!"' >> ~/.bashrc

- Temporarily for a single command:


    MY_VARIABLE="Hello, World!" ./my_script.sh

Common Environment Variables

    PATH: Directories where executable programs are located
    HOME: Path to the user's home directory
    USER: Current logged in user
    SHELL: Path to the current shell
    PWD: Current working directory

### Listing All Environment Variables

Use the env or printenv command:


    env
    printenv

- Unsetting Environment Variables
    - To remove an environment variable:


    unset MY_VARIABLE

- Using Environment Variables in Scripts

Example script:


    #!/bin/bash
    
    echo "Hello, $USER!"
    echo "Your home directory is: $HOME"
    echo "Your current directory is: $PWD"


## Exercises

1. Write a script that prints the value of `PATH`, one directory per line.

2. Create a script that sets a custom environment variable and then uses it in a meaningful way (e.g., to determine the output directory for log files).

3. Modify an existing script to use an environment variable for configuration instead of a hardcoded value.

4. Write a script that checks if a specific environment variable exists, and if not, sets a default value.

5. Create a script that lists all environment variables, sorts them alphabetically, and saves the output to a file.

## Additional Resources

- [Bash Environment Variables](https://tldp.org/LDP/Bash-Beginners-Guide/html/sect_03_02.html)
- [GNU Bash Manual: Environment](https://www.gnu.org/software/bash/manual/html_node/Environment.html)
- [Linux Environment Variables](https://www.geeksforgeeks.org/environment-variables-in-linux-unix/)
