# Day 06: Functions and Return Codes

> **Time:** ~55 min · **Level:** Beginner
> **Prerequisites:** [Day 05](day-05.md)

## Goal

By the end of this lesson you can:

- Define functions that take arguments and keep their variables `local`.
- Choose correctly between returning a **status** (`return`) and returning **data** (`echo`).
- Write small helpers (`log`, `require`, `retry`) that you can reuse in later scripts.

## Concepts

### Defining and calling

```bash
greet() {
    echo "Hello, $1!"
}
greet "Ada"
```

Define a function before you call it. Arguments arrive as `$1`, `$2`, ... exactly as for a script;
`$#` is the count and `"$@"` is all of them, individually quoted. (Day 16 covers script arguments
in depth.)

### `local`: keep variables private

Without `local`, a function's variables are global and will overwrite the caller's.

```bash
f() { local x="inside"; y="leaked"; }
x="outside"; f
echo "$x $y"      # outside leaked
```

### Two ways to give something back

| You want to return | Use | Caller reads it with |
|--------------------|-----|----------------------|
| A **status** (did it work?) | `return 0` / `return 1` | `if func; then`, `func \|\| ...`, `$?` |
| **Data** (a string or number) | `echo` / `printf` | `result="$(func)"` |

`return` only carries 0-255 and is meant for status. A non-zero `return` also trips `set -e`.

### Exit status of a function

A function's status is the status of its last command, or of the `return` that ended it. That is
why `is_even() { (( $1 % 2 == 0 )); }` works directly inside an `if`.

### Logging to stderr

Anything a function prints to stdout is captured by `$(...)`. Log and error messages belong on
stderr: `echo "message" >&2`.

### Inspecting functions

```bash
declare -f greet     # print a function's definition
unset -f greet       # remove it
```

## Worked example

Save as `funcs.sh` and run it.

```bash
#!/usr/bin/env bash
# funcs.sh - functions, arguments, local variables, return codes
set -euo pipefail

# A function that prints a result: callers capture it with $( ).
square() {
    local n="$1"                       # local keeps n from leaking out
    echo $(( n * n ))
}

# A function that reports success/failure through its return code.
is_even() {
    (( $1 % 2 == 0 ))                  # the exit status of (( )) becomes the function's
}

# Logging goes to stderr so it never pollutes captured output.
log() {
    echo "[log] $*" >&2
}

# A guard for required tools; return 1 when something is missing.
require() {
    local tool
    for tool in "$@"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log "missing tool: $tool"
            return 1
        fi
    done
}

result="$(square 7)"
echo "7 squared is $result"

for n in 3 4; do
    if is_even "$n"; then
        echo "$n is even"
    else
        echo "$n is odd"
    fi
done

n=100
square 5 >/dev/null
echo "global n is still $n"            # square's local n did not touch it

require bash sed && echo "bash and sed are installed"
require bash no-such-tool || echo "require returned $?"
```

**Expected output**

```text
7 squared is 49
3 is odd
4 is even
global n is still 100
bash and sed are installed
[log] missing tool: no-such-tool
require returned 1
```

`require bash sed && echo ...` only prints when every tool exists. Notice that `[log] missing tool`
went to stderr and the status came back as `1` for the caller to decide what to do.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `return "$total"` for a value | Only 0-255, and non-zero aborts under `set -e` | `echo "$total"` and capture with `$(...)` |
| Forgetting `local` | Overwrites the caller's variable of the same name | `local i total` at the top of the function |
| `local x=$(cmd)` | `local` hides the exit status of `cmd` | `local x; x="$(cmd)"` |
| Calling a function before its definition | Bash reads top to bottom: "command not found" | Define first, call afterwards |
| Logging with `echo` inside a value-returning function | The log line is captured into the result | `echo ... >&2` |
| `function f() { ...}` mixed styles | Not portable and inconsistent | Use `f() { ...; }` |
| `f $1 $2` | Unquoted: spaces break the arguments | `f "$1" "$2"` |

