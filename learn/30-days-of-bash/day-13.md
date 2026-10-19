# Day 13: File Permissions

> **Time:** ~50 min · **Level:** Intermediate
> **Prerequisites:** [Day 12](day-12.md)

## Goal

By the end of this lesson you can:

- Read `ls -l` and `stat` output and translate between symbolic (`rwxr-x---`) and octal (`750`) modes.
- Change modes with `chmod`, control defaults with `umask`, and find risky permissions with `find`.
- Pick the right mode for scripts, config files, secrets and directories.

## Concepts

### Who and what

Every file has an **owner**, a **group**, and three sets of permission bits: for the **user** (owner),
the **group** and **others**.

```text
-rwxr-x---  1 ada  devs  120 Oct 10 12:00 deploy.sh
 |||||||||
 |||||||++-- others: no access
 ||||||+---- group: r-x  (read, execute)
 |||+++----- user:  rwx  (read, write, execute)
 +---------- type: - file, d directory, l symlink
```

| Bit | On a file | On a directory |
|-----|-----------|----------------|
| `r` (4) | read the contents | list the names inside |
| `w` (2) | modify the contents | create, delete and rename entries inside |
| `x` (1) | run it as a program | **enter** it (`cd`) and reach what is inside |

Add the numbers for each triple: `rwx` = 7, `r-x` = 5, `rw-` = 6, `r--` = 4. So `rwxr-x---` is `750`.

### `chmod`

```bash
chmod 640 notes.txt          # octal: set all bits at once
chmod u+x script.sh          # symbolic: add execute for the owner
chmod go-rwx secrets.env     # take everything away from group and others
chmod -R o-w site/           # recurse (careful: affects files and directories alike)
```

Symbolic form is `who` (`u`, `g`, `o`, `a`) + operator (`+`, `-`, `=`) + bits (`r`, `w`, `x`).

### `umask`: defaults for new files

New files start from `666` and new directories from `777`, minus the bits in the umask. With the
common `022`, files become `644` and directories `755`. A `077` umask makes everything private.

### `chown` and `sudo`

`chown user:group file` changes the owner and normally needs root: `sudo chown ...`. You cannot give
files away without privileges. The exercises in this lesson avoid root entirely.

### Good defaults

| Thing | Mode | Why |
|-------|------|-----|
| Scripts and programs | `755` or `750` | Everyone (or the group) may run; only the owner edits |
| Config files | `644` or `640` | World-readable, or group-only if it contains hostnames |
| Secrets, SSH keys, `.env` | `600` | Owner only. `ssh` refuses keys that are too open |
| Private directories | `700` | Others cannot even enter |
| Anything | **never** `777` | World-writable files are a security hole |

> [!WARNING]
> `chmod -R 777 .` is the classic "make the error go away" command. It lets every user on the system
> modify and replace your files. If you hit "Permission denied", find out *which* bit is missing with
> `ls -ld` and `stat` and add only that one.

## Worked example

Everything below runs without root in an empty directory. Save as `perms.sh`.

```bash
#!/usr/bin/env bash
# perms.sh - reading and changing permissions (no root needed)
set -euo pipefail

show() { stat -c '%a %A %n' -- "$@"; }       # octal, symbolic, name

touch notes.txt secrets.env
echo 'echo "I ran"' > run.sh
mkdir shared

echo "--- defaults (this shell's umask is $(umask))"
show notes.txt run.sh shared

echo "--- symbolic mode: who (u g o a) + - = what (r w x)"
chmod u+x run.sh
chmod go-rwx secrets.env
show run.sh secrets.env

echo "--- octal mode: r=4 w=2 x=1, one digit each for user, group, other"
chmod 640 notes.txt            # rw- r-- ---
chmod 750 shared               # rwx r-x ---
show notes.txt shared

echo "--- the x bit on a script lets you run it by path"
./run.sh

echo "--- the x bit on a directory means 'may enter'"
chmod 600 shared
if ( cd shared ) 2>/dev/null; then
    echo "entered shared (are you root?)"
else
    echo "cannot enter a directory without x"
fi
chmod 750 shared

echo "--- umask removes bits from new files: 077 means private by default"
( umask 077; touch private.txt; mkdir private-dir; show private.txt private-dir )

echo "--- find world-writable files"
chmod o+w notes.txt
find . -type f -perm -o+w
```

**Expected output**

```text
--- defaults (this shell's umask is 0022)
644 -rw-r--r-- notes.txt
644 -rw-r--r-- run.sh
755 drwxr-xr-x shared
--- symbolic mode: who (u g o a) + - = what (r w x)
744 -rwxr--r-- run.sh
600 -rw------- secrets.env
--- octal mode: r=4 w=2 x=1, one digit each for user, group, other
640 -rw-r----- notes.txt
750 drwxr-x--- shared
--- the x bit on a script lets you run it by path
I ran
--- the x bit on a directory means 'may enter'
cannot enter a directory without x
--- umask removes bits from new files: 077 means private by default
600 -rw------- private.txt
700 drwx------ private-dir
--- find world-writable files
./notes.txt
./perms.sh
```

