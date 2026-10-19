# Day 02: Files, Navigation and Globbing

> **Time:** ~50 min · **Level:** Beginner
> **Prerequisites:** [Day 01](day-01.md)

## Goal

By the end of this lesson you can:

- Move around the filesystem and create, copy, move and remove files and directories.
- Use globs (`*`, `?`, `[...]`) and brace expansion (`{a,b}`) to select files.
- Delete safely: preview first, quote names, and guard patterns that match nothing.

## Concepts

Work in your practice directory (`mkdir -p ~/bash-lab && cd ~/bash-lab`) for the whole lesson.

### Where am I? Absolute and relative paths

```bash
pwd          # print working directory
cd /tmp      # absolute path: starts at the root /
cd ..        # relative path: one level up
cd -         # back to the previous directory
cd           # no argument: go home (~)
```

An **absolute** path starts with `/`. A **relative** path starts from where you are now. `.` means
"here" and `..` means "the parent directory".

### Looking around

```bash
ls            # names only
ls -l         # long format: permissions, owner, size, date
ls -la        # also show hidden files (names starting with .)
ls -lh        # human-readable sizes (K, M, G)
```

### Creating, copying, moving, removing

| Command | What it does | Useful flags |
|---------|--------------|--------------|
| `mkdir dir` | Create a directory | `-p` also creates parents and is quiet if it exists |
| `touch file` | Create an empty file or update its timestamp | |
| `cp src dst` | Copy | `-r` directories, `-a` keep metadata, `-v` verbose |
| `mv src dst` | Move or rename | `-v` verbose, `-n` never overwrite |
| `rm file` | Remove (no trash can!) | `-r` directories, `-i` ask first |

### Reading files

```bash
cat file          # print the whole file
head -n 5 file    # first 5 lines
tail -n 5 file    # last 5 lines
wc -l file        # count lines
less file         # scroll; q quits
```

### Getting help

```bash
man ls            # the manual page
ls --help         # short usage summary
type cd           # is it a shell builtin, alias, or program?
```

### Globs: let the shell pick the files

The shell expands patterns **before** the command runs. The command never sees the `*`.

| Pattern | Matches |
|---------|---------|
| `*` | any number of characters, e.g. `*.txt` |
| `?` | exactly one character, e.g. `file?.txt` |
| `[abc]` / `[0-9]` | one character from a set or range |
| `{a,b,c}` | not a glob but *brace expansion*: `file.{txt,log}` becomes `file.txt file.log` |

> [!WARNING]
> `rm` has no undo. Before any `rm` with a glob, run `ls` with the same pattern first and read what
> it lists. Never run `rm -rf` with a variable you have not checked is non-empty.

### Quote names with spaces

`cp my notes.txt backup/` gives `cp` **three** arguments. Always quote: `cp "my notes.txt" backup/`.

## Worked example

Save this as `tour.sh` and run `bash tour.sh` in an empty directory. It builds a small project and
practises each command above.

```bash
#!/usr/bin/env bash
# tour.sh - build a small project, look around, copy and move things
mkdir -p project/{docs,src,backup}
touch project/docs/notes.txt project/docs/todo.txt project/src/app.sh project/src/app.log
cd project || exit 1
echo "Now in: $(basename "$PWD")"

echo "--- top level"
ls

echo "--- everything below here"
find . | sort

echo "--- only text files in docs"
ls docs/*.txt

echo "--- copy, then move"
cp -v docs/notes.txt backup/
mv -v src/app.log backup/app.log.old

echo "--- backup now holds"
ls backup
```

**Expected output**

```text
Now in: project
--- top level
backup
docs
src
--- everything below here
.
./backup
./docs
./docs/notes.txt
./docs/todo.txt
./src
./src/app.log
./src/app.sh
--- only text files in docs
docs/notes.txt
docs/todo.txt
--- copy, then move
'docs/notes.txt' -> 'backup/notes.txt'
renamed 'src/app.log' -> 'backup/app.log.old'
--- backup now holds
app.log.old
notes.txt
```

