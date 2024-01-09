# Hello World using "Echo"
## Introduction

### In this guide, we'll walk you through the basics of shell scripting, focusing on the essential concepts of printing "Hello, World!" and using the echo command. Whether you're a beginner exploring the world of programming or someone looking to enhance their scripting skills, you're in the right place.

### Prerequisites
Before we dive into the tutorial, make sure you have:

A Unix or Unix-like system (e.g., Linux)
A text editor of your choice (e.g., Vim, Nano, or VSCode)
Basic knowledge of navigating the command line


### Writing Your First Script
Step 1: Open a Text Editor
Open your preferred text editor. For example, you can use Vim by typing:

    vim hello_world.sh
    
Step 2: Write the Script
In the text editor, enter the following simple script:

    #!/bin/bash
    # This is a basic script to print "Hello, World!"
    echo "Hello, World!"

    
The #!/bin/bash line is known as a shebang, indicating that the script should be interpreted using the Bash shell.
The # symbol denotes a comment, providing information about the script.

Step 3: Save and Exit
Save the file and exit the text editor. If you're using Vim, press Esc followed by :wq and hit Enter.

Step 4: Make the Script Executable
Make the script executable by running:

    chmod +x hello_world.sh

Step 5: Run the Script
Execute the script using:

    ./hello_world.sh
    
You should see the output:

### Hello, World!

Congratulations! You've just created and run your first shell script.

## Understanding the Script
Now, let's break down the script:

#!/bin/bash: Specifies the Bash shell for interpreting the script.

echo "Hello, World!": Prints the text "Hello, World!" to the terminal.

Using the echo Command

The echo command is fundamental in shell scripting for displaying messages on the screen. You can use it to output text and variables. Let's explore some examples:

Example 1: Printing a Variable

    #!/bin/bash
    # Using echo to print a variable
    name="Olúmáyòwá"
    echo "Hello, $name!"
    
This script declares a variable name with the value "Olúmáyòwá" and prints a personalized greeting.

Example 2: Concatenating Strings

    #!/bin/bash
    # Concatenating strings with echo
    greeting="Hello"
    subject="World"
    echo "$greeting, $subject!"
    
 Here, the script concatenates the strings "Hello" and "World" with a comma in between.

 You have just completed your first shell scripting project and the codes are available for you within the repository to copy and try out.
