#!/usr/bin/env bats

# Test file for enhanced todo manager
# Author: Olúmáyòwá Akinkuehinmi
# Email: akintunero101@gmail.com

setup() {
    # Create temporary directory for tests
    export TEST_DIR=$(mktemp -d)
    export TODO_FILE="$TEST_DIR/todo_list.txt"
    export BACKUP_FILE="$TEST_DIR/todo_list.backup"
    
    # Copy the script to test directory
    cp ../updated_bash_projects/to-do-list/to_do_list.sh "$TEST_DIR/"
    chmod +x "$TEST_DIR/to_do_list.sh"
    
    # Change to test directory
    cd "$TEST_DIR"
}

teardown() {
    # Clean up test directory
    rm -rf "$TEST_DIR"
}

@test "script exists and is executable" {
    [ -f "to_do_list.sh" ]
    [ -x "to_do_list.sh" ]
}

@test "help message displays when no arguments provided" {
    run ./to_do_list.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"Commands:"* ]]
}

@test "add task functionality" {
    run ./to_do_list.sh add "test task"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Task added successfully"* ]]
    
    # Check if task was added to file
    [ -f "todo_list.txt" ]
    [[ "$(cat todo_list.txt)" == *"test task"* ]]
}

@test "add task with empty description fails" {
    run ./to_do_list.sh add ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Input cannot be empty"* ]]
}

@test "add task with very long description fails" {
    long_task=$(printf 'a%.0s' {1..600})
    run ./to_do_list.sh add "$long_task"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Input too long"* ]]
}

@test "add task with dangerous characters fails" {
    run ./to_do_list.sh add "task<script>alert('xss')</script>"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Input contains invalid characters"* ]]
}

@test "list tasks when empty" {
    run ./to_do_list.sh list
    [ "$status" -eq 0 ]
    [[ "$output" == *"To-Do List is empty"* ]]
}

@test "list tasks with content" {
    # Add a task first
    ./to_do_list.sh add "test task 1" > /dev/null
    ./to_do_list.sh add "test task 2" > /dev/null
    
    run ./to_do_list.sh list
    [ "$status" -eq 0 ]
    [[ "$output" == *"To-Do List:"* ]]
    [[ "$output" == *"test task 1"* ]]
    [[ "$output" == *"test task 2"* ]]
    [[ "$output" == *"Total tasks: 2"* ]]
}

@test "remove task functionality" {
    # Add tasks first
    ./to_do_list.sh add "task 1" > /dev/null
    ./to_do_list.sh add "task 2" > /dev/null
    
    # Remove first task
    run ./to_do_list.sh remove 1
    [ "$status" -eq 0 ]
    [[ "$output" == *"Task removed successfully"* ]]
    
    # Check that task was removed
    run ./to_do_list.sh list
    [[ "$output" != *"task 1"* ]]
    [[ "$output" == *"task 2"* ]]
}

@test "remove task with invalid number fails" {
    run ./to_do_list.sh remove "abc"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Task number must be a positive integer"* ]]
}

@test "remove task with zero fails" {
    run ./to_do_list.sh remove 0
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Task number must be a positive integer"* ]]
}

@test "remove task with out of range number fails" {
    run ./to_do_list.sh remove 999
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Task number out of range"* ]]
}

@test "backup functionality" {
    # Add a task first
    ./to_do_list.sh add "backup test task" > /dev/null
    
    run ./to_do_list.sh backup
    [ "$status" -eq 0 ]
    [[ "$output" == *"Backup created successfully"* ]]
    
    # Check if backup file exists
    [ -f "todo_list.backup" ]
}

@test "restore functionality" {
    # Add a task and create backup
    ./to_do_list.sh add "original task" > /dev/null
    ./to_do_list.sh backup > /dev/null
    
    # Clear the todo list
    ./to_do_list.sh clear > /dev/null
    
    # Restore from backup
    run ./to_do_list.sh restore
    [ "$status" -eq 0 ]
    [[ "$output" == *"Backup restored"* ]]
    
    # Check that task was restored
    run ./to_do_list.sh list
    [[ "$output" == *"original task"* ]]
}

@test "clear functionality" {
    # Add tasks first
    ./to_do_list.sh add "task 1" > /dev/null
    ./to_do_list.sh add "task 2" > /dev/null
    
    run ./to_do_list.sh clear
    [ "$status" -eq 0 ]
    [[ "$output" == *"All tasks cleared"* ]]
    
    # Check that tasks were cleared
    run ./to_do_list.sh list
    [[ "$output" == *"To-Do List is empty"* ]]
}

@test "search functionality" {
    # Add tasks
    ./to_do_list.sh add "important meeting" > /dev/null
    ./to_do_list.sh add "buy groceries" > /dev/null
    ./to_do_list.sh add "call important client" > /dev/null
    
    # Search for "important"
    run ./to_do_list.sh search "important"
    [ "$status" -eq 0 ]
    [[ "$output" == *"important meeting"* ]]
    [[ "$output" == *"important client"* ]]
    [[ "$output" != *"buy groceries"* ]]
}

@test "search with no results" {
    ./to_do_list.sh add "test task" > /dev/null
    
    run ./to_do_list.sh search "nonexistent"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No tasks found matching"* ]]
}

@test "search with empty term fails" {
    run ./to_do_list.sh search ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Please provide a search term"* ]]
}

@test "unknown command fails" {
    run ./to_do_list.sh unknown_command
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Unknown command"* ]]
}

@test "tasks are added with timestamps" {
    run ./to_do_list.sh add "timestamp test"
    [ "$status" -eq 0 ]
    
    # Check that timestamp was added
    local content
    content=$(cat todo_list.txt)
    [[ "$content" =~ ^\[[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\]\ timestamp\ test$ ]]
}

@test "backup is created before modifications" {
    # Add initial task
    ./to_do_list.sh add "original" > /dev/null
    
    # Add another task (should create backup)
    ./to_do_list.sh add "new task" > /dev/null
    
    # Check that backup exists
    [ -f "todo_list.backup" ]
    
    # Check backup content
    local backup_content
    backup_content=$(cat todo_list.backup)
    [[ "$backup_content" == *"original"* ]]
    [[ "$backup_content" != *"new task"* ]]
} 