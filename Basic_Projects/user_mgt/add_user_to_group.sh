#!/bin/bash

# Check if both username and group name are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <username> <groupname>"
    exit 1
fi

username=$1
groupname=$2

# Add the user to the group
usermod -a -G $groupname $username

echo "User $username added to group $groupname"
