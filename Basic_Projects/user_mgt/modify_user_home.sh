#!/bin/bash

# Check if both username and new home directory are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <username> <new_home_directory>"
    exit 1
fi

username=$1
new_home=$2

# Change the user's home directory
usermod -d $new_home $username

echo "Home directory for user $username changed to $new_home"