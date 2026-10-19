# Day 04: Decisions, Tests and Exit Codes

> **Time:** ~50 min · **Level:** Beginner
> **Prerequisites:** [Day 03](day-03.md)

## Goal

By the end of this lesson you can:

- Branch with `if`/`elif`/`else` and `case` using `[[ ]]` and `(( ))`.
- Test files, strings and numbers correctly.
- Read, set and propagate exit codes, and explain what `&&` and `||` do.

## Concepts

### Exit codes

Every command ends with a number: **0 means success, anything else means failure**. `$?` holds
the code of the last command.

```bash
ls /etc >/dev/null
echo "$?"            # 0
ls /nonexistent 2>/dev/null
echo "$?"            # 2
```

Scripts end with the code of their last command, or with whatever you pass to `exit N`. Common
convention: `1` general error, `2` misuse, `126` not executable, `127` command not found, `130`
interrupted with Ctrl-C.

### `if` runs a command and looks at its code

```bash
if grep -q "root" /etc/passwd; then
    echo "found root"
fi
```

`[[ ... ]]` and `(( ... ))` are commands that return 0 for "true". Use `[[ ]]` for strings and
files and `(( ))` for numbers.

### `[[ ]]` tests

| Test | True when |
|------|-----------|
| `-f path` / `-d path` / `-e path` | regular file / directory / anything exists |
| `-r`, `-w`, `-x path` | readable / writable / executable |
| `-s path` | file exists and is not empty |
| `-z "$s"` / `-n "$s"` | string is empty / non-empty |
| `"$a" == "$b"`, `!=` | strings equal / different |
| `"$s" == pat*` | glob match (leave the pattern unquoted) |
| `a -eq b`, `-ne`, `-lt`, `-le`, `-gt`, `-ge` | integer comparison (or use `(( ))`) |
| `! test`, `t1 && t2`, `t1 \|\| t2` | not, and, or |

> [!WARNING]
> Prefer `[[ ]]` over the old `[ ]`. Inside `[ ]`, `>` is a **redirection** that creates a file, and
> an empty unquoted variable disappears and breaks the syntax. `[[ ]]` has neither problem.

### `(( ))` for numbers

```bash
n=7
if (( n > 5 && n % 2 == 1 )); then echo "big and odd"; fi
```

### `case` for many options

```bash
case "$answer" in
    y|Y|yes) echo "confirmed" ;;
    n|N|no)  echo "cancelled" ;;
    *)       echo "please answer yes or no" ;;
esac
```

### `&&` and `||`

`a && b` runs `b` only if `a` succeeded. `a || b` runs `b` only if `a` failed.

```bash
mkdir -p backup && echo "ready"
[[ -f config.ini ]] || echo "config.ini is missing"
```

Do not chain `a && b || c` as an if/else: if `b` fails, `c` runs too.

## Worked example

`check.sh` shows each tool in turn. Save it and run `bash check.sh` in an empty directory.

```bash
#!/usr/bin/env bash
# check.sh - conditionals, tests and exit codes
set -euo pipefail

usage=82
if (( usage >= 90 )); then
    echo "CRITICAL: disk at ${usage}%"
elif (( usage >= 75 )); then
    echo "WARNING: disk at ${usage}%"
else
    echo "OK: disk at ${usage}%"
fi

# File tests
if [[ -f /etc/os-release ]]; then
    echo "/etc/os-release is a regular file"
fi
if [[ ! -d /no/such/dir ]]; then
    echo "/no/such/dir does not exist"
fi

# String tests: [[ ]] needs no quotes on the left, and = does glob matching
answer="yes please"
if [[ $answer == y* ]]; then
    echo "starts with y"
fi

# case: match one value against several patterns
file="holiday.JPG"
case "${file,,}" in             # ${var,,} lowercases
    *.jpg|*.png) echo "$file is an image" ;;
    *.txt|*.md)  echo "$file is a document" ;;
    *)           echo "$file is something else" ;;
esac

# Exit codes: every command leaves one. 0 means success.
grep -q root /etc/passwd
echo "grep found root: exit status $?"
status=0
grep -q no-such-user-xyz /etc/passwd || status=$?
echo "grep for a missing user: exit status $status"

# && runs the next command only on success; || only on failure.
mkdir -p out && echo "out/ is ready"
[[ -e missing.txt ]] || echo "missing.txt is not there"
```

