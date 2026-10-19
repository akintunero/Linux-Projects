# Day 03: Variables, Quoting and Strict Mode

> **Time:** ~50 min · **Level:** Beginner
> **Prerequisites:** [Day 02](day-02.md)

## Goal

By the end of this lesson you can:

- Create variables, read them safely with quotes, and capture command output with `$(...)`.
- Do integer arithmetic with `$(( ))`.
- Start every script with `set -euo pipefail` and explain what each option protects you from.

## Concepts

### Variables

```bash
city="London"      # no spaces around =
echo "I live in $city"
echo "I live in ${city}shire"    # braces mark where the name ends
```

Bash has no types: every variable is a string, and numbers are interpreted as numbers only in
arithmetic. Names use letters, digits and `_`, and cannot start with a digit. By convention,
variables you invent are `lower_case` and exported environment variables are `UPPER_CASE`.

### Quoting: the most important habit

| Form | What happens |
|------|--------------|
| `"$var"` | Variable expanded; value kept as **one** word |
| `'$var'` | Nothing expanded: literal text |
| `$var` (no quotes) | Value is split on spaces and globs are expanded |

```bash
file="my report.txt"
touch "$file"            # correct: one argument
ls -l $file              # wrong: two arguments, "my" and "report.txt"
```

**Rule: quote every `$variable` and `$(command)` unless you know why you should not.**

### Command substitution

`$(command)` runs the command and substitutes its output (trailing newlines removed):

```bash
today="$(date +%F)"
echo "Backup for $today"
```

### Arithmetic

`$(( ))` computes with integers and drops the decimals. Inside it you do not need `$` on names.

```bash
echo $(( 7 / 2 ))     # 3, not 3.5
echo $(( 7 % 2 ))     # 1, the remainder
echo $(( 2 ** 10 ))   # 1024
```

For decimals use `bc` or `awk` (Day 12).

### Defaults and required values

```bash
echo "${EDITOR:-nano}"           # use $EDITOR, or "nano" if unset or empty
: "${API_URL:?API_URL is required}"   # abort with a message if unset or empty
```

### Strict mode

Put this at the top of every script from now on:

```bash
set -euo pipefail
```

| Option | Protects you from |
|--------|-------------------|
| `-e` | Carrying on after a command fails |
| `-u` | A typo in a variable name silently becoming an empty string |
| `-o pipefail` | A pipeline hiding a failure in an early stage (`bad_cmd \| sort` is a success without it) |

> [!NOTE]
> `-e` has exceptions: it does not trigger inside `if` conditions, `&&`/`||` lists or `while`
> conditions. Day 15 covers this properly. Strict mode reduces damage; it is not a substitute for
> checking the commands that matter.

### Readonly and constants

```bash
readonly MAX_RETRIES=3
MAX_RETRIES=4          # error: readonly variable
```

## Worked example

Save as `vars.sh` and run `bash vars.sh` in an empty directory.

```bash
#!/usr/bin/env bash
# vars.sh - variables, quoting, substitution, arithmetic, strict mode
set -euo pipefail

name="Ada Lovelace"
count=3
echo "Hello, $name. You have $count new messages."
echo 'Single quotes keep $name literal.'

# Command substitution: capture a command's output in a variable.
touch "report 1.txt" "report 2.txt"
files=$(ls | wc -l)
echo "Files here: $files"

# Arithmetic: $(( )) does integer math only.
total=$(( count * 5 + 2 ))
echo "total=$total, half=$(( total / 2 )), remainder=$(( total % 2 ))"

# A value with spaces must be quoted when you USE it too.
file="report 1.txt"
wc -c < "$file"

# Defaults for variables that may be unset.
echo "Editor: ${EDITOR:-nano}"

# Why set -u matters: a typo becomes an error instead of an empty string.
( echo "Value: $nmae" ) || echo "caught the typo (exit status $?)"
echo "still running"
```

**Expected output**

```text
Hello, Ada Lovelace. You have 3 new messages.
Single quotes keep $name literal.
Files here: 3
total=17, half=8, remainder=1
0
Editor: nano
vars.sh: line 27: nmae: unbound variable
caught the typo (exit status 1)
still running
```

