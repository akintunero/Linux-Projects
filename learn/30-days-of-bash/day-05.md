# Day 05: Loops and Safe Iteration

> **Time:** ~55 min · **Level:** Beginner
> **Prerequisites:** [Day 04](day-04.md)

## Goal

By the end of this lesson you can:

- Write `for`, `while` and `until` loops, with `break` and `continue`.
- Loop over files with a glob and over a file's lines with `while IFS= read -r`.
- Iterate over command output without breaking on spaces or newlines in names.

## Concepts

### `for` over a list

```bash
for env in dev staging prod; do
    echo "deploying to $env"
done
```

### `for` over files: use a glob

The shell expands `*.log` into a proper list, one item per file, even if names contain spaces.

```bash
shopt -s nullglob          # no match -> empty list (otherwise the loop sees the literal "*.log")
for f in *.log; do
    echo "$f"
done
```

> [!WARNING]
> Never write `for f in $(ls)` or `for f in $(cat file)`. The output is split on every space and
> glob-expanded, so `my notes.txt` becomes two items. This is the single most common loop bug.

### C-style `for` and counting

```bash
for (( i = 1; i <= 3; i++ )); do echo "attempt $i"; done
```

### `while` and `until`

`while` repeats while its command succeeds; `until` repeats until it succeeds.

```bash
n=3
while (( n > 0 )); do echo "$n"; n=$(( n - 1 )); done
```

### Reading a file line by line

```bash
while IFS= read -r line; do
    echo "line: $line"
done < input.txt
```

- `read -r` stops backslashes from being treated as escapes.
- `IFS=` stops `read` from trimming leading and trailing whitespace.
- `< input.txt` feeds the file to the loop. The loop is **not** in a pipeline, so variables you set
  inside it survive.

To split a line into fields, set `IFS` for that one `read`:
`while IFS=, read -r host ip state; do ... done < servers.csv`.

### `break` and `continue`

`continue` jumps to the next iteration; `break` leaves the loop.

### Looping over command output safely

File names may contain spaces and even newlines. The only fully safe separator is the NUL byte:

```bash
find . -name '*.log' -print0 | while IFS= read -r -d '' path; do
    echo "$path"
done
```

`-print0` ends each name with NUL and `read -d ''` reads up to NUL. Caveat: a loop at the end of a
pipeline runs in a **subshell**, so counters set inside it vanish afterwards (Day 17 shows
`< <(find ...)` which avoids that).

## Worked example

Save as `loops.sh` and run it in an empty directory.

```bash
#!/usr/bin/env bash
# loops.sh - the loops you will use every week
set -euo pipefail
shopt -s nullglob          # a glob with no match gives an empty list

# 1. A list of words
for env in dev staging prod; do
    echo "deploying to $env"
done

# 2. Files: let the shell expand the glob. Never parse `ls`.
touch a.log b.log "c d.log"
for f in *.log; do
    echo "log file: $f"
done

# 3. Lines of a file: IFS= and -r keep each line exactly as written.
printf '%s\n' "web01,10.0.0.5,up" "db01,10.0.0.9,down" "cache01,10.0.0.7,up" > servers.csv
while IFS=, read -r host ip state; do
    if [[ $state == up ]]; then
        echo "$host ($ip) is up"
    else
        echo "$host ($ip) is DOWN"
    fi
done < servers.csv

# 4. Counting
for (( i = 1; i <= 3; i++ )); do
    echo "attempt $i of 3"
done

# 5. break and continue
for n in 1 2 3 4 5 6; do
    (( n % 2 == 0 )) && continue      # skip even numbers
    (( n > 5 )) && break              # stop after 5
    echo "odd number $n"
done

# 6. Output of a command, safely: NUL-separated names survive spaces and newlines.
find . -maxdepth 1 -name '*.log' -print0 | sort -z | while IFS= read -r -d '' path; do
    echo "found: $path"
done
```

**Expected output**

```text
deploying to dev
deploying to staging
deploying to prod
log file: a.log
log file: b.log
log file: c d.log
web01 (10.0.0.5) is up
db01 (10.0.0.9) is DOWN
cache01 (10.0.0.7) is up
attempt 1 of 3
attempt 2 of 3
attempt 3 of 3
odd number 1
odd number 3
odd number 5
found: ./a.log
found: ./b.log
found: ./c d.log
```

