# Day 21: Understanding Regular Expressions

## Introduction

Regular expressions (regex) are powerful tools for pattern matching and text manipulation. In Bash scripting, regex can be used with various commands like `grep`, `sed`, and `awk` to perform complex text processing tasks.

## Basic Regular Expression Syntax

### Literal Characters
- Most characters match themselves: `a` matches "a"

### Special Characters
- `.`: Matches any single character except newline
- `*`: Matches zero or more occurrences of the previous character
- `^`: Matches the start of a line
- `$`: Matches the end of a line
- `[]`: Matches any single character within the brackets
- `[^]`: Matches any single character not within the brackets

## Extended Regular Expression Syntax

### Quantifiers
- `+`: Matches one or more occurrences
- `?`: Matches zero or one occurrence
- `{n}`: Matches exactly n occurrences
- `{n,}`: Matches n or more occurrences
- `{n,m}`: Matches between n and m occurrences

### Character Classes
- `\d`: Matches any digit (equivalent to `[0-9]`)
- `\w`: Matches any word character (equivalent to `[a-zA-Z0-9_]`)
- `\s`: Matches any whitespace character

### Grouping and Alternation
- `()`: Groups expressions together
- `|`: Matches either the expression before or after the |

## Using Regex in Bash Commands

### grep


    grep -E "pattern" file.txt

### sed


    sed -E 's/pattern/replacement/g' file.txt

### awk


    awk '/pattern/ {print $0}' file.txt

### Practical Examples

Matching email addresses:

    [A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}

Validating IP addresses:


    ^([0-9]{1,3}\.){3}[0-9]{1,3}$

Extracting dates in YYYY-MM-DD format:

    \d{4}-\d{2}-\d{2}

## Exercises

1. Write a regex pattern to match and extract all phone numbers in a text file, assuming they are in the format (xxx) xxx-xxxx.

2. Create a Bash script that uses `sed` with regex to remove all HTML tags from a given file.

3. Write a regex pattern to validate a password that must contain at least one uppercase letter, one lowercase letter, one number, and be at least 8 characters long.

4. Use `grep` with a regex pattern to find all lines in a log file that contain an IP address and a timestamp in the format [DD/Mon/YYYY:HH:MM:SS].

5. Create a Bash script that uses `awk` with regex to extract and sum all floating-point numbers from a text file.

## Additional Resources

- [Regular Expressions in grep](https://www.gnu.org/software/grep/manual/html_node/Regular-Expressions.html)
- [sed Regular Expressions](https://www.gnu.org/software/sed/manual/html_node/Regular-Expressions.html)
- [awk Regular Expressions](https://www.gnu.org/software/gawk/manual/html_node/Regexp.html)
- [RegExr: Learn, Build, & Test RegEx](https://regexr.com/)

