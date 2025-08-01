#!/bin/bash
set -euo pipefail

# Simple test version
readonly TODO_FILE="todo_list.txt"

# Function to print colored output
print_message() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}"
}

# Initialize todo file
if [[ ! -f "$TODO_FILE" ]]; then
    touch "$TODO_FILE"
fi

# Check if no arguments provided
if [[ $# -eq 0 ]]; then
    print_message "\033[0;34m" "Usage: $0 [add|remove|list] [task_number|task_description]"
    exit 1
fi

case $1 in
    add)
        if [[ -z "${2:-}" ]]; then
            print_message "\033[0;31m" "Error: Please provide a task description"
            exit 1
        fi
        echo "$2" >> "$TODO_FILE"
        print_message "\033[0;32m" "Task added successfully"
        ;;
    remove)
        if [[ -z "${2:-}" ]]; then
            print_message "\033[0;31m" "Error: Please provide a task number"
            exit 1
        fi
        if ! [[ "$2" =~ ^[0-9]+$ ]] || [[ $2 -le 0 ]]; then
            print_message "\033[0;31m" "Error: Task number must be a positive integer"
            exit 1
        fi
        task_count=$(wc -l < "$TODO_FILE" 2>/dev/null || echo "0")
        if [[ $2 -gt $task_count ]]; then
            print_message "\033[0;31m" "Error: Task number out of range (1-$task_count)"
            exit 1
        fi
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "${2}d" "$TODO_FILE"
        else
            sed -i "${2}d" "$TODO_FILE"
        fi
        print_message "\033[0;32m" "Task removed successfully"
        ;;
    list)
        if [[ -s "$TODO_FILE" ]]; then
            print_message "\033[0;34m" "To-Do List:"
            cat -n "$TODO_FILE"
        else
            print_message "\033[1;33m" "To-Do List is empty"
        fi
        ;;
    *)
        print_message "\033[0;31m" "Error: Unknown command '$1'"
        exit 1
        ;;
esac 