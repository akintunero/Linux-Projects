#!/bin/bash

echo "List of all users on the system:"
cut -d: -f1 /etc/passwd | sort