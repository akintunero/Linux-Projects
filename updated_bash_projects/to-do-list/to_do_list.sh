#!/bin/bash

# To-Do List Manager

# Usage: ./todo_manager.sh [add|remove|list] [task_number|task_description]

TODO_FILE="todo_list.txt"

if [ ! -f "$TODO_FILE" ]; then
    touch "$TODO_FILE"
fi

case $1 in
    add)
        if [ -z "$2" ]; then
            echo "Please provide a task description."
            exit 1
        fi
        echo "$2" >> "$TODO_FILE"
        echo "Task added successfully."
        ;;
    remove)
        if [ -z "$2" ]; then
            echo "Please provide a task number."
            exit 1
        fi
        if [ $2 -le 0 ]; then
            echo "Task number must be a positive integer."
            exit 1
        fi
        task_count=$(wc -l < "$TODO_FILE")
        if [ $2 -gt $task_count ]; then
            echo "Task number out of range."
            exit 1
        fi
        sed -i "${2}d" "$TODO_FILE"
        echo "Task removed successfully."
        ;;
    list)
        if [ -s "$TODO_FILE" ]; then
            echo "To-Do List:"
            cat -n "$TODO_FILE"
        else
            echo "To-Do List is empty."
        fi
        ;;
    *)
        echo "Usage: $0 [add|remove|list] [task_number|task_description]"
        exit 1
        ;;
esac
