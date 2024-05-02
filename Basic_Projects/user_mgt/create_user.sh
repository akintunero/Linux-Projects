#!/bin/bash

# Check if both username and password are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <username> <password>"
    exit 1
fi

username=$1
password=$2

# Create the user
useradd -m -s /bin/bash $username

# Set the user's password
echo "$username:$password" | chpasswd

echo "User $username created successfully with home directory /home/$username and default shell /bin/bash"