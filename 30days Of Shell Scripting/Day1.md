# Day 1: Introduction to Shell Scripting

## What is a Shell?

A shell is a command-line interpreter that provides a user interface for accessing the services of the operating system. It allows users to execute commands, run scripts, and manage the system's resources. Shells are an integral part of Unix-like operating systems, including Linux and macOS.

## Different Types of Shells:

There are several types of shells, each with its unique features and capabilities. The most commonly used shells include:

- **Bash (Bourne Again Shell):** The default shell on most Linux distributions and macOS. It is an enhanced version of the original Bourne Shell (sh) with additional features.
- **Zsh (Z Shell):** Known for its powerful scripting capabilities and customization options. It is similar to Bash but with additional features like better auto-completion and spelling correction.
- **Ksh (Korn Shell):** A shell that incorporates features from the Bourne Shell and the C Shell. It is known for its scripting capabilities and efficiency.
- **Fish (Friendly Interactive Shell):** Designed to be user-friendly with a focus on interactive use. It provides features like syntax highlighting and autosuggestions.

## Basic Shell Commands:

Shells provide a set of built-in commands that allow users to perform various tasks. Some of the basic commands include:

- `ls`: Lists the files and directories in the current directory.
- `pwd`: Prints the current working directory.
- `cd`: Changes the current directory.
- `mkdir`: Creates a new directory.
- `rmdir`: Removes an empty directory.

## Exercises:

### Open Terminal and Execute Basic Commands

#### Open Terminal:

- **On Linux:** Press `Ctrl + Alt + T` or search for "Terminal" in the applications menu.
- **On macOS:** Press `Cmd + Space` to open Spotlight, type "Terminal," and press Enter.
- **On Windows (using Git Bash or Windows Subsystem for Linux):** Open the Start menu and search for "Git Bash" or "WSL."

#### Execute Basic Commands:

- **List Files and Directories (`ls`):**
    ```
    ls
    ```
    This command will list all the files and directories in the current directory.

- **Print Current Working Directory (`pwd`):**
    ```
    pwd
    ```
    This command will print the full path of the current directory.

- **Change Directory (`cd`):**
    ```
    cd /path/to/directory
    ```
    Replace `/path/to/directory` with the actual path of the directory you want to navigate to. For example:
    ```
    cd /home/user/Documents
    ```

- **Create a New Directory (`mkdir`):**
    ```
    mkdir my_new_directory
    ```
    This command will create a new directory named `my_new_directory` in the current directory.

- **Remove an Empty Directory (`rmdir`):**
    ```
    rmdir my_new_directory
    ```
    This command will remove the directory named `my_new_directory` if it is empty.

#### Example:

Create a new directory, navigate into it, create another directory inside, list the contents, navigate back, and remove the directories:

```
mkdir example_dir
cd example_dir
mkdir inner_dir
ls
cd ..
rmdir example_dir/inner_dir
rmdir example_dir


