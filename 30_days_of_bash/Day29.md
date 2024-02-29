# Day 29: Advanced Text Processing with `grep` and `cut`

## Introduction

`grep` and `cut` are powerful command-line tools for text processing in Unix-like systems. This lesson covers advanced techniques for using these tools effectively in Bash scripts.

## Advanced `grep` Techniques

### 1. Regular Expressions with `grep`

- Basic regex: `grep "pattern" file`
- Extended regex: `grep -E "pattern" file` or `egrep "pattern" file`

Example:

    grep -E "^[A-Z]{3}-[0-9]{4}$" file.txt  # Match format XXX-0000

2. Inverting Matches
Use -v to print lines that don't match:


    grep -v "error" logfile.txt

3. Recursive Searching
Use -r to search recursively through directories:


    grep -r "TODO" /path/to/project

4. Context Control


    -B n: Show n lines before the match
    -A n: Show n lines after the match
    -C n: Show n lines before and after the match

Example:

    grep -C 2 "error" logfile.txt

5. Counting Matches
Use -c to count matches:


    grep -c "error" logfile.txt

Advanced cut Techniques
1. Selecting Fields
Use -f to select specific fields:


    cut -f 1,3 -d ',' data.csv

2. Specifying Delimiter
Use -d to specify a delimiter:


    cut -d ':' -f 1 /etc/passwd

3. Character Ranges
Select specific character ranges:


    cut -c 1-5,10-15 file.txt

4. Complement Selection
Use --complement to select everything except specified fields:


    cut -f 2 --complement -d ',' data.csv

Combining grep and cut
You can pipe the output of grep to cut for more complex text processing:


    grep "ERROR" logfile.txt | cut -d ' ' -f 3-

Practical Examples
1. Extracting Email Addresses


    grep -E -o "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b" file.txt

2. Analyzing Apache Access Logs


    grep "POST" access.log | cut -d ' ' -f 1 | sort | uniq -c | sort -rn

3. Filtering and Extracting CSV Data


    grep "New York" data.csv | cut -d ',' -f 2,4


## Exercises

1. Write a script that uses `grep` to find all lines in a log file that contain "ERROR" and extract the timestamp using `cut`.

2. Create a script that searches for phone numbers in a text file using `grep` with a regular expression, then uses `cut` to format the output.

3. Develop a script that uses `grep` to find all TODO comments in a set of source code files, and `cut` to extract the relevant parts of the comments.

4. Write a script that analyzes a CSV file, using `grep` to filter rows based on a condition, and `cut` to extract specific columns.

5. Create a script that uses `grep` to search for a specific pattern across multiple files, then uses `cut` to extract and display relevant information from the matching lines.

## Additional Resources

- [GNU Grep Manual](https://www.gnu.org/software/grep/manual/grep.html)
- [Cut Command in Linux](https://www.geeksforgeeks.org/cut-command-linux-examples/)
- [Advanced Bash-Scripting Guide: Text Processing Commands](https://tldp.org/LDP/abs/html/textproc.html)

