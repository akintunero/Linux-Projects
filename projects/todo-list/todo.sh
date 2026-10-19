#!/usr/bin/env bash
#
# todo.sh - a small to-do manager with timestamps, search, backup and restore.
#
# Usage: todo.sh COMMAND [ARGS]
# Environment: TODO_FILE (default: ./todo_list.txt)

set -euo pipefail

# shellcheck source=../../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

readonly MAX_TASK_LENGTH=500
TODO_FILE="${TODO_FILE:-todo_list.txt}"
BACKUP_FILE="${TODO_FILE%.txt}.backup"

usage() {
    cat <<EOF
Usage: ${0##*/} COMMAND [ARGS]

Commands:
  add TEXT        Add a task (timestamped)
  list            Show all tasks
  remove N        Remove task number N
  search TERM     Show tasks containing TERM (case-insensitive)
  backup          Save a copy of the list
  restore         Restore the list from the last backup
  clear           Remove every task (a backup is taken first)
  help            Show this message

Environment:
  TODO_FILE       Path of the list (default: ./todo_list.txt)
EOF
}

# validate_text TEXT - reject empty, over-long or control-character input
validate_text() {
    local text="$1"
    [[ -n "$text" ]] || die "Input cannot be empty"
    ((${#text} <= MAX_TASK_LENGTH)) || die "Input too long (max $MAX_TASK_LENGTH characters)"
    # Tasks are stored one per line, so newlines (and other control
    # characters) would corrupt the file. Everything else is plain text.
    if [[ "$text" =~ [[:cntrl:]] ]]; then
        die "Input contains invalid characters"
    fi
}

task_count() { wc -l <"$TODO_FILE" | tr -d ' '; }

# make_backup - copy the list aside before anything modifies it
make_backup() {
    cp -- "$TODO_FILE" "$BACKUP_FILE"
}

cmd_add() {
    local text="${1:-}"
    validate_text "$text"
    make_backup
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$text" >>"$TODO_FILE"
    ok "Task added successfully"
}

cmd_list() {
    if [[ ! -s "$TODO_FILE" ]]; then
        msg "To-Do List is empty"
        return 0
    fi
    info "To-Do List:"
    nl -w2 -s'. ' -b a "$TODO_FILE"
    msg "Total tasks: $(task_count)"
}

cmd_remove() {
    local n="${1:-}"
    is_positive_int "$n" || die "Task number must be a positive integer"
    local count
    count=$(task_count)
    ((10#$n <= count)) || die "Task number out of range (1-$count)"
    make_backup
    # Portable delete-line: no sed -i (differs between GNU and BSD).
    local tmp
    tmp=$(mktemp)
    sed "${n}d" "$TODO_FILE" >"$tmp"
    mv -- "$tmp" "$TODO_FILE"
    ok "Task removed successfully"
}

cmd_search() {
    local term="${1:-}"
    [[ -n "$term" ]] || die "Please provide a search term"
    local hits
    # -F: treat the term literally, not as a regex. -n: keep real task numbers.
    if hits=$(grep -n -i -F -- "$term" "$TODO_FILE"); then
        info "Tasks matching '$term':"
        msg "$hits"
    else
        msg "No tasks found matching '$term'"
    fi
}

cmd_backup() {
    make_backup
    ok "Backup created successfully: $BACKUP_FILE"
}

cmd_restore() {
    [[ -f "$BACKUP_FILE" ]] || die "No backup found at $BACKUP_FILE"
    cp -- "$BACKUP_FILE" "$TODO_FILE"
    ok "Backup restored"
}

cmd_clear() {
    make_backup
    : >"$TODO_FILE"
    ok "All tasks cleared (undo with: ${0##*/} restore)"
}

main() {
    if (($# == 0)); then
        usage >&2
        exit 1
    fi

    [[ -f "$TODO_FILE" ]] || : >"$TODO_FILE"

    local command="$1"
    shift
    case "$command" in
        add) cmd_add "${1:-}" ;;
        list) cmd_list ;;
        remove) cmd_remove "${1:-}" ;;
        search) cmd_search "${1:-}" ;;
        backup) cmd_backup ;;
        restore) cmd_restore ;;
        clear) cmd_clear ;;
        help | -h | --help) usage ;;
        *) die "Unknown command '$command' (try: ${0##*/} help)" ;;
    esac
}

main "$@"
