# Day 08: Redirection, Pipes and Here-Documents

> **Time:** ~55 min · **Level:** Beginner
> **Prerequisites:** [Day 07](day-07.md)

## Goal

By the end of this lesson you can:

- Send stdout and stderr to files, to each other, or to nowhere, and get the order right.
- Connect commands with pipes and save a copy of a stream with `tee`.
- Generate multi-line text with here-docs and feed short strings with here-strings.

## Concepts

### Three standard streams

| Number | Name | Default | Used for |
|--------|------|---------|----------|
| 0 | stdin | keyboard | input |
| 1 | stdout | terminal | normal output |
| 2 | stderr | terminal | errors and diagnostics |

### Redirection operators

| Operator | Meaning |
|----------|---------|
| `> file` | Write stdout to `file` (**truncates** it first) |
| `>> file` | Append stdout to `file` |
| `2> file` | Write stderr to `file` |
| `> file 2>&1` | stdout to `file`, then stderr to the same place as stdout |
| `&> file` | Bash shorthand for the line above |
| `< file` | Read stdin from `file` |
| `> /dev/null` | Discard output |

> [!WARNING]
> **Order matters.** `cmd > file 2>&1` sends both to the file. `cmd 2>&1 > file` points stderr at
> the terminal first, so errors still appear on screen. Also never read and write the same file in
> one command: `sort f > f` empties `f` before `sort` reads it.

### Pipes and `tee`

`a | b` feeds a's stdout to b's stdin. `tee file` copies the stream to a file and also passes it on:

```bash
make 2>&1 | tee build.log      # watch it live and keep a record
```

A pipeline's status is its last command's unless you set `pipefail`. `${PIPESTATUS[@]}` holds the
status of every stage of the **most recent** pipeline.

### Here-documents

A here-doc feeds a block of text to stdin:

```bash
cat > app.conf <<EOF
owner=$USER
EOF
```

- `<<EOF`: variables and `$(...)` **are** expanded.
- `<<'EOF'`: nothing is expanded (use this for templates and code).
- `<<-EOF`: leading **tabs** are stripped, so you can indent the block.

The closing delimiter must be alone on its line.

### Here-strings

`cmd <<< "text"` sends one string (plus a newline) to stdin. It avoids `echo text | cmd` and, unlike
the pipe, `read` keeps its variables:

```bash
read -r first second <<< "hello world"
```

## Worked example

Save as `redirect.sh` and run it in an empty directory.

```bash
#!/usr/bin/env bash
# redirect.sh - streams, redirection, pipes, here-docs, here-strings
set -euo pipefail

# stdout (1) and stderr (2) are separate streams.
ls . /no/such/dir > out.txt 2> err.txt || true
echo "out.txt: $(wc -l < out.txt) line(s); err.txt: $(wc -l < err.txt) line(s)"

# > truncates, >> appends.
echo "first"  > notes.txt
echo "second" >> notes.txt
cat notes.txt

# Send both streams to one file: redirect stdout FIRST, then point stderr at it.
ls . /no/such/dir > both.txt 2>&1 || true
echo "both.txt has $(wc -l < both.txt) lines"

# Throw output away.
ls /no/such/dir 2> /dev/null || echo "ls failed quietly (status $?)"

# Pipes connect stdout to the next command's stdin; tee also saves a copy.
printf '%s\n' pear apple fig | sort | tee sorted.txt | head -n 2

# Here-document: a multi-line file. Quoting the delimiter ('EOF') stops expansion.
user="ada"
cat > app.conf <<EOF
owner=$user
home=$HOME
EOF
cat > raw.conf <<'EOF'
owner=$user
EOF
echo "--- app.conf (expanded)"; sed 's#^home=.*#home=<your home>#' app.conf
echo "--- raw.conf (literal)"; cat raw.conf

# Here-string: feed a short string to stdin.
if grep -q "apple" <<< "$(cat sorted.txt)"; then
    echo "sorted.txt mentions apple"
fi
read -r first second <<< "hello world"
echo "first=$first second=$second"
```

**Expected output**

```text
out.txt: 4 line(s); err.txt: 1 line(s)
first
second
both.txt has 7 lines
ls failed quietly (status 2)
apple
fig
--- app.conf (expanded)
owner=ada
home=<your home>
--- raw.conf (literal)
owner=$user
sorted.txt mentions apple
first=hello second=world
```

