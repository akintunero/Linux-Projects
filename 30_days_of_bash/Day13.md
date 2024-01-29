## Introduction

Understanding and managing file permissions is crucial for system security and proper file management in Unix-like systems. This lesson covers the basics of file permissions and how to manipulate them using Bash commands.

## Understanding File Permissions

In Unix-like systems, file permissions are represented by a 10-character string:

    -rwxrwxrwx


- The first character indicates the file type (`-` for regular file, `d` for directory, etc.)
- The next 9 characters are divided into 3 sets of `rwx`:
    - Owner permissions
    - Group permissions
    - Others permissions

Where:
- `r` = read permission
- `w` = write permission
- `x` = execute permission

## Viewing File Permissions

Use the `ls -l` command to view file permissions:


    ls -l filename

Changing File Permissions
Using Symbolic Mode
The chmod command is used to change file permissions:


    chmod [who][+,-,=][permissions] filename

Where:

    who can be u (user), g (group), o (others), or a (all)
    + adds permission, - removes permission, = sets exact permission
    permissions can be r, w, or x

Examples:


    chmod u+x script.sh  # Add execute permission for the owner
    chmod go-w file.txt  # Remove write permission for group and others
    chmod a=r file.txt   # Set read-only permission for all

- Using Numeric Mode
    - Permissions can also be set using numbers:


    4 = read
    2 = write
    1 = execute

Examples:


    chmod 755 script.sh  # rwxr-xr-x
    chmod 644 file.txt   # rw-r--r--

Changing Ownership
Use the chown command to change file ownership:


    chown user:group filename

Example:


    chown john:users file.txt

Special Permissions

- setuid (4000): Allows a file to be executed with the permissions of the file owner
- setgid (2000): Similar to setuid, but for group permissions
- sticky bit (1000): Prevents users from deleting files they don't own in shared directories

Example:


    chmod 4755 file  # Set setuid
    chmod 2755 file  # Set setgid
    chmod 1755 dir   # Set sticky bit

Practical Examples

- Make a script executable:


    chmod +x script.sh

Set read and write permissions for owner, and read-only for others:

    chmod 644 file.txt

Recursively change permissions of a directory:

    chmod -R 755 directory

Change ownership of a file:

    chown newuser:newgroup file.txt

## Exercises

1. Write a script that checks if a file is executable. If not, make it executable and print a message.

2. Create a script that changes the permissions of all `.txt` files in a directory to read-only for all users.

3. Write a script that takes a filename as an argument and prints out its permissions in both symbolic and numeric format.

4. Create a script that sets the setuid bit on a file if it's owned by root and is executable.

5. Write a script that changes the ownership of all files in a directory to the current user, but only if the current user has write permission on the directory.

## Additional Resources

- [Linux File Permissions Explained](https://www.linux.com/training-tutorials/understanding-linux-file-permissions/)
- [chmod Command in Linux](https://linuxize.com/post/chmod-command-in-linux/)
- [chown Command in Linux](https://linuxize.com/post/linux-chown-command/)
