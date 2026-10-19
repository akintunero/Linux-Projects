# Day 14: Debugging Scripts

> **Time:** ~55 min · **Level:** Intermediate
> **Prerequisites:** [Day 13](day-13.md)

## Goal

By the end of this lesson you can:

- Check a script for syntax errors without running it (`bash -n`) and trace it while running (`set -x`).
- Customise the trace prefix with `PS4` and send it to its own file.
- Add a switchable `debug` helper and recognise a handful of classic bugs on sight.

## Concepts

### Step 0: read the error message

Bash tells you the script name, the line number and what it did not understand:

```text
break-it.sh: line 7: syntax error near unexpected token `fi'
```

The reported line is where Bash *noticed* the problem. The mistake is often a line or two earlier
(a missing `then`, `done` or closing quote).

### Check without running: `bash -n`

```bash
bash -n script.sh      # parse only; prints errors, runs nothing
```

### Trace while running: `set -x`

```bash
bash -x script.sh      # trace the whole script
set -x                 # ...or turn it on in a region
risky_command
set +x                 # ...and off again
```

Each command is printed after expansion, prefixed with `+` (one `+` per subshell nesting level).
`set -v` prints lines as they are read, before expansion.

### Make the trace readable with `PS4`

```bash
PS4='+ ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '
```

You now see file, line number and function for every command. To keep stdout clean, send the
trace to a file: `exec 5>trace.log; BASH_XTRACEFD=5`.

### Your own switch

A `debug` function gated on an environment variable stays in the script forever and costs nothing:
`DEBUG=1 ./script.sh`. Log to stderr so captured output is not polluted.

### Inspecting data

| Tool | Shows |
|------|-------|
| `declare -p var` | Exact value, type (string, array), flags |
| `printf '%q\n' "$s"` | The string quoted so hidden characters are visible |
| `echo "[$var]"` | Leading and trailing whitespace |
| `type -a cmd` | Which `cmd` will actually run |

### ShellCheck: a second pair of eyes

[ShellCheck](https://www.shellcheck.net/) is a linter that catches unquoted variables, bad tests and
portability mistakes. Install it with your package manager (`apt install shellcheck`,
`brew install shellcheck`) and run `shellcheck script.sh`. Paste any script into the website to try it
without installing. Every warning has a wiki page (`SC2086` and so on) explaining the fix.

## Worked example

One script, four views of the same function. Save it as `debug.sh`.

```bash
#!/usr/bin/env bash
# debug.sh - three ways to see what a script is doing
set -euo pipefail

# A debug helper controlled by an environment variable.
debug() {
    if [[ ${DEBUG:-0} == 1 ]]; then
        echo "[debug] $*" >&2
    fi
    return 0
}

