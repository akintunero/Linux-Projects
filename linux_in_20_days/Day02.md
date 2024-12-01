# Day 2: Basic Commands

## Objectives
- Learn fundamental Linux commands.
- Practice using these commands to navigate and manipulate the file system.

## Basic Linux Commands

Linux commands are powerful tools for interacting with the operating system. Here are some essential commands you should become familiar with:

### Navigating the File System

- **`ls`**: Lists directory contents.
    - Usage: `ls [options] [directory]`
    - Example: `ls -l /home` lists detailed contents of the `/home` directory.

- **`cd`**: Changes the current directory.
    - Usage: `cd [directory]`
    - Example: `cd /var/log` moves to the `/var/log` directory.

- **`pwd`**: Prints the working directory, showing the current directory path.
    - Usage: `pwd`
    - Example: Running `pwd` might output `/home/user`.

### Creating and Managing Files and Directories

- **`mkdir`**: Creates a new directory.
    - Usage: `mkdir [directory_name]`
    - Example: `mkdir my_folder` creates a new directory named `my_folder`.

- **`rmdir`**: Removes an empty directory.
    - Usage: `rmdir [directory_name]`
    - Example: `rmdir old_folder` removes the empty directory named `old_folder`.

- **`touch`**: Creates an empty file or updates the timestamp of an existing file.
    - Usage: `touch [file_name]`
    - Example: `touch newfile.txt` creates a new file named `newfile.txt`.

- **`cp`**: Copies files or directories.
    - Usage: `cp [source] [destination]`
    - Example: `cp file1.txt /backup/` copies `file1.txt` to the `/backup/` directory.

- **`mv`**: Moves or renames files or directories.
    - Usage: `mv [source] [destination]`
    - Example: `mv oldname.txt newname.txt` renames a file from `oldname.txt` to `newname.txt`.

- **`rm`**: Removes files or directories.
    - Usage: `rm [options] [file_or_directory]`
    - Example: `rm file1.txt` deletes the file named `file1.txt`.
    - Note: Use with caution, as this command permanently deletes files.

## Task

1. Open your terminal.
2. Practice using each of these commands:
    - List the contents of your home directory with `ls`.
    - Create a new directory called "test_dir" using `mkdir`.
    - Change into "test_dir" using `cd`.
    - Create a new file named "example.txt" inside "test_dir" using `touch`.
    - Copy "example.txt" to your home directory using `cp`.
    - Rename "example.txt" to "sample.txt" using `mv`.
    - Remove "sample.txt" from your home directory using `rm`.
    - Navigate back to your home directory and remove "test_dir" using `rmdir`.

3. Document any challenges you encounter and how you overcame them.

## Additional Resources
- [Linux Command Line Basics](https://ubuntu.com/tutorials/command-line-for-beginners#1-overview)
- [The Linux Command Handbook](https://www.freecodecamp.org/news/the-linux-command-handbook/)