The last two commands show strict mode at work: `$nmae` is a typo, so Bash stops that subshell
with an error instead of printing an empty value. `wc -c < "$file"` counts the bytes in the file;
`touch` created it empty, so it prints `0`.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `name=Ada Lovelace` | Bash runs `Lovelace` with `name=Ada` in its environment | `name="Ada Lovelace"` |
| `echo '$name'` | Single quotes disable expansion | `echo "$name"` |
| `total=$a+$b` | Concatenates strings: `3+4` | `total=$(( a + b ))` |
| `echo $(( 10 / 4 ))` expecting 2.5 | Integer division | Use `bc` or `awk` |
| `((i++))` under `set -e` | `((expr))` returns 1 when the result is 0, which aborts the script | `i=$(( i + 1 ))` |
| `set -u` and `$1` unset | An unset positional parameter is an error | `"${1:-}"` or `"${1:?usage: ...}"` |
| `rm -rf "$dir"/*` with `dir` empty | Becomes `rm -rf /*` | `"${dir:?}"/*` |

## Exercises

### Easy: greeting card

Store a name, a city and an age in variables. Print `Ada from London is 36; 64 years to go.` where
the last number is computed as `100 - age`.

**Acceptance criteria**

- Script starts with `set -euo pipefail`.
- Changing only the three variables changes the whole sentence correctly.
- Every expansion is quoted or in braces within a quoted string.

### Medium: disk report

Given `used_kb=45678` and `total_kb=102400`, print `Used: 44 MB of 100 MB (44%)` and the free
space in MB. Beware integer division: compute the percentage as `used * 100 / total`, not
`used / total * 100`.

**Acceptance criteria**

- Output matches the sample line exactly for the sample numbers.
- Setting `used_kb=0` still works and prints `0%`.
- No `bc` or `awk` is needed.

### Hard: release tag and backup name

Starting from `major=2 minor=7 patch=9`, compute the next patch release and print `Next tag:
v2.7.10`. Build a backup file name `backup-<short hostname>-<YYYY-MM-DD>.tar.gz` using command
substitution, then verify its shape with a glob test in `[[ ]]`. Finally, show a required variable
`DEPLOY_DIR` being checked with `${DEPLOY_DIR:?...}` inside a subshell so the script can print a
friendly refusal and keep going.

**Acceptance criteria**

- Prints `Next tag: v2.7.10` without using `((patch++))`.
- The backup name test passes on any machine.
- With `DEPLOY_DIR` unset the script reports the refusal; with it set (`DEPLOY_DIR=/srv bash
  hard.sh`) it does not.

### Break it

This script has **three bugs**. Save it as `break-it.sh`, run it, and fix it. Add strict mode too.

```bash
#!/usr/bin/env bash
name=Ada Lovelace
count=4
echo '$name has $count files'
total=$count+1
echo "next: $total"
```

**Expected output**

```text
break-it.sh: line 2: Lovelace: command not found
$name has $count files
next: 4+1
```

<details>
<summary>Hint</summary>

The first error message is about a different word than the one you think is wrong. For the other
two bugs, compare the printed text with what you meant to print.

</details>

## Solutions

<details>
<summary>Easy</summary>

Braces after a variable are optional here but clearly mark where each name ends.

```bash
#!/usr/bin/env bash
# Day 03 easy: greeting card with variables and arithmetic.
set -euo pipefail

name="Ada"
city="London"
age=36
to_go=$(( 100 - age ))

echo "${name} from ${city} is ${age}; ${to_go} years to go."
```

**Expected output**

```text
Ada from London is 36; 64 years to go.
```

</details>

<details>
<summary>Medium</summary>

Integer division truncates, so multiplying by 100 *before* dividing keeps the precision we need.