Notice `run.sh` went from `644` to `744` with only `u+x`, and that a directory without `x` cannot be
entered even by its owner.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `./deploy.sh`: Permission denied | No execute bit | `chmod u+x deploy.sh` (or run `bash deploy.sh`) |
| `chmod 600` on a directory | Without `x` you cannot enter it | Directories need `x`: `chmod 700 dir` |
| `chmod 777` to "fix" something | Anyone can now change the file | Add just the missing bit |
| `chmod -R 644 dir` | Strips `x` from subdirectories, making them unreachable | Use `find dir -type f -exec chmod 644 {} +` and the same for `-type d` with `755` |
| Setting the mode after writing a secret | There is a window where the file is readable | `umask 077` or `install -m 600` first |
| Editing as root, then wondering why a user cannot read | New files are owned by root | `chown` them back, or use `sudo -u user` |
| `ls -l` on a file you cannot reach | `stat` needs `x` on the directory | Check the directory modes, too |

## Exercises

### Easy: a private secrets file

In a temporary directory create `secrets.env` readable and writable only by you. Verify the mode with
`stat -c %a` and print `OK` when it is exactly `600`.

**Acceptance criteria**

- `stat -c %A secrets.env` shows `-rw-------`.
- The check is done by the script, not by eye.

### Medium: world-writable audit

Build a small tree `site/uploads/` in a temp directory with two files made world-writable (666),
one of them with a space in its name. List them, fix them with a single `find ... -exec chmod o-w {} +`,
and confirm the count of world-writable files is now 0.

**Acceptance criteria**

- Before: both files are listed, including `my file.txt` intact.
- After: `0 world-writable file(s)`.
- Group and owner bits are left as they were (`664`, not `600`).

### Hard: deployment tree with a mode table

Create `app/bin`, `app/conf`, `app/data` with `install -d -m`, plus `app/bin/run.sh` (750) and
`app/conf/app.env` (640). Declare the expected mode of each path in an associative array, then verify
each with `stat -c %a` and print `ok` or `WRONG` per path. Deliberately break one mode so you see a
failure. The script exits 1 when anything mismatches.

**Acceptance criteria**

- Output has one line per path, sorted by path.
- The broken file is reported as `WRONG ... 644 (want 640)`.
- Exit status is 1; with the mistake removed it is 0.

### Break it

This script has **three bugs**: it cannot run the deploy script, it cannot read the report, and it
sets an unsafe mode. Save as `break-it.sh`, run it, and fix it.

```bash
#!/usr/bin/env bash
echo 'echo "deploy ok"' > deploy.sh
./deploy.sh

mkdir -p reports
touch reports/q1.txt
chmod 600 reports
cat reports/q1.txt && echo "read q1.txt"

chmod 777 deploy.sh
stat -c '%a %n' deploy.sh
```

**Expected output**

```text
break-it.sh: line 3: ./deploy.sh: Permission denied
cat: reports/q1.txt: Permission denied
777 deploy.sh
```

<details>
<summary>Hint</summary>

Two of the three bugs are in the error messages; the third is in the last line of output. Which
digit in `777` is giving everyone write access?

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 13 easy: create a secrets file that only its owner can read and write.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"

touch secrets.env
chmod 600 secrets.env

mode="$(stat -c %a secrets.env)"
echo "secrets.env mode: ${mode}"
if [[ $mode == 600 ]]; then
    echo "OK: private to the owner"
fi
stat -c '%A' secrets.env

cd / && rm -rf -- "$work"
```

**Expected output**

```text
secrets.env mode: 600
OK: private to the owner
-rw-------
```

</details>

<details>
<summary>Medium</summary>

`-perm -o+w` matches files where the "others write" bit is set (the `-` means "at least these
bits"). `-exec ... {} +` batches many files into one `chmod` and handles spaces correctly.

```bash
#!/usr/bin/env bash
# Day 13 medium: audit a tree for world-writable files and fix them.
# Works on a temporary tree only.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"
mkdir -p site/uploads
touch site/index.html site/uploads/a.txt "site/uploads/my file.txt"
chmod 666 site/uploads/a.txt "site/uploads/my file.txt"

echo "Before:"
find site -type f -perm -o+w -print0 | sort -z | while IFS= read -r -d '' f; do
    echo "  world-writable: $f"
done

# -exec ... {} + passes many files to one chmod and handles odd names safely.
find site -type f -perm -o+w -exec chmod o-w {} +