`|| true` after `ls` is deliberate: `ls` returns 2 when one argument is missing, which would stop a
`set -e` script. `sed` hides your home directory in the output. The numbers in the first and third
lines come from `ls` listing the current directory plus the missing one.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `echo "x" > log.txt` in a loop | Each pass truncates the file | `>>` or redirect the whole loop once |
| `cmd 2>&1 > file` | stderr was pointed at the terminal before stdout moved | `cmd > file 2>&1` |
| `sort data > data` | The shell truncates `data` before `sort` runs | `sort -o data data` or write to a temp file |
| Tabs/spaces before the closing `EOF` | The delimiter must be alone, with no indentation (unless `<<-` with tabs) | Unindent it |
| Variables unexpectedly expanded in a here-doc | `<<EOF` expands `$...` | `<<'EOF'` |
| `cmd \| tee file` loses the failure of `cmd` | Status is `tee`'s | `set -o pipefail` or `${PIPESTATUS[0]}` |
| `echo "$text" \| read x` | `read` runs in a subshell, `x` is lost | `read -r x <<< "$text"` |

## Exercises

### Easy: split the streams

In a temporary directory create two files, then run `ls . missing-dir` with stdout going to
`out.txt` and stderr to `err.txt`. Print how many lines each file has and show `err.txt`.

**Acceptance criteria**

- `err.txt` contains exactly one line: the "cannot access" error.
- Nothing from `ls` appears on the terminal while it runs.
- The script does not stop because `ls` failed.

### Medium: generate and verify a config

Use a here-doc to write `shop.conf` with a comment line, `listen_port=8080` (from a variable) and
a `log_file=` path built from the app name. Use a second, quoted here-doc to write `template.conf`
containing the literal text `listen_port=${port}`. Then verify the port line with `grep -q` and a
here-string.

**Acceptance criteria**

- `shop.conf` shows the expanded values, `template.conf` shows the literal `${port}`.
- The verification prints `check passed: port is 8080`, and the script exits 1 if it fails.
- No `echo ... | grep`.

### Hard: logged runner

Write `run_logged LABEL COMMAND [ARGS...]` that prints the command output live **and** appends it
(stdout plus stderr) to a log file, with header and footer lines, and returns the command's own exit
status, not `tee`'s. Run one command that succeeds and one that fails and report the wrapper's
status for each.

**Acceptance criteria**

- The failing run returns the same status as the command (2 for `ls /no/such/dir`).
- The log holds both commands' output and all header/footer lines.
- Uses `${PIPESTATUS[0]}` (or `pipefail`) correctly.

### Break it

This script has **three bugs**. Save it as `break-it.sh`, run it and fix it so that `log.txt` has two
lines, `errors.txt` contains the error, and `data.txt` is sorted and non-empty.

```bash
#!/usr/bin/env bash
printf 'b\na\n' > data.txt

echo "start" > log.txt
ls /nonexistent > log.txt 2>&1

ls /nonexistent 2>&1 > errors.txt

sort data.txt > data.txt

echo "log.txt: $(wc -l < log.txt) line(s)"
echo "errors.txt: $(wc -c < errors.txt) bytes"
echo "data.txt: $(wc -c < data.txt) bytes"
```

**Expected output**

```text
ls: cannot access '/nonexistent': No such file or directory
log.txt: 1 line(s)
errors.txt: 0 bytes
data.txt: 0 bytes
```

<details>
<summary>Hint</summary>

One error message escaped to the terminal: which redirection was supposed to catch it? And why is
`data.txt` zero bytes?

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 08 easy: split stdout and stderr of one command into two files.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"
touch one.txt two.txt

ls . missing-dir > out.txt 2> err.txt || true

echo "stdout lines: $(wc -l < out.txt)"
echo "stderr lines: $(wc -l < err.txt)"
echo "--- err.txt"
cat err.txt

cd / && rm -rf -- "$work"
```

**Expected output**

```text
stdout lines: 5
stderr lines: 1
--- err.txt
ls: cannot access 'missing-dir': No such file or directory
```

</details>

<details>
<summary>Medium</summary>

`$(< file)` reads a file without starting `cat`. The here-string avoids a pipe, so there is no
subshell.

```bash
#!/usr/bin/env bash
# Day 08 medium: generate a config with a here-doc and verify it with a here-string.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"

app="shop"
port=8080

cat > "${app}.conf" <<EOF
# generated config for ${app}
listen_port=${port}
log_file=/var/log/${app}.log
EOF

cat > template.conf <<'EOF'
listen_port=${port}
EOF

echo "--- ${app}.conf"
cat "${app}.conf"
echo "--- template.conf (nothing expanded)"
cat template.conf

content="$(< "${app}.conf")"
if grep -q "^listen_port=8080$" <<< "$content"; then
    echo "check passed: port is 8080"
