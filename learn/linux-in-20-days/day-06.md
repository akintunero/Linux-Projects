# Day 06: Finding Things, Pipes and Redirection

> **Time:** ~60 min · **Level:** Beginner
> **Prerequisites:** [Day 05](day-05.md)

## Goal

By the end of this lesson you can:

- Search file contents with `grep` and files with `find`, including running a command on every match.
- Connect programs with pipes and redirect stdout and stderr separately.
- Answer "what are the top N things in this log?" with `sort | uniq -c | sort -rn`.

## Concepts

### Three streams

Every program has input (stdin, 0), output (stdout, 1) and errors (stderr, 2).

| Syntax | Meaning |
|--------|---------|
| `cmd > f` | stdout to file (overwrite) |
| `cmd >> f` | stdout appended |
| `cmd 2> f` | stderr to file |
| `cmd > f 2>&1` | both to the same file (order matters) |
| `cmd < f` | stdin from file |
| `a \| b` | stdout of `a` becomes stdin of `b` |
| `cmd \| tee f` | show output and save it |
| `cmd > /dev/null` | discard |

### grep

```bash
grep PATTERN file        # lines that match
grep -n  ...             # show line numbers
grep -i  ...             # ignore case
grep -v  ...             # invert: lines that do NOT match
grep -c  ...             # count matching lines
grep -E 'a|b' ...        # extended regex (alternation, +, ?)
grep -r  PATTERN dir     # recurse;  -l list file names only
grep -o  ...             # print only the matched part
```

### find

```bash
find DIR -name '*.log'            # by name (quote the pattern!)
find DIR -type f -size +1M        # regular files larger than 1 MiB
find DIR -mtime -1                # modified in the last 24 hours
find DIR -empty                   # empty files/directories
find DIR -name '*.tmp' -delete    # delete matches (see the warning below)
find DIR -type f -print0 | xargs -0 wc -l    # safe with spaces in names
```

### The counting idiom

`uniq -c` only merges **adjacent** duplicates, so sort first. Then sort the counts, largest first:

```bash
sort | uniq -c | sort -rn
```

## Worked example

Scenario: a web server log has had a bad afternoon. Create a small log:

```bash
cd "$(mktemp -d)"
cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2026:13:55:36] "GET /index.html HTTP/1.1" 200 1043
198.51.100.7 - - [10/Oct/2026:13:55:40] "GET /missing.png HTTP/1.1" 404 209
203.0.113.5 - - [10/Oct/2026:13:56:01] "POST /login HTTP/1.1" 302 404
192.0.2.44 - - [10/Oct/2026:13:57:12] "GET /index.html HTTP/1.1" 200 1043
198.51.100.7 - - [10/Oct/2026:13:57:30] "GET /about.html HTTP/1.1" 200 2310
203.0.113.5 - - [10/Oct/2026:13:58:02] "GET /api/data HTTP/1.1" 500 87
192.0.2.44 - - [10/Oct/2026:13:58:45] "GET /missing.css HTTP/1.1" 404 209
203.0.113.5 - - [10/Oct/2026:14:01:10] "GET /index.html HTTP/1.1" 200 1043
EOF
```

How many 404s? The obvious command gets it wrong, because the `/login` line has a byte count of 404:

```bash
grep -c 404 access.log
grep -c '" 404 ' access.log
```

**Expected output:**

```text
3
2
```

Anchoring on the closing quote and spaces matches only the status column.

Find POST requests with line numbers, count lines that are not 200, and show errors compactly:

```bash
grep -n 'POST' access.log
grep -vc '" 200 ' access.log
grep -E '" (404|500) ' access.log | cut -d' ' -f1,6,8
```

**Expected output:**

```text
3:203.0.113.5 - - [10/Oct/2026:13:56:01] "POST /login HTTP/1.1" 302 404
4
198.51.100.7 /missing.png 404
203.0.113.5 /api/data 500
192.0.2.44 /missing.css 404
```

Who is busiest?

```bash
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn
```

**Expected output:**

```text
      4 203.0.113.5
      2 198.51.100.7
      2 192.0.2.44
```

Without the first `sort`, `uniq -c` would see `203.0.113.5` three times in separate groups and the totals would be wrong.

Now search a directory tree. `find` filters by metadata, `grep -r` by content:

```bash
mkdir -p logs/old
cp access.log logs/a.log; cp access.log logs/old/b.log; : > logs/empty.log
grep -rl 'POST' logs
find logs -type f -name '*.log' -print0 | xargs -0 wc -l
find logs -name '*.log' -empty
```

**Expected output** (the order of `grep -r` results can differ between systems):

```text
logs/a.log
logs/old/b.log
   0 logs/empty.log
   8 logs/a.log
   8 logs/old/b.log
  16 total
logs/empty.log
```

Finally, separate the streams. `ls` of a missing path writes to stderr:

```bash
ls access.log /nonexistent > out.txt 2> err.txt
cat out.txt
cat err.txt
```

**Expected output** (error wording varies by coreutils version):

```text
access.log
ls: cannot access '/nonexistent': No such file or directory
```

> [!WARNING]
> `find ... -delete` and `find ... -exec rm {} +` remove files immediately. Run the same `find` **without**
> the action first and read the list. Put `-delete` last in the expression: `find` evaluates left to
> right, and `-delete` before `-name` would delete everything.