The `servers.csv` loop reads three comma-separated fields per line. `found: ./c d.log` shows the
file with a space in its name survived intact.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `for f in $(ls *.txt)` | Splits `my notes.txt` into `my` and `notes.txt` | `for f in *.txt` |
| `for f in *.log` with no logs | The loop runs once with `f` set to `*.log` | `shopt -s nullglob` |
| `cat file \| while read line` | Extra process, backslashes eaten, subshell hides variables | `while IFS= read -r line; do ...; done < file` |
| `read line` | Mangles backslashes and trims whitespace | `IFS= read -r line` |
| `i=$((i+1))` forgotten in a `while` | Infinite loop | Always change what the condition tests |
| `for i in {1..$n}` | Brace expansion happens before variables | `for (( i = 1; i <= n; i++ ))` |
| Counting inside `cmd \| while ...` | The loop is a subshell; the count is lost | Redirect from a file or use `< <(cmd)` |

## Exercises

### Easy: numbered photo list

In a scratch directory create `beach day.jpg`, `city.jpg`, `notes.txt` and `forest.jpg`. Print
`1: beach day.jpg`, `2: city.jpg`, and so on for the JPEG files only. If there are none, print
`No JPEG files`.

**Acceptance criteria**

- The name with a space prints on one line.
- Deleting all `.jpg` files and running again prints `No JPEG files`.
- No use of `ls` or command substitution to produce the list.

### Medium: hosts that are down

Create a `servers.csv` with a header line `host,ip,state`, a comment line starting with `#`, and
three hosts (one `down`). Read it with `while IFS=, read -r`, skip the header and the comment, print
`DOWN: host (ip)` for each host whose state is not `up`, then print the count. Exit with status 1
if any host is down.

**Acceptance criteria**

- Output is `DOWN: db01 (10.0.0.9)` then `1 host(s) down` for the sample data.
- `echo $?` after the script prints `1`; with all hosts up it prints `0`.
- The loop reads from the file with `<`, not from `cat file |`.

### Hard: rotate logs

In a scratch directory create `app.log` (1500 bytes), `small.log` (4 bytes), and old copies
`app.log.1`, `app.log.2`, `app.log.3`. For every `*.log` larger than 1000 bytes: delete the oldest
copy (`.3`), shift the others up (`.2` to `.3`, `.1` to `.2`), move the log to `.1`, and create a
fresh empty log. Print `skip` or `rotate` per file and finally list the sizes.

**Acceptance criteria**

- After running, `app.log` is 0 bytes, `app.log.1` is 1500 bytes, `app.log.2` and `app.log.3` hold
  the old `.1` and `.2` data, and the old `.3` is gone.
- `small.log` is untouched.
- Re-running with no big logs rotates nothing.

### Break it

This script has **two bugs**. Save it as `break-it.sh`, run it, and fix it.

```bash
#!/usr/bin/env bash
touch "my notes.txt" todo.txt

for f in $(ls *.txt); do
    echo "Processing $f"
done

count=0
ls *.txt | while read line; do
    count=$((count + 1))
done
echo "Total: $count"
```

**Expected output**

```text
Processing my
Processing notes.txt
Processing todo.txt
Total: 0
```

<details>
<summary>Hint</summary>

Count the lines printed under "Processing": there are three, but only two files. And why is the total
0 when two files exist?

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 05 easy: print a numbered list of JPEG files; say so if there are none.
set -euo pipefail
shopt -s nullglob

work="$(mktemp -d)"
cd "$work"
touch "beach day.jpg" city.jpg notes.txt forest.jpg

n=0
for photo in *.jpg; do
    n=$(( n + 1 ))
    echo "${n}: ${photo}"
done
if (( n == 0 )); then
    echo "No JPEG files"
fi

