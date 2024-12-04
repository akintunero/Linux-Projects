# Day 12: Shell Scripting Basics

## Objectives
- Understand the basics of shell scripting in Linux.
- Learn how to create and run simple shell scripts to automate tasks.

## Introduction to Shell Scripting

Shell scripting is a powerful way to automate repetitive tasks, manage system operations, and streamline workflows in Linux. A shell script is a text file containing a sequence of commands that are executed by the shell.

### Creating a Shell Script

1. **Create a New Script File**: Use a text editor like `nano` or `vim` to create a new file with a `.sh` extension. For example, use `nano myscript.sh` to create a script file.

2. **Add the Shebang**: The first line of the script should be the shebang (`#!`) followed by the path to the shell interpreter. For bash, it is `#!/bin/bash`.

3. **Write Commands**: Add commands to the script file. For example:
    - Start with `#!/bin/bash`.
    - Add `echo "Hello, World!"` to print a message.
   ````
      #!/bin/bash
      echo "Hello, World!"
   ````

4. **Save and Exit**: Save your changes and exit the text editor.

### Running a Shell Script

1. **Make the Script Executable**: Use `chmod +x myscript.sh` to make your script executable.

````
chmod +x myscript.sh
````

2. **Execute the Script**: Run your script by specifying its path using `./myscript.sh`.

````
./myscript.sh

````


### Basic Script Components

- **Variables**: Store data that can be used and manipulated within your script. For example, define a variable with `name="Akin"` and use it with `echo "Hello, $name"`.

````name="Akin"
echo "Hello, $name"
````


- **Comments**: Use `#` to add comments and document your script. For example, add `# This is a comment` before commands.

````
# This is a comment
echo "This will be executed"
````


- **Conditional Statements**: Make decisions based on conditions using `if` statements. For example:
    - Use `if [ "$name" == "Akin" ]; then`
    - Follow with `echo "Welcome, Akin!"`
    - End with `fi`.
    
````
if [ "$name" == "Akin" ]; then
    echo "Welcome, Akin!"
fi
````

- **Loops**: Repeat actions using loops such as `for`, `while`, or `until`. For example:
    - Use `for i in {1..5}; do`
    - Follow with `echo "Iteration $i"`
    - End with `done`.

````
for i in {1..5}; do
    echo "Iteration $i"
done
````

## Task

1. Create a new shell script named `greet.sh` that asks for the user's name and greets them.

2. Add logic to check if the user provides their name; if not, prompt them again.

3. Make your script executable and run it.

4. Document any challenges you encounter and how you overcame them.

## Additional Resources

- [Bash Scripting Tutorial for Beginners](https://ryanstutorials.net/bash-scripting-tutorial/)
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)
- [Shell Scripting Basics](https://www.geeksforgeeks.org/introduction-to-shell-scripting/)
- [30 Days of Bash](https://github.com/akintunero/Linux-Projects/tree/main/30_days_of_bash/)

