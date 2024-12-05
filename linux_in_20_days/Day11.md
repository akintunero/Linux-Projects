# Day 11: User and Group Management

## Objectives
- Understand how to manage users and groups in Linux.
- Learn how to use commands to create, modify, and delete users and groups using `adduser`.

## Introduction to User and Group Management

User and group management is a fundamental aspect of Linux system administration. It involves creating and managing user accounts and groups to control access to system resources.

### Managing Users

#### Creating a New User

- **Using `adduser`**: Use `sudo adduser username` to create a new user account. This command will prompt you for additional information such as password, full name, and other details interactively.

#### Modifying User Accounts

- **Add User to Group**: Use `sudo usermod -aG groupname username` to add an existing user to a group.

#### Deleting a User

- **Using `deluser`**: Use `sudo deluser username` to delete a user account.
- **Delete User and Home Directory**: Use `sudo deluser --remove-home username` to delete a user along with their home directory.

### Managing Groups

#### Creating a New Group

- **Using `addgroup`**: Use `sudo addgroup groupname` to create a new group.

#### Modifying Group Membership

- **Add User to Group**: Use `sudo usermod -aG groupname username` to add a user to a group.

#### Deleting a Group

- **Using `delgroup`**: Use `sudo delgroup groupname` to delete a group.

### Task

1. Open your terminal and practice using these commands:

    - Create a new user named "testuser":
        - Use `sudo adduser testuser`
        - Follow the prompts to set up the user's password and additional information.

    - Create a new group named "testgroup":
        - Use `sudo addgroup testgroup`

    - Add "testuser" to "testgroup":
        - Use `sudo usermod -aG testgroup testuser`

    - Verify that "testuser" is in "testgroup":
        - Use `groups testuser`

    - Delete "testuser" along with their home directory:
        - Use `sudo deluser --remove-home testuser`

2. Document any challenges you encounter and how you overcame them.

## Additional Resources

- [Managing Users in Linux](https://www.tecmint.com/add-users-in-linux/)
- [Understanding Linux Groups](https://www.howtogeek.com/50787/add-a-user-to-a-group-or-second-group-on-linux/)
- [Linux User Management Commands](https://www.geeksforgeeks.org/user-management-in-linux/)