echo "After: $(find site -type f -perm -o+w | wc -l) world-writable file(s)"
stat -c '%a %n' site/uploads/a.txt "site/uploads/my file.txt"

cd / && rm -rf -- "$work"
```

**Expected output**

```text
Before:
  world-writable: site/uploads/a.txt
  world-writable: site/uploads/my file.txt
After: 0 world-writable file(s)
664 site/uploads/a.txt
664 site/uploads/my file.txt
```

</details>

<details>
<summary>Hard</summary>

This script ends with `1 mismatch(es)` and exit status 1 on purpose, because the `chmod 644` line
plants the error. Delete that line to see it pass. `install -d -m` creates a directory with a mode in
one step, so there is no moment when it has the wrong one.

```bash
#!/usr/bin/env bash
# Day 13 hard: build a deployment tree with exact modes, then verify it against a table.
# Exit 0 if every mode matches, 1 otherwise. Temporary files only; no root needed.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"

declare -A expected=(
    [app/bin]=755
    [app/conf]=750
    [app/conf/app.env]=640
    [app/data]=700
    [app/bin/run.sh]=750
)

install -d -m 755 app/bin
install -d -m 750 app/conf
install -d -m 700 app/data
printf '#!/bin/sh\necho ok\n' | install -m 750 /dev/stdin app/bin/run.sh
echo 'SECRET=1' | install -m 640 /dev/stdin app/conf/app.env
chmod 644 app/conf/app.env            # introduce one deliberate mistake

bad=0
mapfile -t paths <<< "$(printf '%s\n' "${!expected[@]}" | sort)"
for path in "${paths[@]}"; do
    actual="$(stat -c %a -- "$path")"
    if [[ $actual == "${expected[$path]}" ]]; then
        printf 'ok     %-18s %s\n' "$path" "$actual"
    else
        printf 'WRONG  %-18s %s (want %s)\n' "$path" "$actual" "${expected[$path]}"
        bad=$(( bad + 1 ))
    fi
done

cd / && rm -rf -- "$work"
echo "${bad} mismatch(es)"
if (( bad > 0 )); then
    exit 1
fi
```

**Expected output**

```text
ok     app/bin            755
ok     app/bin/run.sh     750
ok     app/conf           750
WRONG  app/conf/app.env   644 (want 640)
ok     app/data           700
1 mismatch(es)
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `deploy.sh` has no execute bit, so `./deploy.sh` fails. Bug 2: `chmod 600` on a directory
removes `x`, so nothing inside can be reached. Bug 3: `chmod 777` is overkill and unsafe; `755` is
enough. This test runs as a normal user; as root some of these checks would not fail, because root
bypasses permission checks.

```bash
#!/usr/bin/env bash
# Fixed: give scripts the execute bit (not 777), and directories need x to be entered.
set -euo pipefail

echo 'echo "deploy ok"' > deploy.sh
chmod 755 deploy.sh
./deploy.sh

mkdir -p reports
touch reports/q1.txt
chmod 700 reports
cat reports/q1.txt && echo "read q1.txt"

stat -c '%a %n' deploy.sh
```

**Expected output**

```text
deploy ok
read q1.txt
755 deploy.sh
```

</details>

Solution files live in [`solutions/day-13/`](solutions/day-13/).

## Self-check

1. What mode is `rwxr-x---` in octal?
2. What does `x` mean on a directory?
3. Which umask gives new files mode `600`?
4. Why is `chmod -R 644 dir` usually a mistake?
5. What mode should an SSH private key have?

<details>
<summary>Answers</summary>

1. `750`.
2. Permission to enter it and access its contents by name.
3. `077` (files start at 666; removing 077 leaves 600).
4. It removes `x` from subdirectories, so you can no longer enter them.
5. `600` (or `400`); `ssh` ignores keys that others can read.

</details>

## Cheat sheet

| Command | Meaning |
|---------|---------|
| `ls -l`, `ls -ld dir` | Show modes (the second shows a directory itself) |
| `stat -c '%a %A %U:%G %n' f` | Mode, owner and name in one line |
| `chmod 755 f`, `chmod u+x f` | Set / adjust mode |
| `find . -type f -perm -o+w` | Find world-writable files |
| `find . -type d -exec chmod 755 {} +` | Fix directories only |
| `umask 077` | Private by default for this shell |
| `install -d -m 700 dir`, `install -m 600 src dst` | Create with the right mode at once |
| `chown user:group f` | Change owner (needs root) |
| `id`, `groups` | Who am I, which groups |

## Further reading

- [chmod(1) manual](https://man7.org/linux/man-pages/man1/chmod.1.html): every option of `chmod`,
  including `X` and special bits.
- [Greg's Wiki: Permissions](https://mywiki.wooledge.org/Permissions): common permission problems and
  their causes, explained plainly.

**Next:** [Day 14](day-14.md)
