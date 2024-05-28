#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <username> <expiry_date>"
    echo "Expiry date format: YYYY-MM-DD"
    exit 1
fi

username=$1
expiry_date=$2

usermod -e $expiry_date $username

echo "Expiration date for user $username set to $expiry_date"