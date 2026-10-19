# Day 02: Working With Files and Directories

> **Time:** ~45 min · **Level:** Beginner
> **Prerequisites:** [Day 01](day-01.md)

## Goal

By the end of this lesson you can:

- Create, copy, move, rename and remove files and directories, and predict what each command leaves behind.
- Use globs (`*`, `?`, `{a,b}`) and know that the shell, not the command, expands them.
- Delete safely: preview with `ls`, confirm with `-i`, and prefer `rmdir` for directories you expect to be empty.

## Concepts

### The core six

| Command | Does | Example |
|---------|------|---------|
| `ls` | list | `ls -lA` (long, include dotfiles, skip `.` and `..`) |
| `mkdir` | make directories | `mkdir -p a/b/c` (`-p` creates parents, no error if present) |
| `touch` | create empty file / update timestamp | `touch notes.txt` |
| `cp` | copy | `cp -a src dst` (`-a` = recursive, keep permissions and times) |
| `mv` | move or rename | `mv old.txt new.txt` |
| `rm` / `rmdir` | delete | `rm -i file`, `rmdir emptydir` |

`mv` within one filesystem renames; it does not copy data. `cp -r` on a directory copies the directory **and** everything inside.

### Globs are expanded by the shell

```bash
echo project/src/*.c
```

Before `echo` runs, bash replaces the pattern with the matching names. If nothing matches, bash passes the pattern through unchanged, which is why `rm *.tmp` fails with "No such file" when there are no `.tmp` files.

Brace expansion `{a,b}` is different: it generates words and does not look at the disk. `mkdir -p project/{src,docs}` is exactly `mkdir -p project/src project/docs`.

### Quote names that contain spaces

`cp my photos backup` is **three** arguments. Write `cp "my photos" backup`. The same applies to variables: `"$dir"`.

## Worked example

Scenario: scaffold a small project, make a backup copy, then clean up.

```bash
mkdir -p ~/linux20-test/day-02 && cd ~/linux20-test/day-02
mkdir -p project/{src,docs,backup}
touch project/src/main.c project/src/util.c project/docs/readme.txt
ls -R project
```

**Expected output:**

```text
project:
backup
docs
src

project/backup:

project/docs:
readme.txt

project/src:
main.c
util.c
```

Copy a file, rename the copy, and look at the result:

```bash
cp project/src/main.c project/backup/
mv project/backup/main.c project/backup/main.c.bak
ls project/backup
```

**Expected output:**

```text
main.c.bak
```

See what the shell does with a glob, then copy the whole tree:

```bash
echo project/src/*.c
cp -r project project-copy
ls project-copy
```

**Expected output:**

```text
project/src/main.c project/src/util.c
backup
docs
src
```

Now remove things, from safest to riskiest:

```bash
rm project/docs/readme.txt
rmdir project/docs
rmdir project/src
```

`rmdir project/docs` succeeds because the directory is now empty. `rmdir project/src` fails because it still holds two files:

```text
rmdir: failed to remove 'project/src': Directory not empty
```

(The wording differs slightly between coreutils versions; the meaning does not.) That refusal is a feature: `rmdir` cannot delete data.

Clean up the whole exercise area. Read the command twice before pressing Enter.

> [!WARNING]
> `rm -r` deletes without a trash bin and without asking. Always `ls` the exact path first. Never put
> an unquoted variable in an `rm -r` command: if it is empty, you may be deleting something much larger
> than you meant.

```bash
cd ~
ls ~/linux20-test          # look first
rm -r ~/linux20-test       # then delete
```

**Undo:** there is none. If a file mattered, copy it first (`cp -a`) or use the `trash.sh` helper from the Hard exercise.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `rm -rf $dir/*` with `dir` unset | Becomes `rm -rf /*` | Quote and guard: `rm -rf "${dir:?}"/*` |
| `cp my photos backup` | Three arguments, not two | `cp "my photos" backup` |
| `mkdir a/b/c` fails: "No such file or directory" | Parents do not exist | `mkdir -p a/b/c` |
| `mv a b` overwrites `b` silently | `mv` replaces existing files | `mv -n` (never overwrite) or `mv -i` (ask) |
| `cp dir newdir` says "-r not specified; omitting directory" | `cp` needs `-r` for directories | `cp -a dir newdir` |
| `rm *.tmp` errors when there are none | Unmatched glob stays literal | `find . -name '*.tmp' -delete` |

## Exercises

Do these in an empty directory (`cd "$(mktemp -d)"`). Reference solutions: [`solutions/day-02/`](solutions/day-02/).

### Easy

Create `proj/` containing `src/`, `docs/` and `tests/`, with an empty `proj/src/app.sh` and `proj/docs/README.md`, using as few commands as you can.

**Acceptance criteria:**

