# Day 4: File and Directory Permissions

## Objectives
- Understand how file and directory permissions work in Linux.
- Learn how to change permissions, ownership, and group associations.

## Understanding File Permissions

In Linux, each file and directory has associated permissions that determine who can read, write, or execute them. These permissions are divided into three categories:

1. **Owner**: The user who owns the file.
2. **Group**: A set of users who share access rights to the file.
3. **Others**: All other users.

### Permission Types

- **Read (r)**: Allows viewing the contents of a file or listing a directory's contents.
- **Write (w)**: Allows modifying the contents of a file or adding/removing files in a directory.
- **Execute (x)**: Allows executing a file (if it's a script or program) or accessing a directory.

### Viewing Permissions

Use the `ls -l` command to view permissions of files and directories. The output will look something like this:

-rwxr-xr-- 1 user group 1234 Jan 01 12:34 example.txt

text

- The first character indicates the type (`-` for files, `d` for directories).
- The next nine characters represent permissions for owner, group, and others (e.g., `rwxr-xr--`).

## Changing Permissions

### Using `chmod`

The `chmod` command changes the permissions of files and directories.

- **Symbolic Mode**: Use symbols to change permissions.
    - Example: `chmod u+x filename` adds execute permission for the owner.

- **Numeric Mode**: Use numbers to set permissions.
    - Example: `chmod 754 filename` sets permissions to `rwxr-xr--`.

### Changing Ownership

### Using `chown`

The `chown` command changes the ownership of files and directories.

- Usage: `chown [owner][:group] filename`
    - Example: `chown user:group filename` changes the owner to "user" and group to "group".

### Changing Group Ownership

### Using `chgrp`

The `chgrp` command changes the group of files and directories.

- Usage: `chgrp [group] filename`
    - Example: `chgrp groupname filename` changes the group to "groupname".

## Task

1. Open your terminal and experiment with changing permissions:
    - Create a new file using `touch myfile.txt`.
    - View its current permissions with `ls -l myfile.txt`.
    - Change its permissions to make it executable by the owner using `chmod u+x myfile.txt`.
    - Verify the change with `ls -l myfile.txt`.

2. Experiment with changing ownership:
    - Change the owner of "myfile.txt" (you may need superuser privileges) using `sudo chown newowner myfile.txt`.
    - Change the group using `sudo chgrp newgroup myfile.txt`.

3. Document any challenges you encounter and how you overcame them.

## Additional Resources
- [Understanding Linux File Permissions](https://www.linux.com/training-tutorials/understanding-linux-file-permissions/)
- [Linux File Permission Tutorial](https://www.guru99.com/file-permissions.html)