cd / && rm -rf -- "$work"
```

**Expected output**

```text
1: beach day.jpg
2: city.jpg
3: forest.jpg
```

</details>

<details>
<summary>Medium</summary>

`[[ $host == \#* ]]` matches names starting with `#`; the backslash stops `#` starting a comment.
The count is kept in a variable and the cleanup runs before `exit`, so the temp directory never
survives a failing run.

```bash
#!/usr/bin/env bash
# Day 05 medium: report hosts that are down; exit 1 if any are.
set -euo pipefail

work="$(mktemp -d)"
cat > "$work/servers.csv" <<'EOF'
host,ip,state
# staging
web01,10.0.0.5,up
db01,10.0.0.9,down
cache01,10.0.0.7,up
EOF

down=0
while IFS=, read -r host ip state; do
    [[ $host == host ]] && continue          # header line
    [[ $host == \#* ]] && continue           # comment line
    if [[ $state != up ]]; then
        echo "DOWN: $host ($ip)"
        down=$(( down + 1 ))
    fi
done < "$work/servers.csv"

rm -rf -- "$work"
echo "$down host(s) down"
if (( down > 0 )); then
    exit 1
fi
```

**Expected output**

```text
DOWN: db01 (10.0.0.9)
1 host(s) down
```

</details>

<details>
<summary>Hard</summary>

The inner loop counts **down** (`keep-1` to `1`) so each copy moves before the one below it is
overwritten. Working oldest-first is the whole trick of log rotation.

```bash
#!/usr/bin/env bash
# Day 05 hard: rotate every *.log bigger than max_bytes, keeping 3 old copies.
# Works only inside a temporary directory it creates; safe to run anywhere.
set -euo pipefail
shopt -s nullglob

work="$(mktemp -d)"
cd "$work"
max_bytes=1000
keep=3

# Sample data: one big log with history, one small log.
head -c 1500 /dev/zero | tr '\0' 'x' > app.log
echo "gen1" > app.log.1
echo "gen2" > app.log.2
echo "gen3" > app.log.3
echo "tiny" > small.log

for log in *.log; do
    size="$(stat -c %s -- "$log")"
    if (( size <= max_bytes )); then
        echo "skip   $log (${size} bytes)"
        continue
    fi
    rm -f -- "${log}.${keep}"                       # the oldest copy falls off the end
    for (( i = keep - 1; i >= 1; i-- )); do
        if [[ -e "${log}.${i}" ]]; then
            mv -- "${log}.${i}" "${log}.$(( i + 1 ))"
        fi
    done
    mv -- "$log" "${log}.1"
    : > "$log"                                      # fresh empty log
    echo "rotate $log (${size} bytes)"
done

echo "--- result"
stat -c '%n %s bytes' app.log* small.log

cd / && rm -rf -- "$work"
```

**Expected output**

```text
rotate app.log (1500 bytes)
skip   small.log (5 bytes)
--- result
app.log 0 bytes
app.log.1 1500 bytes
app.log.2 5 bytes
app.log.3 5 bytes
small.log 5 bytes
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `$(ls *.txt)` splits `my notes.txt` into two words. Bug 2: the `while` loop sits at the end of
a pipe, so it runs in a subshell and `count` is still 0 in the parent. Looping over the glob and
counting in the same shell fixes both.

```bash
#!/usr/bin/env bash
# Fixed: loop over the glob (not over `ls` output) and count inside the loop,
# not in a pipeline subshell.
set -euo pipefail
shopt -s nullglob

touch "my notes.txt" todo.txt

count=0
for f in *.txt; do
    echo "Processing $f"
    count=$(( count + 1 ))
done
echo "Total: $count"
```

**Expected output**

```text
Processing my notes.txt
Processing todo.txt
Total: 2
```

</details>

Solution files live in [`solutions/day-05/`](solutions/day-05/).

## Self-check

1. Why is `for f in $(ls)` wrong?
2. What does `shopt -s nullglob` change?
3. What do `IFS=` and `-r` do in `while IFS= read -r line`?
4. Why does a counter incremented inside `cmd | while read ...` stay unchanged?
5. What is the difference between `break` and `continue`?

<details>
<summary>Answers</summary>

1. The output is split on whitespace and re-globbed, so names with spaces break into pieces.
2. A glob that matches nothing expands to nothing instead of staying as literal text.
3. `IFS=` keeps leading and trailing whitespace; `-r` keeps backslashes literal.
4. Each side of a pipe runs in a subshell; its variables disappear when it ends.
5. `break` leaves the loop; `continue` skips to the next iteration.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `for x in a b c; do ...; done` | Loop over words |
| `for f in *.txt; do ...; done` | Loop over files (with `nullglob`) |
| `for (( i=0; i<n; i++ ))` | Counting loop |
| `while cmd; do ...; done` / `until cmd` | Repeat while / until success |
| `while IFS= read -r line; do ...; done < file` | Read lines safely |
| `IFS=, read -r a b c` | Split a line into fields |
| `find ... -print0 \| while IFS= read -r -d ''` | NUL-safe file loop |
| `break`, `continue` | Leave / skip iteration |

## Further reading

- [Greg's Wiki: BashFAQ/001](https://mywiki.wooledge.org/BashFAQ/001): the definitive answer on reading
  a file line by line.
- [Greg's Wiki: BashFAQ/020](https://mywiki.wooledge.org/BashFAQ/020): how to iterate over files and
  directory trees safely.
- [Greg's Wiki: DontReadLinesWithFor](https://mywiki.wooledge.org/DontReadLinesWithFor): why a `for`
  loop is the wrong tool for lines.

**Next:** [Day 06](day-06.md)
