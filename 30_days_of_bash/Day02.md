# Day 2: Basic Commands and Navigation in the Terminal

## Introduction

Navigating the terminal efficiently is a crucial skill for Bash scripting. Today, we'll explore essential commands for moving around the filesystem and manipulating files and directories.

### Basic Navigation Commands

 1. pwd (Print Working Directory)
Displays your current location in the filesystem.

    pwd

2. ls (List)
Lists contents of the current directory.

    ls
    ls -l  # Detailed list
    ls -a  # Show hidden files

3. cd (Change Directory)
Moves you to a different directory.

    cd /path/to/directory
    cd ..  # Move up one directory
    cd ~   # Go to home directory
    cd -   # Go to previous directory

File and Directory Manipulation
4. mkdir (Make Directory)
Creates a new directory.

    mkdir new_directory

5. touch
Creates an empty file or updates the timestamp of an existing file.

    touch newfile.txt

6. cp (Copy)
Copies files or directories.

    cp file.txt /path/to/destination
    cp -r directory /path/to/destination  # Copy directory and its contents

7. mv (Move)
Moves or renames files and directories.

    mv file.txt newname.txt  # Rename
    mv file.txt /path/to/destination  # Move

8. rm (Remove)
Deletes files or directories.

    rm file.txt
    rm -r directory  # Remove directory and its contents

Viewing File Contents

9. cat
Displays the contents of a file.

    cat file.txt

10. less
Allows scrolling through large files.

    less largefile.txt

### Finding Things

11. find
Searches for files and directories.

    find /path/to/search -name "filename"

12. grep
Searches for patterns in files.

    grep "pattern" file.txt

# Exercises

## Create a directory structure:
1. Create a directory called "project" in your home directory.
2. Inside "project", create three subdirectories: "docs", "src", and "tests".
3. In each subdirectory, create an empty file called "README.md".

## Navigation practice:
1. Starting from your home directory, navigate to the "src" directory you just created using a single command.
2. List the contents of the "src" directory.
3. Move back to the "project" directory.
4. List all subdirectories of "project" in long format.

## File manipulation:
1. Create a file called "todo.txt" in the "project" directory.
2. Add the line "Complete Bash scripting course" to "todo.txt" using the `echo` command and output redirection.
3. Make a copy of "todo.txt" in the "docs" directory.
4. Rename the copy to "tasks.txt".

## Search and display:
1. Use the `find` command to locate all "README.md" files in the "project" directory and its subdirectories.
2. Use `grep` to search for the word "Complete" in all text files within the "project" directory.

## Cleanup:
1. Remove the "tests" directory and all its contents.
2. Move the "tasks.txt" file from "docs" to "src".
Bonus Challenge: Write a Bash script that automates the creation of the directory structure from Exercise 1.


## Additional Resources

- [Learn the Command Line - Codecademy](https://www.codecademy.com/learn/learn-the-command-line)
- [Command Line for Beginners - Ubuntu](https://ubuntu.com/tutorials/command-line-for-beginners)
- [Bash Cheat Sheet - Devhints](https://devhints.io/bash)
