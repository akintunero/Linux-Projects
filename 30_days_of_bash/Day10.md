# Day 10: String Manipulation Techniques

## Introduction

String manipulation is a crucial skill in Bash scripting. It allows you to process and modify text data efficiently. This lesson covers various techniques for working with strings in Bash.

## Basic String Operations

### 1. String Length

To get the length of a string:


    string="Hello, World!"
    echo ${#string}  # Output: 13

2. Substring Extraction
- To extract a portion of a string:

    
    string="Hello, World!"
    echo ${string:7:5}  # Output: World

3. String Concatenation
- To concatenate strings:

    
    string1="Hello"
    string2="World"
    result="$string1 $string2"
    echo $result  # Output: Hello World

String Manipulation Techniques
1. Replacing Substrings
- To replace the first occurrence of a substring:

    
    string="The quick brown fox"
    echo ${string/quick/slow}  # Output: The slow brown fox

To replace all occurrences:


    string="The quick quick brown fox"
    echo ${string//quick/slow}  # Output: The slow slow brown fox

2. Removing Substrings
To remove from the beginning of a string:

    
    string="The quick brown fox"
    echo ${string#The }  # Output: quick brown fox

To remove from the end of a string:


    string="The quick brown fox"
    echo ${string%fox}  # Output: The quick brown 

3. Changing Case
To convert to uppercase:


    string="Hello, World!"
    echo ${string^^}  # Output: HELLO, WORLD!

To convert to lowercase:


    string="Hello, World!"
    echo ${string,,}  # Output: hello, world!

4. Trimming Whitespace
To trim leading and trailing whitespace:


    string="   Hello, World!   "
    trimmed=$(echo $string | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    echo "$trimmed"  # Output: Hello, World!

Advanced String Manipulation
1. Using Regular Expressions
    With =~ operator:
    
    
    string="The year is 2023"
    if [[ $string =~ [0-9]{4} ]]; then
        echo "Year found: ${BASH_REMATCH}"
    fi

2. String Splitting
Using IFS (Internal Field Separator):


    string="apple,banana,cherry"
    IFS=',' read -ra ADDR <<< "$string"
    for i in "${ADDR[@]}"; do
        echo "$i"
    done

Practical Examples

Extracting filename and extension:

    fullfile="/path/to/file.txt"
    filename=$(basename -- "$fullfile")
    extension="${filename##*.}"
    filename="${filename%.*}"
    echo "Filename: $filename, Extension: $extension"


Capitalizing the first letter of each word:


    string="hello world"
    capitalized=$(echo "$string" | sed 's/\b$$.$$/\u\1/g')
    echo "$capitalized"  # Output: Hello World


## Exercises

1. Write a script that takes a sentence as input and reverses each word in the sentence.

2. Create a function that counts the number of vowels in a given string.

3. Write a script that takes a filename as input and adds a prefix to it (e.g., "processed_").

4. Create a script that generates a random password of a specified length, ensuring it contains at least one uppercase letter, one lowercase letter, one number, and one special character.

5. Write a function that takes a string and returns true if it's a palindrome, false otherwise.

## Additional Resources

- [Bash String Manipulation](https://tldp.org/LDP/abs/html/string-manipulation.html)
- [Bash Scripting: String Operations](https://www.shellscript.sh/string-manipulation.html)
- [Advanced Bash-Scripting Guide: Manipulating Strings](https://tldp.org/LDP/abs/html/string-manipulation.html)