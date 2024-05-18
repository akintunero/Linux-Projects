#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

username=$1

passwd -l $username

echo "Account for user $username has been locked"