**Expected output**

```text
WARNING: disk at 82%
/etc/os-release is a regular file
/no/such/dir does not exist
starts with y
holiday.JPG is an image
grep found root: exit status 0
grep for a missing user: exit status 1
out/ is ready
missing.txt is not there
```

Note `|| status=$?`: under `set -e` a failing command would abort the script, but a command that is
part of an `||` list is allowed to fail, and we capture its code on the way.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `[ $n > 5 ]` | `>` is a redirect: creates a file named `5`, always true | `(( n > 5 ))` or `[[ $n -gt 5 ]]` |
| `[ $name == "x" ]` with empty `$name` | The test collapses to `[ == x ]`: syntax error | `[[ $name == "x" ]]` |
| `[[ $a = $b ]]` meaning "equal as text" | An unquoted right side is a pattern | Quote it: `[[ $a == "$b" ]]` |
| `if [[ $x == 5 ]]` for numbers | String comparison: `05` and `5` differ | `(( x == 5 ))` |
| `if [[ -f $file ]]` fails on names with spaces | Fine in `[[ ]]`, but not in `[ ]` | Use `[[ ]]` and quote elsewhere |
| `cmd && echo ok \|\| echo failed` | If `echo ok` fails, "failed" prints too | Use a real `if` |
| `if [ -f file ] then` | Missing `;` or newline before `then` | `if ...; then` |

## Exercises

### Easy: grade calculator

Given `score=73`, print `Score 73 is grade C` using `if/elif/else`: 90+ is A, 80+ is B, 70+ is C,
anything else F.

**Acceptance criteria**

- Changing `score` to 95, 85, 70 and 12 gives A, B, C and F.
- Uses `(( ))` for the numeric comparisons.

### Medium: file classifier

Given a file name in a variable, print its category: `images` (jpg, jpeg, png, gif), `documents`
(txt, md, pdf), `archives` (zip, tar, tar.gz, tgz), or `other`. It must treat `Holiday.JPG` and
`holiday.jpg` the same.

**Acceptance criteria**

- Uses a single `case` statement.
- `Holiday.JPG -> images`, `notes.MD -> documents`, `backup.tar.gz -> archives`, `a.exe -> other`.
- Lower-casing is done with `${file,,}`, not with an external command.

### Hard: disk-alert check

Write a read-only monitoring check for `/`. It reads usage from `df --output=pcent /`, then:
below 80 prints `OK:` and exits 0; 80-89 prints `WARNING:` and exits 1; 90 and above prints
`CRITICAL:` and exits 2. If the number cannot be read, print `UNKNOWN` on stderr and exit 3. Let the
variable `DISK_USAGE` override the real reading so you can test every branch.

**Acceptance criteria**

- `DISK_USAGE=42`, `85`, `95` and `abc` give exit codes 0, 1, 2 and 3 (check with `echo $?`).
- Messages contain the percentage and the threshold that was crossed.
- The script is strict-mode safe and does not use `[ ]`.

### Break it

This script has **two bugs** (plus a stray file it leaves behind). Save it as `break-it.sh`, run it
in an empty directory, run `ls`, and fix it.

```bash
#!/usr/bin/env bash
count=10
name=

if [ $count > 5 ]; then
    echo "count is big"
fi

if [ $name == "" ]; then
    echo "no name given"
fi
ls
```

**Expected output**

```text
count is big
break-it.sh: line 9: [: ==: unary operator expected
5
break-it.sh
```

<details>
<summary>Hint</summary>

Look at the file listing at the end. Where did a file named `5` come from?

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 04 easy: turn a score into a grade.
set -euo pipefail

score=73

if (( score >= 90 )); then
    grade="A"
elif (( score >= 80 )); then
    grade="B"
elif (( score >= 70 )); then
    grade="C"
else
    grade="F"
fi