total_size() {
    local dir="$1" sum=0 f
    for f in "$dir"/*; do
        debug "checking $f"
        sum=$(( sum + $(stat -c %s -- "$f") ))
    done
    echo "$sum"
}

mkdir data
printf 'aaaa' > data/a.txt
printf 'bb'   > data/b.txt

echo "--- 1. normal run"
total_size data

echo "--- 2. DEBUG=1 turns on our own messages"
DEBUG=1 total_size data

echo "--- 3. set -x traces every command; PS4 controls the prefix"
PS4='+ ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '
set -x
total_size data
set +x

echo "--- 4. inspect a variable's exact value and type"
declare -p PS4
```

**Expected output**

```text
--- 1. normal run
6
--- 2. DEBUG=1 turns on our own messages
[debug] checking data/a.txt
[debug] checking data/b.txt
6
--- 3. set -x traces every command; PS4 controls the prefix
+ debug.sh:35:main: total_size data
+ debug.sh:14:total_size: local dir=data sum=0 f
+ debug.sh:15:total_size: for f in "$dir"/*
+ debug.sh:16:total_size: debug 'checking data/a.txt'
+ debug.sh:7:debug: [[ 0 == 1 ]]
+ debug.sh:10:debug: return 0
++ debug.sh:17:total_size: stat -c %s -- data/a.txt
+ debug.sh:17:total_size: sum=4
+ debug.sh:15:total_size: for f in "$dir"/*
+ debug.sh:16:total_size: debug 'checking data/b.txt'
+ debug.sh:7:debug: [[ 0 == 1 ]]
+ debug.sh:10:debug: return 0
++ debug.sh:17:total_size: stat -c %s -- data/b.txt
+ debug.sh:17:total_size: sum=6
+ debug.sh:19:total_size: echo 6
6
+ debug.sh:36:main: set +x
--- 4. inspect a variable's exact value and type
declare -- PS4="+ \${BASH_SOURCE##*/}:\${LINENO}:\${FUNCNAME[0]:-main}: "
```

In view 3, `++` marks commands run inside `$( )` (a subshell). Read the trace top to bottom: it is
exactly what Bash executed, with all variables already expanded.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| Staring at the code instead of tracing | You see what you meant, not what runs | `bash -x script.sh` |
| `set -x` and leaving it on | Secrets in commands end up in logs | `set +x` after the region; never trace code that handles passwords |
| Debug output on stdout | It becomes part of a function's "result" | `echo ... >&2` |
| Debug helper returns non-zero when off | Under `set -e` the script stops | End the function with `return 0` |
| Loop `while read line` drops the last line | The final line has no newline, so `read` returns 1 | `while IFS= read -r l \|\| [[ -n $l ]]` |
| Editing the wrong copy of a script | `PATH` finds another one first | `type -a script` |
| Assuming the error line is the bad line | Bash reports where parsing failed | Look at the 2-3 lines above it |

## Exercises

### Easy: a debug switch

Write a `debug` function that prints `[debug] message` to **stderr** only when `DEBUG=1`. Use it to
log a start message and a counter value. Run the script normally, then with `DEBUG=1`.

**Acceptance criteria**

- Without `DEBUG`, only `processed 3 items` appears.
- With `DEBUG=1 bash script.sh`, the `[debug]` lines also appear.
- The helper never makes the script fail under `set -e`.

### Medium: the missing last line

A file has the numbers `10`, `20`, `30` but no final newline. A `while read` loop that sums them
reports 30. Reproduce the bug, fix it, and trace one `read` with `set -x` and a `PS4` that prints
the line number.

**Acceptance criteria**

- Buggy loop prints `sum = 30 (expected 60)`; fixed loop prints `sum = 60`.
- The fix keeps `IFS=` and `-r`.
- The trace lines start with `+ line N:`.

### Hard: trace to a file

Send the xtrace of a small script with a function to a separate file using `BASH_XTRACEFD` and a
`PS4` that contains the function name. Show that stdout is clean, print the first six trace lines
and count the lines that mention the function.

**Acceptance criteria**

- Nothing from the trace appears on the terminal.
- Trace lines look like `+ hard.sh:15:greet: echo 'hello, Ada'`.
- File descriptor 5 is closed at the end (`exec 5>&-`).

### Break it

This script has **two bugs** that show up one at a time. Save as `break-it.sh`. Use `bash -n` to
find the first and `bash -x` (or the error message) to find the second.

```bash
#!/usr/bin/env bash
set -euo pipefail

name="report"
if [[ -n $name ]]
    echo "have a name"
fi
echo "Total: $totl"
```

**Expected output**

```text
break-it.sh: line 7: syntax error near unexpected token `fi'
```

<details>
<summary>Hint</summary>

Bash complains about `fi`, but what is missing is on the line with `if`. After fixing that, run the
script again and read the error: it names the exact variable.

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 14 easy: a debug() helper switched on by DEBUG=1.
# Try:  bash easy.sh      and      DEBUG=1 bash easy.sh
set -euo pipefail

debug() {
    if [[ ${DEBUG:-0} == 1 ]]; then
        echo "[debug] $*" >&2
    fi
    return 0
}

debug "starting up"
count=3
debug "count is ${count}"
echo "processed ${count} items"
```

**Expected output**

```text
processed 3 items
```

</details>

<details>
<summary>Medium</summary>

When the last line has no newline, `read` fills `line` but returns 1 (end of file). The loop
condition `|| [[ -n $line ]]` keeps going while `line` still holds data.

```bash
#!/usr/bin/env bash
# Day 14 medium: the classic "last line has no newline" bug, found and fixed.
set -euo pipefail

work="$(mktemp -d)"
printf '10\n20\n30' > "$work/numbers.txt"      # note: no newline after 30

echo "--- buggy loop"
sum=0
while IFS= read -r line; do
    sum=$(( sum + line ))
done < "$work/numbers.txt"
echo "sum = ${sum} (expected 60)"

