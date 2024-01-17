# Day 7: Writing Your First Bash Script

## Introduction

Today, we'll put together everything we've learned so far and write a complete Bash script. This lesson will guide you through the process of creating, writing, and executing a Bash script.

## Script Structure

A basic Bash script typically follows this structure:

1. Shebang
2. Comments/Documentation
3. Global variables
4. Functions
5. Main script logic

## Step-by-Step Guide

### 1. Create the Script File

Create a new file with a `.sh` extension:


    touch my_first_script.sh

2. Add the Shebang
Open the file in a text editor and add the shebang line:


    #!/bin/bash

This line tells the system to use Bash to interpret the script.
3. Add Comments and Documentation


    #!/bin/bash

    # Script: my_first_script.sh
    # Description: This script demonstrates basic Bash scripting concepts
    # Author: Your Name
    # Date: YYYY-MM-DD

4. Define Global Variables

    
    GREETING="Hello, World!"
    MAX_COUNT=5

5. Define Functions

    
    print_greeting() {
        echo "$GREETING"
    }
    
    count_down() {
        local count=$1
        while [ $count -gt 0 ]; do
            echo $count
            count=$((count - 1))
            sleep 1
        done
        echo "Blast off!"
    }

6. Main Script Logic

    
    # Main script execution starts here
    
    echo "Starting the script..."
    
    print_greeting
    
    echo "Counting down from $MAX_COUNT"
    count_down $MAX_COUNT
    
    echo "Script execution completed."

7. Make the Script Executable
In the terminal, make your script executable:


    chmod +x my_first_script.sh

8. Run the Script
Execute your script:

        
    ./my_first_script.sh

Complete Script
Here's what your complete script should look like:

    #!/bin/bash

    # Script: my_first_script.sh
    # Description: This script demonstrates basic Bash scripting concepts
    # Author: Your Name
    # Date: YYYY-MM-DD
    
    # Global variables
    GREETING="Hello, World!"
    MAX_COUNT=5
    
    # Functions
    print_greeting() {
        echo "$GREETING"
    }
    
    count_down() {
        local count=$1
        while [ $count -gt 0 ]; do
            echo $count
            count=$((count - 1))
            sleep 1
        done
        echo "Blast off!"
    }

    # Main script execution starts here
    echo "Starting the script..."
    
    print_greeting
    
    echo "Counting down from $MAX_COUNT"
    count_down $MAX_COUNT
    
    echo "Script execution completed."

## Exercises

1. Modify the script to accept a user's name as a command-line argument and include it in the greeting.

2. Add error handling to the `count_down` function to ensure the input is a positive integer.

3. Create a new function that generates a random number between 1 and 10, and use it in the main script logic.

4. Modify the script to log its output to a file in addition to displaying it on the screen.

5. Add a menu system to your script, allowing the user to choose between different functions to execute.

## Additional Resources

- [Bash Scripting Tutorial](https://linuxconfig.org/bash-scripting-tutorial-for-beginners)
- [Shell Scripting for Beginners](https://www.guru99.com/introduction-to-shell-scripting.html)
- [Bash Guide for Beginners](https://tldp.org/LDP/Bash-Beginners-Guide/html/)