else
    echo "check FAILED" >&2
    exit 1
fi

cd / && rm -rf -- "$work"
```

**Expected output**

```text
--- shop.conf
# generated config for shop
listen_port=8080
log_file=/var/log/shop.log
--- template.conf (nothing expanded)
listen_port=${port}
check passed: port is 8080
```

</details>

<details>
<summary>Hard</summary>

`PIPESTATUS[0]` must be read immediately after the pipeline, before any other command overwrites it.
The `|| status=$?` at the call site keeps `set -e` from ending the script.

```bash
#!/usr/bin/env bash
# Day 08 hard: run a command, show its output live, log it, and keep its exit status.
# Works in a temporary directory only.
set -euo pipefail

work="$(mktemp -d)"
logfile="${work}/job.log"

# run_logged LABEL COMMAND [ARGS...]
# stdout+stderr are shown AND appended to the log; the command's own status is returned.
run_logged() {
    local label="$1"
    shift
    echo "== ${label}: $*" | tee -a "$logfile"
    "$@" 2>&1 | tee -a "$logfile"
    local status="${PIPESTATUS[0]}"       # status of "$@", not of tee
    echo "== ${label}: exit ${status}" | tee -a "$logfile"
    return "$status"
}

run_logged greeting echo "hello from the job"
status=0
run_logged broken ls /no/such/dir || status=$?
echo "wrapper returned ${status}"

echo "--- lines in log: $(wc -l < "$logfile")"
grep -c '^== ' "$logfile" | sed 's/^/header lines: /'

rm -rf -- "$work"
```

**Expected output**

```text
== greeting: echo hello from the job
hello from the job
== greeting: exit 0
== broken: ls /no/such/dir
ls: cannot access '/no/such/dir': No such file or directory
== broken: exit 2
wrapper returned 2
--- lines in log: 6
header lines: 4
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `>` truncated `log.txt`, destroying `start` (use `>>`). Bug 2: `2>&1 > errors.txt` has the
wrong order, so the error appeared on screen and `errors.txt` stayed empty. Bug 3: `sort data.txt >
data.txt` emptied the input before `sort` read it; `sort -o` handles that safely.

```bash
#!/usr/bin/env bash
# Fixed: append with >>, redirect stdout before stderr, never read and write the same file.
printf 'b\na\n' > data.txt

echo "start" > log.txt
ls /nonexistent >> log.txt 2>&1

ls /nonexistent > errors.txt 2>&1

sort -o data.txt data.txt        # -o is safe even when input and output are the same file

echo "log.txt: $(wc -l < log.txt) line(s)"
echo "errors.txt: $(wc -c < errors.txt) bytes"
echo "data.txt: $(wc -c < data.txt) bytes"
```

**Expected output**

```text
log.txt: 2 line(s)
errors.txt: 60 bytes
data.txt: 4 bytes
```

</details>

Solution files live in [`solutions/day-08/`](solutions/day-08/).

## Self-check

1. Which file descriptor is stderr?
2. What is the difference between `>` and `>>`?
3. Why does `cmd 2>&1 > f` not capture errors in `f`?
4. When do you use `<<'EOF'` instead of `<<EOF`?
5. What does `${PIPESTATUS[0]}` give you?

<details>
<summary>Answers</summary>

1. Number 2.
2. `>` truncates the file first; `>>` appends.
3. Redirections are processed left to right: stderr is pointed at where stdout currently goes (the
   terminal) before stdout moves to `f`.
4. When the text must be taken literally, with no variable or command expansion.
5. The exit status of the first command in the most recent pipeline.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `> f`, `>> f` | Overwrite / append stdout |
| `2> f`, `2>&1`, `&> f` | stderr to file / to stdout / both |
| `< f` | stdin from file |
| `cmd1 \| cmd2` | Pipe |
| `tee [-a] f` | Copy stream to file (append with `-a`) |
| `<<EOF`, `<<'EOF'`, `<<-EOF` | Here-doc: expanding / literal / tab-stripped |
| `<<< "text"` | Here-string |
| `> /dev/null 2>&1` | Silence everything |
| `${PIPESTATUS[@]}` | Status of each pipeline stage |

## Further reading

- [Greg's Wiki: BashGuide/InputAndOutput](https://mywiki.wooledge.org/BashGuide/InputAndOutput):
  a patient walkthrough of file descriptors and redirection.
- [Greg's Wiki: BashFAQ/024](https://mywiki.wooledge.org/BashFAQ/024): why variables set in a pipeline
  loop disappear and what to do instead.

**Next:** [Day 09](day-09.md)