echo "--- fixed loop: read returns non-zero on the final unterminated line, but still fills 'line'"
sum=0
while IFS= read -r line || [[ -n $line ]]; do
    sum=$(( sum + line ))
done < "$work/numbers.txt"
echo "sum = ${sum}"

echo "--- tracing the read with set -x and a line-number prefix"
PS4='+ line ${LINENO}: '
set -x
line=""
IFS= read -r line < "$work/numbers.txt"
set +x

rm -rf -- "$work"
```

**Expected output**

```text
--- buggy loop
sum = 30 (expected 60)
--- fixed loop: read returns non-zero on the final unterminated line, but still fills 'line'
sum = 60
--- tracing the read with set -x and a line-number prefix
+ line 25: line=
+ line 26: IFS=
+ line 26: read -r line
+ line 27: set +x
```

</details>

<details>
<summary>Hard</summary>

`BASH_XTRACEFD` tells Bash which file descriptor receives the trace. `++` lines come from the command
substitution (a subshell).

```bash
#!/usr/bin/env bash
# Day 14 hard: send the xtrace to its own file so normal output stays clean.
# Temporary files only.
set -euo pipefail

work="$(mktemp -d)"
trace="${work}/trace.log"

exec 5> "$trace"                         # open file descriptor 5 for writing
BASH_XTRACEFD=5                          # xtrace now goes to fd 5, not stderr
PS4='+ ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '

greet() {
    local who="$1"
    echo "hello, ${who}"
}

set -x
greet "Ada"
result="$(greet "Grace")"
set +x

echo "stdout stayed clean: ${result}"
echo "--- first lines of the trace file"
head -n 6 "$trace"
echo "--- trace lines mentioning greet: $(grep -c 'greet' "$trace")"

exec 5>&-                                # close fd 5
rm -rf -- "$work"
```

**Expected output**

```text
hello, Ada
stdout stayed clean: hello, Grace
--- first lines of the trace file
+ hard.sh:19:main: greet Ada
+ hard.sh:14:greet: local who=Ada
+ hard.sh:15:greet: echo 'hello, Ada'
++ hard.sh:20:main: greet Grace
++ hard.sh:14:greet: local who=Grace
++ hard.sh:15:greet: echo 'hello, Grace'
--- trace lines mentioning greet: 6
```

</details>

<details>
<summary>Break it</summary>

Bug 1: the `if` line lacks `; then`. Bash only notices at `fi`, which is why the reported line is
7, not 5. Bug 2: `$totl` is a typo; `set -u` would have caught it as `totl: unbound variable`.

```bash
#!/usr/bin/env bash
# Fixed: "then" was missing, and totl was a typo for a variable that must exist.
set -euo pipefail

name="report"
total=3
if [[ -n $name ]]; then
    echo "have a name"
fi
echo "Total: $total"
```

**Expected output**

```text
have a name
Total: 3
```

</details>

Solution files live in [`solutions/day-14/`](solutions/day-14/).

## Self-check

1. Which command checks syntax without running the script?
2. What does `+` at the start of a trace line mean, and what does `++` mean?
3. How do you change the prefix of trace lines?
4. Why should debug messages go to stderr?
5. How do you get Bash to show the exact contents and type of a variable?

<details>
<summary>Answers</summary>

1. `bash -n script.sh`.
2. A command executed at the top level; `++` is one level deeper, such as inside `$( )`.
3. Set `PS4`.
4. So they do not mix into output that other commands capture or parse.
5. `declare -p name`.

</details>

## Cheat sheet

| Command | Meaning |
|---------|---------|
| `bash -n f.sh` | Syntax check only |
| `bash -x f.sh` | Trace execution |
| `set -x` / `set +x` | Trace a region |
| `set -v` | Print input lines as read |
| `PS4='+ ${LINENO}: '` | Trace prefix with line numbers |
| `exec 5>log; BASH_XTRACEFD=5` | Trace to a file |
| `DEBUG=1 ./f.sh` | Switch on your own debug helper |
| `declare -p var` | Inspect a variable |
| `shellcheck f.sh` | Lint a script |

## Further reading

- [ShellCheck wiki](https://www.shellcheck.net/wiki/): one page per warning, each explaining the bug
  and the fix.
- [Greg's Wiki: BashGuide/Practices#Debugging](https://mywiki.wooledge.org/BashGuide/Practices#Debugging):
  a short list of debugging habits.

**Next:** [Day 15](day-15.md)