**Undo:** none for deletion. Preview first (`find ... -print`), or move matches to a directory with `-exec mv -t backup/ {} +`.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `grep 404 log` counts non-status matches | `404` appears in byte counts, URLs, IDs | Anchor on the column: `grep '" 404 '` or use awk (Day 07) |
| `sort \| uniq -c` forgotten `sort` | `uniq` only merges adjacent lines | always `sort \| uniq -c` |
| `sort -n` for biggest-first | `-n` is ascending | `sort -rn` |
| `find . -name *.log` | The shell expands `*.log` first | Quote it: `-name '*.log'` |
| `cmd 2>&1 > f` leaves stderr on the terminal | Redirections apply left to right | `cmd > f 2>&1` |
| `grep -r pattern` also reads binaries and `.git` | No filters | `grep -rI --exclude-dir=.git pattern` |
| `find ... \| xargs rm` breaks on spaces | Whitespace splits names | `-print0 \| xargs -0` |

## Exercises

Reference solutions: [`solutions/day-06/`](solutions/day-06/). Use the log from the worked example.

### Easy

Count how many requests returned status **404**.

**Acceptance criteria:**

- The answer is `2`, not `3`.
- You anchored the pattern so a `404` byte count is not counted.

### Medium

Print the two busiest client IPs with their request counts, busiest first.

**Acceptance criteria:**

- Exactly two lines.
- First line is `4 203.0.113.5`.
- Works when the same IP appears on non-adjacent lines.

### Hard

Write `logsummary.sh [FILE|-]` that prints `== status codes ==` followed by `CODE COUNT` lines (ascending by code), then `== top clients ==` with the three busiest IPs as `IP COUNT`. With `-` it reads stdin.

**Acceptance criteria:**

- For the sample log it prints `404 2` and `203.0.113.5 4`.
- `cat access.log | ./logsummary.sh -` gives the same output as `./logsummary.sh access.log`.
- An unreadable file gives an error and a non-zero exit status.

### Break it

[`solutions/day-06/break-it.sh`](solutions/day-06/break-it.sh) should print the two busiest IPs (busiest first) and the number of 404 responses. It has three bugs.

**Acceptance criteria:** output starts with `4 203.0.113.5` and the 404 count is `2`.

## Solutions

<details>
<summary>Easy</summary>

```bash
grep -c '" 404 ' access.log
```

Script: [`easy.sh`](solutions/day-06/easy.sh).

</details>

<details>
<summary>Medium</summary>

```bash
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head -n 2 | awk '{print $1, $2}'
```

`awk` drops `uniq`'s leading spaces. Script: [`medium.sh`](solutions/day-06/medium.sh).

</details>

<details>
<summary>Hard</summary>

Buffer stdin into a temporary file so it can be read twice, and tie-break equal counts by IP so the output is stable:

```bash
tmp=$(mktemp); trap 'rm -f "$tmp"' RETURN
awk '{print $8}' "$tmp" | sort | uniq -c | sort -k2n | awk '{print $2, $1}'
cut -d' ' -f1 "$tmp" | sort | uniq -c | sort -k1,1nr -k2,2 | head -n 3 | awk '{print $2, $1}'
```

Script with `--self-test`: [`hard.sh`](solutions/day-06/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. `uniq -c` without `sort` only merges adjacent duplicates.
2. `sort -n` is ascending; use `sort -rn`.
3. `grep 404` matches the `/login` byte count; use `grep -c '" 404 '`.

Fixed script: [`break-it.fixed.sh`](solutions/day-06/break-it.fixed.sh).

</details>

## Self-check

1. What does `cmd > out.txt 2>&1` do, and why does `cmd 2>&1 > out.txt` differ?
2. Why must you `sort` before `uniq -c`?
3. What is the safest way to run a command on every file `find` finds, if names may contain spaces?
4. Which flag makes `grep` print only file names?
5. What happens if you write `find . -name *.log` and `a.log` exists in the current directory?

<details>
<summary>Answers</summary>

1. It sends stdout to the file and then points stderr at the same place. In the other order, stderr is duplicated to the terminal first, so errors still appear on screen.
2. `uniq` only collapses adjacent duplicates.
3. `find ... -print0 | xargs -0 cmd` or `find ... -exec cmd {} +`.
4. `-l` (and `-L` for files without matches).
5. The shell expands `*.log` to `a.log` before `find` runs, so `find` searches for that exact name only.

</details>

## Cheat sheet

```bash
grep -rn 'text' dir                  # recursive, with line numbers
grep -E 'a|b' f; grep -v 'x' f       # alternation; invert
find . -type f -name '*.log' -mtime -1
find . -type f -size +100M
find . -name '*.tmp' -print          # preview, then add -delete
cmd > out 2> err; cmd > all 2>&1     # redirection
cmd | tee file                       # show and save
sort | uniq -c | sort -rn | head     # top-N counting idiom
find . -print0 | xargs -0 cmd        # safe with spaces
```

## Further reading

- [grep(1) on Ubuntu manpages](https://manpages.ubuntu.com/manpages/noble/man1/grep.1.html): every option and the regular-expression syntax.
- [find(1) on Ubuntu manpages](https://manpages.ubuntu.com/manpages/noble/man1/find.1.html): all tests and actions, with worked examples.
- [Bash Day 04](../30-days-of-bash/day-04.md): exit codes, which `grep` uses (0 = match, 1 = none).

**Next:** [Day 07](day-07.md)