## Exercises

### Easy: greet with a default

Write `greet` that prints `Hello, <name>!` and uses `friend` when called without an argument. Call
it twice: with `Ada` and with nothing.

**Acceptance criteria**

- Output is `Hello, Ada!` then `Hello, friend!`.
- The name is stored in a `local` variable.

### Medium: size helper

Write `file_size_mb file` that **prints** the size in whole megabytes, and `require_file file` that
**returns** 1 with an error on stderr if the path is not a regular file. In a scratch directory
create a 3 MB file (`head -c 3145728 /dev/zero > big.bin`), check it, print its size, then check a
missing file and report the failure.

**Acceptance criteria**

- Prints `big.bin is 3 MB`.
- For the missing file the script prints the error from `require_file` plus its own message and
  still exits 0.
- The size is captured with `$(...)`, not through a global variable.

### Hard: reusable retry

Write `retry MAX DELAY command [args...]` that runs the command until it succeeds, sleeping `DELAY`
seconds between attempts and giving up (returning 1) after `MAX` attempts. Log progress to stderr.
Test it with a function `flaky` that fails twice then succeeds (keep the call counter in a temp
file, because a command in `$( )` or a subshell cannot update a variable for you).

**Acceptance criteria**

- `retry 5 0 flaky` succeeds on the 3rd attempt.
- `retry 2 0 flaky` gives up and returns 1.
- The function works with any command, including ones whose arguments contain spaces.

### Break it

This script has **two bugs**: it prints a wrong result and it stops early with no error message.
Save it as `break-it.sh`, run it, check `echo $?`, and fix it.

```bash
#!/usr/bin/env bash
set -euo pipefail

total=100

sum_to() {
    total=0
    for i in $(seq 1 "$1"); do
        total=$(( total + i ))
    done
    return "$total"
}

echo "starting with total=$total"
sum_to 3
echo "sum of 1..3 is $total"
echo "done"
```

**Expected output**

```text
starting with total=100
```

<details>
<summary>Hint</summary>

The script ends after `sum_to 3` and the exit status is 6. Why did the function's `return` stop the
script, and what happened to `total=100`?

</details>

## Solutions

<details>
<summary>Easy</summary>

`${1:-friend}` is the default-value expansion from Day 3.

```bash
#!/usr/bin/env bash
# Day 06 easy: a greet function with a default argument.
set -euo pipefail

greet() {
    local name="${1:-friend}"
    echo "Hello, ${name}!"
}

greet "Ada"
greet
```

**Expected output**

```text
Hello, Ada!
Hello, friend!
```

</details>

<details>
<summary>Medium</summary>

`file_size_mb` hands data back with `echo`; `require_file` hands a status back with `return`. Because
`require_file` is used as an `if` condition, `set -e` does not abort on its failure.

```bash
#!/usr/bin/env bash
# Day 06 medium: file_size_mb prints a value; require_file returns a status.
set -euo pipefail

file_size_mb() {
    local bytes
    bytes="$(stat -c %s -- "$1")"
    echo $(( bytes / 1024 / 1024 ))
}

require_file() {
    if [[ ! -f $1 ]]; then
        echo "error: $1 is not a file" >&2
        return 1
    fi
}

work="$(mktemp -d)"
head -c 3145728 /dev/zero > "$work/big.bin"          # 3 MiB

require_file "$work/big.bin"
size="$(file_size_mb "$work/big.bin")"
echo "big.bin is ${size} MB"

if ! require_file "$work/missing.bin"; then
    echo "missing.bin check failed as expected"
fi

rm -rf -- "$work"
```

**Expected output**

```text
big.bin is 3 MB
error: /tmp/tmp.G3hcAy6rrZ/missing.bin is not a file
missing.bin check failed as expected
```

</details>

<details>
<summary>Hard</summary>

`until "$@"` runs the command with its arguments intact. The `[retry]` lines go to stderr, so they
appear in your terminal while stdout stays clean.

