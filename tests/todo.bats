#!/usr/bin/env bats
# Tests for projects/todo-list/todo.sh

load test_helper

setup() {
    make_workdir
    export TODO_FILE="$WORKDIR/todo_list.txt"
    TODO="$REPO_ROOT/projects/todo-list/todo.sh"
}

teardown() {
    cleanup_workdir
}

@test "script is executable" {
    [ -x "$TODO" ]
}

@test "no arguments prints usage and fails" {
    run "$TODO"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"Commands:"* ]]
}

@test "help prints usage and succeeds" {
    run "$TODO" help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Commands:"* ]]
}

@test "add stores a timestamped task" {
    run "$TODO" add "test task"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Task added successfully"* ]]
    [[ "$(cat "$TODO_FILE")" =~ ^\[[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\]\ test\ task$ ]]
}

@test "add accepts punctuation and shell metacharacters as plain text" {
    run "$TODO" add 'buy milk & eggs; $5 total'
    [ "$status" -eq 0 ]
    grep -qF 'buy milk & eggs; $5 total' "$TODO_FILE"
}

@test "add rejects an empty description" {
    run "$TODO" add ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Input cannot be empty"* ]]
}

@test "add rejects a description over 500 characters" {
    long_task=$(printf 'a%.0s' {1..501})
    run "$TODO" add "$long_task"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Input too long"* ]]
}

@test "add rejects control characters" {
    run "$TODO" add $'line one\nline two'
    [ "$status" -eq 1 ]
    [[ "$output" == *"Input contains invalid characters"* ]]
}

@test "list on a fresh list says it is empty" {
    run "$TODO" list
    [ "$status" -eq 0 ]
    [[ "$output" == *"To-Do List is empty"* ]]
}

@test "list shows numbered tasks and a total" {
    "$TODO" add "test task 1" >/dev/null
    "$TODO" add "test task 2" >/dev/null
    run "$TODO" list
    [ "$status" -eq 0 ]
    [[ "$output" == *"test task 1"* ]]
    [[ "$output" == *"test task 2"* ]]
    [[ "$output" == *"Total tasks: 2"* ]]
}

@test "remove deletes only the chosen task" {
    "$TODO" add "task 1" >/dev/null
    "$TODO" add "task 2" >/dev/null
    run "$TODO" remove 1
    [ "$status" -eq 0 ]
    [[ "$output" == *"Task removed successfully"* ]]
    run "$TODO" list
    [[ "$output" != *"task 1"* ]]
    [[ "$output" == *"task 2"* ]]
}

@test "remove rejects non-numeric, zero and out-of-range numbers" {
    "$TODO" add "only task" >/dev/null
    run "$TODO" remove abc
    [ "$status" -eq 1 ]
    [[ "$output" == *"positive integer"* ]]
    run "$TODO" remove 0
    [ "$status" -eq 1 ]
    [[ "$output" == *"positive integer"* ]]
    run "$TODO" remove 999
    [ "$status" -eq 1 ]
    [[ "$output" == *"out of range"* ]]
}

@test "search finds matches case-insensitively" {
    "$TODO" add "Important meeting" >/dev/null
    "$TODO" add "buy groceries" >/dev/null
    "$TODO" add "call important client" >/dev/null
    run "$TODO" search "important"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Important meeting"* ]]
    [[ "$output" == *"important client"* ]]
    [[ "$output" != *"groceries"* ]]
}

@test "search treats the term literally, not as a regex" {
    "$TODO" add "plain task" >/dev/null
    run "$TODO" search ".*"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No tasks found"* ]]
}

@test "search reports when nothing matches" {
    "$TODO" add "test task" >/dev/null
    run "$TODO" search "nonexistent"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No tasks found matching"* ]]
}

@test "search without a term fails" {
    run "$TODO" search ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Please provide a search term"* ]]
}

@test "backup then restore brings a cleared list back" {
    "$TODO" add "original task" >/dev/null
    run "$TODO" backup
    [ "$status" -eq 0 ]
    [[ "$output" == *"Backup created successfully"* ]]
    "$TODO" clear >/dev/null
    run "$TODO" list
    [[ "$output" == *"empty"* ]]
    run "$TODO" restore
    [ "$status" -eq 0 ]
    [[ "$output" == *"Backup restored"* ]]
    run "$TODO" list
    [[ "$output" == *"original task"* ]]
}

@test "restore without a backup fails" {
    run "$TODO" restore
    [ "$status" -eq 1 ]
    [[ "$output" == *"No backup found"* ]]
}

@test "clear empties the list" {
    "$TODO" add "task 1" >/dev/null
    run "$TODO" clear
    [ "$status" -eq 0 ]
    [[ "$output" == *"All tasks cleared"* ]]
    [ ! -s "$TODO_FILE" ]
}

@test "every modification keeps the previous state as a backup" {
    "$TODO" add "original" >/dev/null
    "$TODO" add "new task" >/dev/null
    backup="${TODO_FILE%.txt}.backup"
    grep -q "original" "$backup"
    ! grep -q "new task" "$backup"
}

@test "unknown command fails with a hint" {
    run "$TODO" frobnicate
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command 'frobnicate'"* ]]
}