```bash
#!/usr/bin/env bash
# Day 03 medium: format a disk report from raw kilobyte numbers.
set -euo pipefail

used_kb=45678
total_kb=102400

used_mb=$(( used_kb / 1024 ))
total_mb=$(( total_kb / 1024 ))
percent=$(( used_kb * 100 / total_kb ))   # multiply first, or integer division gives 0
free_mb=$(( total_mb - used_mb ))

echo "Used: ${used_mb} MB of ${total_mb} MB (${percent}%)"
echo "Free: ${free_mb} MB"
```

**Expected output**

```text
Used: 44 MB of 100 MB (44%)
Free: 56 MB
```

</details>

<details>
<summary>Hard</summary>

`: "${DEPLOY_DIR:?...}"` uses the no-op `:` command purely so Bash evaluates the expansion. In a
subshell `( ... )` the failure only ends the subshell, so the `||` branch runs and the script goes
on. This prints a different hostname and date on your machine; only the shape is fixed.

```bash
#!/usr/bin/env bash
# Day 03 hard: build a release tag and a backup file name under strict mode.
set -euo pipefail

major=2
minor=7
patch=9

patch=$(( patch + 1 ))               # not ((patch++)): it returns 1 when the old value is 0
tag="v${major}.${minor}.${patch}"
echo "Next tag: ${tag}"

host="$(hostname -s)"
stamp="$(date +%F)"
backup="backup-${host}-${stamp}.tar.gz"
if [[ $backup == backup-*-????-??-??.tar.gz ]]; then
    echo "Backup name has the expected shape"
fi

# ${VAR:?message} aborts with a message when VAR is unset or empty.
( : "${DEPLOY_DIR:?DEPLOY_DIR must be set}" ) 2>&1 || echo "refused to continue without DEPLOY_DIR"
```

**Expected output**

```text
Next tag: v2.7.10
Backup name has the expected shape
hard.sh: line 21: DEPLOY_DIR: DEPLOY_DIR must be set
refused to continue without DEPLOY_DIR
```

</details>

<details>
<summary>Break it</summary>

Bug 1: unquoted `Ada Lovelace` made Bash run `Lovelace` as a command. Bug 2: single quotes stopped
expansion. Bug 3: `$count+1` is string concatenation, not arithmetic.

```bash
#!/usr/bin/env bash
# Fixed: quote the value, use double quotes to expand, and use $(( )) for math.
set -euo pipefail

name="Ada Lovelace"
count=4
echo "$name has $count files"
total=$(( count + 1 ))
echo "next: $total"
```

**Expected output**

```text
Ada Lovelace has 4 files
next: 5
```

</details>

Solution files live in [`solutions/day-03/`](solutions/day-03/).

## Self-check

1. What is the difference between `'$x'` and `"$x"`?
2. What does `echo $(( 9 / 2 ))` print?
3. Which `set` option turns an unset-variable typo into an error?
4. Why is `bad_command | sort` a success without `pipefail`?
5. What does `${name:-guest}` do?

<details>
<summary>Answers</summary>

1. Single quotes print the text `$x`; double quotes substitute the variable's value.
2. `4` (integer division).
3. `set -u` (part of `set -euo pipefail`).
4. A pipeline's status is that of its last command (`sort`), and `sort` succeeded.
5. It expands to the value of `name`, or `guest` if `name` is unset or empty.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `var="value"` | Assign |
| `"$var"`, `"${var}"` | Read, quoted |
| `$(cmd)` | Capture command output |
| `$(( a + b ))` | Integer arithmetic |
| `${var:-default}` | Default if unset or empty |
| `${var:?message}` | Abort if unset or empty |
| `readonly NAME=value` | Constant |
| `set -euo pipefail` | Strict mode |
| `'text'` / `"text"` | Literal / expanding quotes |

## Further reading

- [Greg's Wiki: Quotes](https://mywiki.wooledge.org/Quotes): the clearest explanation of when and why
  to quote.
- [ShellCheck SC2086](https://www.shellcheck.net/wiki/SC2086): the warning for unquoted variables,
  with examples of what goes wrong.
- [Greg's Wiki: BashFAQ/105](https://mywiki.wooledge.org/BashFAQ/105): why `set -e` behaves
  surprisingly and when not to rely on it.

**Next:** [Day 04](day-04.md)