```bash
#!/usr/bin/env bash
# Day 06 hard: a reusable retry function, tested with a flaky command.
# Safe: only touches a temporary directory.
set -euo pipefail

log() { echo "[retry] $*" >&2; }

# retry MAX_ATTEMPTS DELAY_SECONDS COMMAND [ARGS...]
retry() {
    local max="$1" delay="$2" attempt=1
    shift 2
    until "$@"; do
        if (( attempt >= max )); then
            log "giving up after ${attempt} attempts: $*"
            return 1
        fi
        log "attempt ${attempt} failed, retrying in ${delay}s"
        sleep "$delay"
        attempt=$(( attempt + 1 ))
    done
    log "succeeded on attempt ${attempt}"
}

work="$(mktemp -d)"
echo 0 > "$work/calls"

# Fails twice, then succeeds.
flaky() {
    local calls
    calls="$(< "$work/calls")"
    calls=$(( calls + 1 ))
    echo "$calls" > "$work/calls"
    (( calls >= 3 ))
}

retry 5 0 flaky && echo "flaky command worked"
echo 0 > "$work/calls"
retry 2 0 flaky || echo "retry reported failure with only 2 attempts"

rm -rf -- "$work"
```

**Expected output**

```text
[retry] attempt 1 failed, retrying in 0s
[retry] attempt 2 failed, retrying in 0s
[retry] succeeded on attempt 3
flaky command worked
[retry] attempt 1 failed, retrying in 0s
[retry] giving up after 2 attempts: flaky
retry reported failure with only 2 attempts
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `total` and `i` were global, so the function overwrote the caller's `total=100`. Bug 2: it
used `return "$total"`, so the function exited with status 6, which `set -e` treats as a failure and
ends the script silently. Use `local` variables and `echo` the result.

```bash
#!/usr/bin/env bash
# Fixed: locals do not leak, and the result travels through stdout, not through return.
# (return carries only a status 0-255, and a non-zero status aborts the script under set -e.)
set -euo pipefail

total=100

sum_to() {
    local sum=0 i
    for (( i = 1; i <= $1; i++ )); do
        sum=$(( sum + i ))
    done
    echo "$sum"
}

echo "starting with total=$total"
result="$(sum_to 3)"
echo "sum of 1..3 is $result"
echo "total is still $total"
echo "done"
```

**Expected output**

```text
starting with total=100
sum of 1..3 is 6
total is still 100
done
```

</details>

Solution files live in [`solutions/day-06/`](solutions/day-06/).

## Self-check

1. What does `local` do?
2. How do you get a string out of a function?
3. What is the exit status of a function with no `return`?
4. Why should logging inside a function go to stderr?
5. What is wrong with `local out=$(some_command)`?

<details>
<summary>Answers</summary>

1. It limits a variable to the function (and its callees), so it cannot clobber a global.
2. Print it with `echo`/`printf` and capture it: `x="$(func)"`.
3. The status of the last command it ran.
4. Stdout is what `$(...)` captures; logs on stdout would pollute the result.
5. `local` succeeds, hiding the failure of `some_command`; declare first, then assign.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `name() { ...; }` | Define a function |
| `"$1"`, `"$@"`, `$#` | Arguments, all arguments, count |
| `local v` | Function-private variable |
| `return N` | Finish with status N |
| `echo x` + `$(f)` | Pass data back |
| `if f; then` | Branch on status |
| `echo msg >&2` | Log to stderr |
| `declare -f f` | Show a function's source |

## Further reading

- [Greg's Wiki: BashGuide/Functions](https://mywiki.wooledge.org/BashGuide/CompoundCommands):
  compound commands and functions explained for beginners.
- [Greg's Wiki: BashFAQ/084](https://mywiki.wooledge.org/BashFAQ/084): how to return a string from a
  function, with the alternatives to `echo`.

**Next:** [Day 07](day-07.md)
