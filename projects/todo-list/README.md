# To-do list manager

A command-line to-do list in about 120 lines of Bash. It is small enough to read in one sitting and
covers the habits that matter: input validation, safe file edits, backups, and clear exit codes.

**You will practise:** `case` dispatch, functions, `set -euo pipefail`, quoting, `grep -F`, atomic file
updates with `mktemp` + `mv`, and testing with Bats.

## Usage

```bash
./todo.sh add "Learn Linux scripting"
./todo.sh add "Read the bash manual"
./todo.sh list
./todo.sh search bash
./todo.sh remove 1
./todo.sh backup
./todo.sh clear
./todo.sh restore       # undo the clear
```

Output:

```text
To-Do List:
 1. [2026-10-17 13:27:24] Learn Linux scripting
 2. [2026-10-17 13:27:24] Read the bash manual
Total tasks: 2
```

| Command | What it does |
|---------|--------------|
| `add TEXT` | Appends `[timestamp] TEXT`. Rejects empty text, over 500 characters, and control characters |
| `list` | Numbered list and total |
| `remove N` | Deletes task `N` (must be in range) |
| `search TERM` | Case-insensitive, **literal** match (the term is not a regex); keeps the original task numbers |
| `backup` / `restore` | Copy the list aside / bring it back |
| `clear` | Empties the list after taking a backup |

Every command that changes the list first saves the previous version to `todo_list.backup`, so a
mistake is one `restore` away. The list lives in `./todo_list.txt`; set `TODO_FILE=/path/list.txt` to
use another file.

## Run the tests

```bash
bats ../../tests/todo.bats
```

## Exercises

1. **Easy.** Add a `count` command that prints only the number of tasks.
2. **Medium.** Add `done N` that moves a task to `todo_list.done` with a completion timestamp.
3. **Medium.** Add `--priority high|low` to `add` and make `list` sort high priority first.
4. **Hard.** Replace the single backup with the last five, named by timestamp, and add `restore N`.
   Write Bats tests first.