echo "Score ${score} is grade ${grade}"
```

**Expected output**

```text
Score 73 is grade C
```

</details>

<details>
<summary>Medium</summary>

Patterns in `case` are globs, and `|` separates alternatives. Put the more specific pattern first if
two could match the same name.

```bash
#!/usr/bin/env bash
# Day 04 medium: classify a file name by its extension (case-insensitive).
set -euo pipefail

file="Holiday.JPG"

case "${file,,}" in
    *.jpg|*.jpeg|*.png|*.gif) category="images" ;;
    *.txt|*.md|*.pdf)         category="documents" ;;
    *.zip|*.tar|*.tar.gz|*.tgz) category="archives" ;;
    *)                        category="other" ;;
esac

echo "${file} -> ${category}"
```

**Expected output**

```text
Holiday.JPG -> images
```

</details>

<details>
<summary>Hard</summary>

The `case` guard replaces a regex test (regular expressions are Day 21): it rejects empty values and
anything containing a non-digit. The value shown depends on your disk. Try
`DISK_USAGE=95 bash hard.sh; echo $?`.

```bash
#!/usr/bin/env bash
# Day 04 hard: disk-alert check with monitoring-style exit codes.
# 0 = OK, 1 = WARNING, 2 = CRITICAL. Read-only: it only runs df.
# Override for testing:  DISK_USAGE=95 bash hard.sh
set -euo pipefail

warn=80
crit=90
usage="${DISK_USAGE:-$(df --output=pcent / | tail -n 1 | tr -dc '0-9')}"

case "$usage" in
    ''|*[!0-9]*)                      # empty, or contains a non-digit
        echo "UNKNOWN: could not read disk usage" >&2
        exit 3
        ;;
esac

if (( usage >= crit )); then
    echo "CRITICAL: / is ${usage}% full (limit ${crit}%)"
    exit 2
elif (( usage >= warn )); then
    echo "WARNING: / is ${usage}% full (limit ${warn}%)"
    exit 1
fi
echo "OK: / is ${usage}% full"
```

**Expected output**

```text
OK: / is 2% full
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `[ $count > 5 ]` redirected the output of `[` into a new file called `5`, which is why `ls`
shows it. The test is always "true". Bug 2: `$name` is empty, so `[ == "" ]` is a syntax error. Use
`(( count > 5 ))` and `[[ -z $name ]]`.

```bash
#!/usr/bin/env bash
# Fixed: [[ ]] does not treat > as a redirection and tolerates empty variables;
# (( )) compares numbers.
set -euo pipefail

count=10
name=

if (( count > 5 )); then
    echo "count is big"
fi

if [[ -z $name ]]; then
    echo "no name given"
fi
ls
```

**Expected output**

```text
count is big
no name given
break-it.fixed.sh
```

</details>

Solution files live in [`solutions/day-04/`](solutions/day-04/).

## Self-check

1. What exit code means success?
2. Which of `[ ]` and `[[ ]]` can safely contain an empty unquoted variable?
3. What does `a && b || c` do when `a` succeeds and `b` fails?
4. How do you test that a path exists and is a directory?
5. What is the `case` branch that catches everything else?

<details>
<summary>Answers</summary>

1. Zero.
2. `[[ ]]`.
3. It runs `c` as well, because `||` sees the failure of `b`.
4. `[[ -d "$path" ]]`.
5. `*)`.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `if cmd; then ... elif ...; else ...; fi` | Branch on a command's exit code |
| `[[ -f f ]]`, `[[ -d d ]]`, `[[ -z s ]]` | File and string tests |
| `(( n > 5 ))` | Numeric test |
| `case $x in a\|b) ...;; *) ...;; esac` | Multi-way match |
| `cmd1 && cmd2`, `cmd1 \|\| cmd2` | Run on success / failure |
| `$?` | Exit code of the last command |
| `exit N` | End the script with code N |
| `${var,,}`, `${var^^}` | Lowercase, uppercase |

## Further reading

- [Greg's Wiki: BashFAQ/031](https://mywiki.wooledge.org/BashFAQ/031): the differences between
  `[`, `[[` and `test`, with all the portability caveats.
- [Greg's Wiki: Exit Status](https://mywiki.wooledge.org/BashGuide/TestsAndConditionals#Exit_Status-1): which exit codes mean what.

**Next:** [Day 05](day-05.md)
