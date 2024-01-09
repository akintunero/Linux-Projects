# Day 01: Introduction to Bash and Setting Up the Environment

## What is Bash?

Bash (Bourne Again Shell) is a command-line interface and scripting language for Unix-like operating systems. It's an enhanced version of the original Bourne Shell (sh) and is the default shell for most Linux distributions and macOS.

Key points about Bash:
- It's a powerful tool for automating tasks and system administration.
- Bash allows users to interact with the operating system through commands.
- It supports scripting, enabling the creation of complex programs and workflows.

## Importance of Bash in Scripting

1. Automation: Bash scripts can automate repetitive tasks, saving time and reducing errors.
2. System Administration: It's widely used for managing and configuring Unix-like systems.
3. Portability: Bash scripts can run on various Unix-like systems with little to no modification.
4. Integration: Bash can easily integrate with other command-line tools and utilities.

## Setting Up the Bash Environment

1. Check your Bash version:



2. Create a directory for your Bash scripts:

mkdir ~/bash_scripts
cd ~/bash_scripts


3. Create your first Bash script:

touch hello_world.sh
chmod +x hello_world.sh

text

4. Open the script in a text editor and add:

    
    #!/bin/bash
    echo "Hello, World!"

    Run your script:

    text
    ./hello_world.sh

## Basic Bash Commands

- `echo`: Print text to the console
- `ls`: List directory contents
- `cd`: Change directory
- `mkdir`: Create a new directory
- `touch`: Create an empty file
- `chmod`: Change file permissions

## Exercise

Create a Bash script that:

1. Creates a new directory called "my_project"
2. Changes into that directory
3. Creates three empty files named "file1.txt", "file2.txt", and "file3.txt"
4. Lists the contents of the directory
5. Prints a message saying "Project setup complete!"

- Sit back while we go from basic to advanced while getting fully hands-on