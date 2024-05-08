#!/bin/bash

# Check if a username is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

username=$1

# Delete the user and their home directory
userdel -r $username

echo "User $username deleted successfully along with their home directory"