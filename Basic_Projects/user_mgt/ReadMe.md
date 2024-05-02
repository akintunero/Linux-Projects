# Linux User Management Scripts

This repository contains a collection of shell scripts for managing users and groups on a Linux system. These scripts automate common user administration tasks, making system management more efficient and less error-prone.

## Scripts Overview

### User Management
1. `create_user.sh`: Creates a new user with a home directory and sets their password.
2. `modify_user_home.sh`: Changes a user's home directory.
3. `delete_user.sh`: Removes a user and their home directory from the system.
4. `list_users.sh`: Displays a list of all users on the system.
5. `change_user_password.sh`: Changes the password for a specified user.
6. `lock_user_account.sh`: Locks a user account, preventing login.
7. `unlock_user_account.sh`: Unlocks a previously locked user account.
8. `set_user_expiry.sh`: Sets an expiration date for a user account.

### Group Management
1. `add_user_to_group.sh`: Adds a user to a specified group.
2. `create_group.sh`: Creates a new group on the system.
3. `delete_group.sh`: Removes a group from the system.
4. `list_user_groups.sh`: Shows all groups a specific user belongs to.

## Usage

To use these scripts:

1. Clone this repository to your local machine.
2. Navigate to the script directory.
3. Make the scripts executable:


    chmod +x *.sh


4. Run a script with appropriate arguments. For example:


    sudo ./create_user.sh newusername user_password



## Important Notes

- Most of these scripts require root or sudo privileges to execute successfully.
- Always use these scripts with caution, as they can make significant changes to your system.
- It's recommended to test these scripts in a safe environment before using them on a production system.
- Ensure you have backups of important data before performing user management operations.