- `find proj | sort` prints exactly: `proj`, `proj/docs`, `proj/docs/README.md`, `proj/src`, `proj/src/app.sh`, `proj/tests`.
- You used `mkdir -p` with brace expansion.

### Medium

Make a backup copy `proj.bak`, rename `README.md` to `README.txt` **in the copy only**, and delete the empty `tests/` directory from the original only, without using `rm`.

**Acceptance criteria:**

- `proj/tests` no longer exists; `proj.bak/tests` still does.
- `proj/docs/README.md` still exists; `proj.bak/docs/README.txt` exists.
- No file's timestamp or mode changed in the copy (hint: `cp -a`).

### Hard

Write `trash.sh FILE...` that moves each argument into a trash directory (`$TRASH_DIR`, default `~/.local/share/mytrash`) instead of deleting it.

**Acceptance criteria:**

- Names with spaces work.
- Trashing the same name twice keeps both copies.
- No arguments, a missing file, or `/` produce an error message and a non-zero exit status, and nothing is moved.
- It never overwrites an existing file in the trash.

### Break it

Run [`solutions/day-02/break-it.sh`](solutions/day-02/break-it.sh) in an empty directory. It should back up the folder `my photos` to `backup/2024` and delete `*.tmp` files in it, but it has three bugs. Fix them.

**Acceptance criteria:** the script prints `backup complete`, `backup/2024/my photos/a.jpg` exists, and the script also works when there are no `.tmp` files.

## Solutions

<details>
<summary>Easy</summary>

```bash
mkdir -p proj/{src,docs,tests}
touch proj/src/app.sh proj/docs/README.md
```

Script with check: [`easy.sh`](solutions/day-02/easy.sh).

</details>

<details>
<summary>Medium</summary>

```bash
cp -a proj proj.bak
mv proj.bak/docs/README.md proj.bak/docs/README.txt
rmdir proj/tests
```

`rmdir` only removes empty directories, so it is the safe tool when you believe a directory is empty. Script: [`medium.sh`](solutions/day-02/medium.sh).

</details>

<details>
<summary>Hard</summary>

Core of the solution: build a unique target name, never overwrite, and quote everything.

```bash
target="$dir/$(basename -- "$f").$stamp"
n=0
while [[ -e $target ]]; do
  n=$((n + 1)); target="$dir/$(basename -- "$f").$stamp.$n"
done
mv -n -- "$f" "$target"
```

`--` ends option parsing so a file called `-rf` cannot be read as an option. Full script with `--self-test`: [`hard.sh`](solutions/day-02/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. `mkdir $dest` fails because `backup/` does not exist: use `mkdir -p "$dest"`.
2. `cp -r $src $dest` splits `my photos` into `my` and `photos`: quote both variables.
3. `rm $src/*.tmp` errors when nothing matches, and `set -e` aborts the script: use `find "$src" -name '*.tmp' -type f -delete`.

Fixed script: [`break-it.fixed.sh`](solutions/day-02/break-it.fixed.sh).

</details>

## Self-check

1. What is the difference between `mkdir a/b` and `mkdir -p a/b`?
2. Who expands `*.c`: `ls` or bash?
3. Why is `rmdir` safer than `rm -r` for cleaning up what should be an empty directory?
4. What does `mv -n a b` do if `b` already exists?
5. How do you copy a directory and keep its timestamps and permissions?

<details>
<summary>Answers</summary>

1. `-p` also creates missing parents and does not complain if the directory exists.
2. Bash, before `ls` starts. The command only sees the resulting names.
3. `rmdir` refuses if anything is inside, so it cannot delete data by accident.
4. Nothing: `-n` means never overwrite.
5. `cp -a dir copy`.

</details>

## Cheat sheet

```bash
ls -lAh                     # long, hidden, human sizes
mkdir -p a/b/c              # parents as needed
touch file                  # create or update timestamp
cp -a src dst               # recursive copy preserving metadata
mv -n old new               # rename/move, never overwrite
rmdir dir                   # delete only if empty
rm -i file                  # ask before deleting
echo *.txt                  # preview what a glob matches
mkdir -p p/{src,docs}       # brace expansion
```

## Further reading

- [cp(1) on Ubuntu manpages](https://manpages.ubuntu.com/manpages/noble/man1/cp.1.html): every cp option, including -a and --backup.
- [rm(1) on Ubuntu manpages](https://manpages.ubuntu.com/manpages/noble/man1/rm.1.html): what --preserve-root and -I do.
- [POSIX shell command language: pattern matching](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html): the standard definition of globs, quoting and redirection.
- [Bash Day 03: variables, quoting and strict mode](../30-days-of-bash/day-03.md): quoting rules in depth, in the scripting course.

**Next:** [Day 03](day-03.md)
