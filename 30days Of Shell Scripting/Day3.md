# Day 3: Variables and User Input

## Introduction

In scripting, variables and user input are fundamental concepts that allow you to make your scripts more dynamic and interactive. On Day 3, we will learn how to define and use variables, and how to read input from users. Understanding these concepts will enable you to create more versatile and engaging scripts.

## Topics

### Defining and Using Variables

Variables are like storage containers for data. They hold values that you can use and manipulate in your script. In shell scripting, you can define a variable and assign a value to it. Here's how you can work with variables:

1. **Defining a Variable:**
   To define a variable, simply write the variable name followed by an equal sign (`=`) and the value you want to assign. For example:

   ```
   greeting="Hello, World!"

In this scenario, greeting is the variable name, and "Hello, World!" is the value assigned to it. Note that there should be no spaces around the = sign.

Using a Variable:
To use the value of a variable, you need to reference it with a dollar sign ($). For example:

    echo $greeting

 This will output the value of the greeting variable, which is Hello, World!.

Reading User Input

You can make your scripts interactive by asking users for input. This is done using the read command. Here's how you can use it:

Prompting the User:
You can prompt the user by displaying a message before reading their input. For example:

    

    echo "Enter your name:"
    read userName

In this scenario, Enter your name: is displayed to the user, and then the read command waits for the user to type something. The input is stored in the variable userName.

Using the User Input:
After reading the input, you can use it just like any other variable. For example:

    echo "Hello, $userName!"

This will greet the user with their name.

## Exercises
Create a Script that Asks for the User's Name and Greets Them

Let's put everything we've learned into practice with a simple script:

Open a Text Editor:
Open your preferred text editor to create a new script file.

Write the Script:
Enter the following lines into your script:

  
    #! /bin/bash
    
    # Prompt the user for their name
    echo "What is your name?"

# Read the user's input and store it in a variable
    read userName

# Greet the user
echo "Hello, $userName! Welcome to the world of shell scripting."

Save the File:
Save the file with a .sh extension, for In this scenario, greet_user.sh.

Make the Script Executable:
Open your terminal and navigate to the directory where you saved your script:



cd /path/to/your/script

Make the script executable:



chmod +x greet_user.sh

Run the Script:
Execute the script by running:

    ./greet_user.sh

Follow the prompts and see how the script interacts with you by asking for your name and then greeting you.

