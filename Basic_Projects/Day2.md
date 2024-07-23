# Day 2: Making Your First Script and Running It

## Introduction

One of the powerful ways to perform tasks that are repetitive in nature, automate system operation, and streamline workflows is shell scripting. On Day 2 of this journey, we will focus on the basics of creating and running your first shell script. This will lay a strong foundation for more complex scripting tasks in the future.

## Topics

### Creating a Shell Script File

A shell script is a text file that contains a sequence of commands for a UNIX-based operating system. These commands are executed by the shell when you run the script.

**Steps to Create a Shell Script File:**

1. **Open a Text Editor:**
   You can use any text editor you are comfortable with, such as `nano`, `vim`, or even a GUI-based editor like `gedit`.

2. **Write Your Script:**
   At the beginning of your script, add a shebang (`#!`) with the path to your shell. For example, if you wanted to use  you would write:

   ```
   #! /bin/

This tells the system that we wish for the script to be executed using the  shell.

Add Commands:
Following the shebang line, commands can be placed in the file which you want the script to execute. For our first script, let's write:


    #! /bin/
    echo "Hello, World!"

Save the File:
Save the file using a .sh extension; it is common practice to give shell scripts this extension. For instance, you could use hello_world.sh as the filename.

### Making a Script Executable

Before you can run your script, you need to give the file permission to be executed.

Procedure to Create a Script Executable:

Open Your Terminal:
Open up your terminal application.

Change File Directory:
Execute the cd command to go to the location where you saved your script. For example:

    
    cd /path/to/your/script

Change File Permission:
Execute the chmod command to make the file executable. For example:


    chmod +x hello_world.sh

The command changes the file permissions to make the script executable.

Run a Script

Once your script is executable, you can run it from the terminal.

How to Run a Script:

In the Terminal:
Make sure you are in the right directory where your script is.

Run the Script:
Use the ./ notation followed by the script name. For example:

    
    ./hello_world.sh

In that command, we are stating that located in this current directory, we would like the shell to run the script.

## Exercises

Write and Run a "Hello, World!" Script

Open a Text Editor:
Open the text editor you are most comfortable using; start a new file in your favorite editor.

Write the Script:
Enter the following lines into your script:

    #! /bin/
    echo "Hello, World!"

Save the File:
Save it with the filename hello_world.sh.

Make the Script Executable:
Open a terminal and navigate to the directory where you saved your script:



    cd /path/to/your/script

Make the script executable:

    chmod +x hello_world.sh

Run the Script:
Execute the script by running:

    ./hello_world.sh

Example:

Let's go through the entire process step by step.

 Open a text editor and create a new file.

  Open a terminal. In the terminal window, type:

    echo 'Hello World'

Type CTRL-x, y to save the file and exit.

Make the script executable with the command:

    chmod +x hello_world.sh

Run the script:

    ./hello_world.sh