Brace expansion built the three directories in one command. The path printed by `ls docs/*.txt`
shows the shell expanding the glob for us. Your `ls` may sort differently depending on locale.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `cp my notes.txt dir/` | The shell splits on spaces: three arguments | `cp "my notes.txt" dir/` |
| `mv *.log archive/` with no `.log` files | An unmatched glob stays literal, so `mv` looks for a file called `*.log` | `shopt -s nullglob` and check the array is non-empty |
| `rm -rf $dir/*` when `$dir` is empty | Expands to `rm -rf /*` | Use `${dir:?}` or check the variable first |
| `rm -rf *` in the wrong directory | `pwd` was not what you thought | Run `pwd` and `ls` first; prefer `rm -ri` while learning |
| `mkdir a/b/c` fails | `a/b` does not exist | `mkdir -p a/b/c` |
| `cp dir newdir` fails | `cp` skips directories without `-r` | `cp -r dir newdir` (or `-a`) |
| `mv file existing` silently overwrites | `mv` replaces without asking | `mv -n` (no clobber) or `mv -i` |

## Exercises

Run your solutions in a scratch directory (`mktemp -d` makes one), not in a folder you care about.

### Easy: photo tree

Create `photos/2024` and `photos/2025` with one command, put `beach.jpg`, `city.jpg`, `notes.txt`
in the first and `forest.jpg`, `lake.jpg`, `edit.png` in the second (use `touch` and brace
expansion). Then list only the `.jpg` files in both years with a single `ls`.

**Acceptance criteria**

- Exactly four paths are listed, all ending in `.jpg`.
- You used one `mkdir -p` and one glob, not four separate `ls` calls.

### Medium: sort a messy folder

In a scratch directory create `a.txt`, `b.txt`, `my notes.txt`, `c.log`, `d.csv`. Write
`sort-files.sh` that moves all `.txt` files into `docs/` and all `.log` files into `logs/`, creating
the folders if needed. It must not fail when a folder has no matching files, so test it again after
the first run.

**Acceptance criteria**

- `docs/` holds three files including `my notes.txt`; `logs/` holds `c.log`; `d.csv` stays put.
- Running the script a second time prints no errors.
- Uses `shopt -s nullglob` and quotes every expansion.

### Hard: backup and verify

Create a small `project/` tree with a `docs/readme.txt` and a `src/app.sh`. Copy it to
`project.bak` preserving metadata, and use `diff -r` to prove the two are identical. Then edit one
file and show that `diff -r` now reports a difference. Print a friendly message for each case.

**Acceptance criteria**

- First check prints `backup verified: identical`.
- After the edit the script prints that the trees differ and shows the `diff` output.
- No files are left behind in the directory you ran it from.

### Break it

This script has **two bugs**. Save it as `break-it.sh`, run it in an empty directory, and fix it.

```bash
#!/usr/bin/env bash
mkdir -p backup archive
echo "hello" > "my notes.txt"
cp my notes.txt backup/
mv *.log archive/
ls backup archive
```

**Expected output**

```text
cp: cannot stat 'my': No such file or directory
cp: cannot stat 'notes.txt': No such file or directory
mv: cannot stat '*.log': No such file or directory
archive:

backup:
```

<details>
<summary>Hint</summary>

Count the arguments the first failing command received, then ask what the shell does with `*.log`
when there is nothing to match.

</details>

## Solutions

<details>
<summary>Easy</summary>

`photos/{2024,2025}` expands to two paths, and `photos/*/*.jpg` matches every `.jpg` one level
down inside any year folder.

```bash
#!/usr/bin/env bash
# Day 02 easy: build the photo tree and list only the .jpg files.
work="$(mktemp -d)"
cd "$work" || exit 1

mkdir -p photos/{2024,2025}
touch photos/2024/{beach,city}.jpg photos/2024/notes.txt
touch photos/2025/{forest,lake}.jpg photos/2025/edit.png

echo "JPEG files:"
ls photos/*/*.jpg

cd / && rm -rf -- "$work"
```

**Expected output**

```text
JPEG files:
photos/2024/beach.jpg
photos/2024/city.jpg
photos/2025/forest.jpg
photos/2025/lake.jpg
```

</details>

<details>
<summary>Medium</summary>

With `nullglob` on, `*.log` expands to nothing when there are no matches, so the array is empty and
we skip `mv`. `--` ends option parsing so a file named `-x.txt` is not treated as a flag.

