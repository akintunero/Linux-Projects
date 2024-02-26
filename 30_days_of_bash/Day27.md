# Day 27: Incorporating External Commands and Scripts

## Introduction

Incorporating external commands and scripts is a powerful feature in Bash that allows you to extend the functionality of your scripts by leveraging existing tools and custom scripts. This lesson covers various methods to integrate external resources into your Bash scripts effectively.

## Basic Command Execution

### Using Backticks

The oldest method, still widely used:

    result=`command`

    Using $()

- The modern, preferred method:


    result=$(command)

### Executing External Scripts
- Source / Dot Operator
    - To execute a script in the current shell environment:


    source script.sh
    # or
    . script.sh

- Executing as a Separate Process
    - To run a script as a separate process:


    ./script.sh
    # or
    bash script.sh

- Passing Arguments to External Scripts


    ./script.sh arg1 arg2

- Capturing Output from External Commands
    - Capturing stdout


    output=$(command)
    echo "The output is: $output"

    Capturing stderr

    
    error=$(command 2>&1)
    echo "The error is: $error"

- Using External Commands in Conditionals


    if command -v jq >/dev/null 2>&1; then
        echo "jq is installed"
    else
        echo "jq is not installed"
    fi

- Piping Between Commands


    echo "Hello, World!" | tr '[:lower:]' '[:upper:]'

Practical Examples
1. Using curl and jq to Process API Data


    #!/bin/bash
    
    api_url="https://api.github.com/repos/bash/bash"
    repo_info=$(curl -s "$api_url")
    stars=$(echo "$repo_info" | jq '.stargazers_count')
    
    echo "The Bash repository has $stars stars."

2. Incorporating a Python Script


    #!/bin/bash

    # Assuming we have a Python script named 'process_data.py'
    data="Some data"
    processed_data=$(python3 process_data.py "$data")
    echo "Processed data: $processed_data"

3. Using awk for Data Processing


    #!/bin/bash
    
    # Assuming we have a CSV file named 'data.csv'
    average=$(awk -F',' '{sum+=$2} END {print sum/NR}' data.csv)
    echo "The average is: $average"


## Best Practices

1. Always check for the existence of external commands before using them.
2. Use full paths for scripts and commands when necessary to avoid PATH issues.
3. Handle errors and edge cases when incorporating external resources.
4. Document dependencies clearly in your script's comments or README.
5. Consider using functions to encapsulate external command logic for better readability and reusability.

## Exercises

1. Create a Bash script that uses `curl` to fetch weather data from a public API and `jq` to parse and display specific information (e.g., temperature, humidity).

2. Write a script that incorporates an external Python script to perform a complex calculation, then uses the result in further Bash operations.

3. Develop a log analysis script that uses a combination of `grep`, `awk`, and `sort` to extract and summarize information from a log file.

4. Create a backup script that uses `rsync` to synchronize files and captures both stdout and stderr for logging purposes.

5. Write a system information script that collects data using various system commands (`uname`, `df`, `free`, etc.) and formats the output into a JSON structure using `jq`.

## Additional Resources

- [Bash Manual: Command Substitution](https://www.gnu.org/software/bash/manual/html_node/Command-Substitution.html)
- [Advanced Bash-Scripting Guide: External Commands](https://tldp.org/LDP/abs/html/external.html)
- [Bash Hackers Wiki: Command Substitution](https://wiki.bash-hackers.org/syntax/expansion/cmdsubst)