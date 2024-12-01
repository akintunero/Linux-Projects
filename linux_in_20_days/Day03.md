# Day 3: Navigating the File System

## Objectives
- Understand the structure of the Linux file system.
- Learn how to navigate directories effectively using basic commands.

## Linux File System Structure

The Linux file system is organized in a hierarchical directory structure. At the top is the root directory, represented by `/`, which contains all other directories and files.

### Key Directories

- **`/`**: The root directory, which contains all other directories.
- **`/home`**: Contains personal directories for users, such as `/home/user`.
- **`/bin`**: Contains essential binary executables (e.g., common commands like `ls`, `cp`).
- **`/etc`**: Contains configuration files for the system.
- **`/var`**: Contains variable data like logs and databases.
- **`/usr`**: Contains user-installed software and libraries.
- **`/tmp`**: A temporary file storage location that is cleared upon reboot.

## Navigating Directories

### Commands for Navigation

- **`cd [directory]`**: Change to a specified directory.
    - Example: `cd /etc` changes the current directory to `/etc`.

- **`ls [options] [directory]`**: List contents of a directory.
    - Example: `ls -a /home/user` lists all files, including hidden ones, in `/home/user`.

- **`pwd`**: Print the working directory to display the current directory path.
    - Example: Running `pwd` might output `/home/user/documents`.

- **`tree [directory]`**: Display directories and subdirectories in a tree-like format (may need to install with `sudo apt-get install tree`).
    - Example: `tree /var/logs` shows the directory structure under `/var/logs`.

## Task

1. Open your terminal and explore your file system:
    - Use `pwd` to confirm your current directory.
    - Navigate to different directories using `cd`, such as `/etc`, `/var`, and `/home`.
    - List contents of these directories with `ls`.
    - Use `ls -l` to view detailed information about files (permissions, owner, size).
    - Try using `tree` to visualize the structure of a directory.

2. Explore hidden files:
    - Use `ls -a ~` to list all files, including hidden ones, in your home directory.

3. Document any challenges you encounter and how you overcame them.

## Additional Resources
- [Linux Directory Structure Explained](https://www.geeksforgeeks.org/linux-directory-structure-and-important-files-paths/)
- [Navigating Directories in Linux](https://www.linux.com/training-tutorials/navigating-directories-linux/)