```bash
#!/usr/bin/env bash
# Day 02 medium: sort a messy folder into docs/ and logs/. Safe to re-run.
work="$(mktemp -d)"
cd "$work" || exit 1
touch a.txt b.txt "my notes.txt" c.log d.csv

mkdir -p docs logs
shopt -s nullglob          # a pattern with no match expands to nothing, not to itself

txt=(*.txt)
logs=(*.log)

if (( ${#txt[@]} > 0 )); then
    mv -v -- "${txt[@]}" docs/
fi
if (( ${#logs[@]} > 0 )); then
    mv -v -- "${logs[@]}" logs/
fi

echo "--- result"
find . -type f | sort

cd / && rm -rf -- "$work"
```

**Expected output**

```text
renamed 'a.txt' -> 'docs/a.txt'
renamed 'b.txt' -> 'docs/b.txt'
renamed 'my notes.txt' -> 'docs/my notes.txt'
renamed 'c.log' -> 'logs/c.log'
--- result
./d.csv
./docs/a.txt
./docs/b.txt
./docs/my notes.txt
./logs/c.log
```

</details>

<details>
<summary>Hard</summary>

`diff` exits 0 when inputs match and 1 when they differ, so the `if` can test it directly. We
discard its output on the first two checks and show it on the last.

```bash
#!/usr/bin/env bash
# Day 02 hard: back up a tree and prove the copy is identical.
work="$(mktemp -d)"
cd "$work" || exit 1

mkdir -p project/{docs,src}
echo "first draft" > project/docs/readme.txt
echo 'echo hi' > project/src/app.sh

cp -a project project.bak              # -a keeps timestamps and permissions

if diff -r project project.bak >/dev/null; then
    echo "backup verified: identical"
else
    echo "backup differs" >&2
fi

echo "second draft" > project/docs/readme.txt
if diff -r project project.bak >/dev/null; then
    echo "still identical"
else
    echo "after editing: trees differ, as expected"
    diff -r project project.bak
fi

cd / && rm -rf -- "$work"
```

**Expected output**

```text
backup verified: identical
after editing: trees differ, as expected
diff -r project/docs/readme.txt project.bak/docs/readme.txt
1c1
< second draft
---
> first draft
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `my notes.txt` is unquoted, so `cp` got two source names that do not exist. Bug 2: with no
`.log` files, the glob stays literal and `mv` fails. The fix quotes the name and guards the glob.

```bash
#!/usr/bin/env bash
# Fixed: quote the file name, and guard the glob so "no .log files" is not an error.
mkdir -p backup archive
echo "hello" > "my notes.txt"
cp "my notes.txt" backup/

shopt -s nullglob
logs=(*.log)
if (( ${#logs[@]} > 0 )); then
    mv -- "${logs[@]}" archive/
fi
ls backup archive
```

**Expected output**

```text
archive:

backup:
my notes.txt
```

</details>

Solution files live in [`solutions/day-02/`](solutions/day-02/).

## Self-check

1. What is the difference between `/home/me` and `home/me`?
2. What does `mkdir -p a/b/c` do that `mkdir a/b/c` may not?
3. Why does `rm *.tmp` print "No such file" when there are no `.tmp` files?
4. What does `ls file.{txt,log}` expand to?
5. Which flag makes `mv` refuse to overwrite an existing file?

<details>
<summary>Answers</summary>

1. The first is absolute (starts at `/`); the second is relative to the current directory.
2. It creates missing parent directories and does not complain if the directory already exists.
3. The glob matched nothing, so it stayed as the literal text `*.tmp` and `rm` looked for that file.
4. `ls file.txt file.log` (brace expansion happens before the command runs).
5. `-n` (`--no-clobber`); `-i` asks interactively instead.

</details>

## Cheat sheet

| Command | Purpose |
|---------|---------|
| `pwd`, `cd dir`, `cd -`, `cd` | Where am I, move, go back, go home |
| `ls -lah` | Detailed listing with hidden files |
| `mkdir -p a/b/c` | Create nested directories |
| `touch f` | Create empty file |
| `cp -a src dst` | Copy preserving metadata |
| `mv -n src dst` | Move without overwriting |
| `rm -ri dir` | Remove, asking first |
| `head`, `tail`, `wc -l`, `less` | Peek at files |
| `*`, `?`, `[a-c]`, `{x,y}` | Globs and brace expansion |
| `man cmd`, `cmd --help`, `type cmd` | Get help |

## Further reading

- [Greg's Wiki: Globs](https://mywiki.wooledge.org/glob): why globs beat `ls` parsing, with the
  gotchas spelled out.

**Next:** [Day 03](day-03.md)
