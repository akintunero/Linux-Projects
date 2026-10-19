# Day 12: Reports with `awk`

> **Time:** ~60 min · **Level:** Intermediate
> **Prerequisites:** [Day 11](day-11.md)

## Goal

By the end of this lesson you can:

- Select and print fields from column-oriented text, with or without a custom separator.
- Filter with conditions and compute totals, averages and counts per key.
- Pass shell values into `awk` safely and format a small report with `printf`.

## Concepts

`awk` reads a file record by record (a record is normally a line), splits it into fields, and runs
`pattern { action }` rules.

```bash
awk 'pattern { action }' file
```

### Fields and built-in variables

| Name | Meaning |
|------|---------|
| `$0` | The whole line |
| `$1`, `$2`, ... | Fields (split on whitespace by default) |
| `NF` | Number of fields; `$NF` is the last field |
| `NR` | Line number (record number) across all input |
| `FS` / `-F` | Input field separator: `-F:` or `-F,` |
| `OFS` | Output field separator used by `print a, b` |

### Patterns

- No pattern: the action runs on every line.
- An expression: `$9 >= 500` runs only for lines where it is true.
- A regex: `/error/` matches lines containing "error"; `$7 ~ /^\/api/` matches one field.
- `BEGIN { ... }` runs before any line, `END { ... }` after the last one.

### Variables, arrays and printf

Variables need no declaration and start as `0` or empty. Arrays are always associative.

```bash
awk '{ hits[$1]++ } END { for (ip in hits) print hits[ip], ip }' access.log
```

`printf "%-15s %5d\n", ip, n` formats like C: `%s` string, `%d` integer, `%.1f` decimals, `-` left
aligns. Unlike `print`, `printf` adds no newline.

### Shell values: `-v`, never string pasting

A single-quoted awk program cannot see shell variables. Hand them over with `-v`:

```bash
awk -v min="$min" '$9 >= min' access.log
```

### The nginx access-log format

```text
203.0.113.5 - - [10/Oct/2025:13:55:36 +0000] "GET /index.html HTTP/1.1" 200 2326
```

Split on whitespace: `$1` client IP, `$7` path, `$9` status code, `$10` bytes sent.

## Worked example

Save as `awk.sh`. It creates a ten-line log and answers seven questions about it.

```bash
#!/usr/bin/env bash
# awk.sh - fields, patterns, accumulators and reports on an nginx access log
set -euo pipefail

cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2025:13:55:36 +0000] "GET /index.html HTTP/1.1" 200 2326
198.51.100.7 - - [10/Oct/2025:13:55:40 +0000] "GET /about.html HTTP/1.1" 200 1840
203.0.113.5 - - [10/Oct/2025:13:56:01 +0000] "GET /missing HTTP/1.1" 404 153
192.0.2.44 - - [10/Oct/2025:13:56:12 +0000] "POST /api/login HTTP/1.1" 200 512
198.51.100.7 - - [10/Oct/2025:13:57:03 +0000] "GET /api/items HTTP/1.1" 500 87
203.0.113.5 - - [10/Oct/2025:13:57:30 +0000] "GET /logo.png HTTP/1.1" 304 0
192.0.2.44 - - [10/Oct/2025:13:58:11 +0000] "POST /api/login HTTP/1.1" 401 64
198.51.100.7 - - [10/Oct/2025:13:58:45 +0000] "GET /index.html HTTP/1.1" 200 2326
203.0.113.5 - - [10/Oct/2025:13:59:02 +0000] "GET /api/items HTTP/1.1" 503 87
192.0.2.44 - - [10/Oct/2025:13:59:30 +0000] "GET /index.html HTTP/1.1" 200 2326
EOF

echo "--- 1. columns: IP, path, status"
awk '{ print $1, $7, $9 }' access.log | head -n 3

echo "--- 2. a pattern: only server errors"
awk '$9 >= 500 { print $1, $7, $9 }' access.log

echo "--- 3. BEGIN / END and counters"
awk 'BEGIN { print "counting..." } { n++ } END { print n " requests, " NF " fields on the last line" }' access.log

echo "--- 4. sum a column"
awk '{ bytes += $10 } END { printf "total bytes: %d, average: %.1f\n", bytes, bytes / NR }' access.log

echo "--- 5. associative arrays: hits per IP"
awk '{ hits[$1]++ } END { for (ip in hits) print hits[ip], ip }' access.log | sort -rn

echo "--- 6. pass a shell value in with -v"
min=500
awk -v min="$min" '$9 >= min { c++ } END { print c+0 " responses with status >= " min }' access.log

echo "--- 7. another separator: /etc/passwd style"
printf 'root:x:0:0:root:/root:/bin/bash\nada:x:1000:1000:Ada:/home/ada:/bin/zsh\n' |
    awk -F: '{ printf "%-6s uid=%s shell=%s\n", $1, $3, $7 }'
```

**Expected output**

```text
--- 1. columns: IP, path, status
203.0.113.5 /index.html 200
198.51.100.7 /about.html 200
203.0.113.5 /missing 404
--- 2. a pattern: only server errors
198.51.100.7 /api/items 500
203.0.113.5 /api/items 503
--- 3. BEGIN / END and counters
counting...
10 requests, 10 fields on the last line
--- 4. sum a column
total bytes: 9721, average: 972.1
--- 5. associative arrays: hits per IP
4 203.0.113.5
3 198.51.100.7
3 192.0.2.44
--- 6. pass a shell value in with -v
2 responses with status >= 500
--- 7. another separator: /etc/passwd style
root   uid=0 shell=/bin/bash
ada    uid=1000 shell=/bin/zsh
```

Section 5 pipes `awk`'s unordered `for (ip in hits)` output into `sort -rn` to get a stable order.
`c+0` in section 6 forces `0` instead of an empty string when nothing matched.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `awk '$9 > $limit'` with a shell `limit` | `$limit` is awk's field-by-variable syntax, not the shell variable | `awk -v limit="$limit" '$9 > limit'` |
| `awk '{ s += $10 } END { print s }'` with no file | `awk` waits on stdin (Ctrl-D ends it) | Give it the file name |
| `print $1 $2` | No separator between the values | `print $1, $2` or `print $1 " " $2` |
| `-F ,` vs `-F,` confusion with spaces in data | Wrong separator, wrong columns | Check with `awk -F, '{print NF}'` |
| Comparing numbers as strings | A field like `"200"` vs `"1000"` can sort as text | Compare against a number: `$9 + 0 > 400` |
| Double quotes around the whole program | The shell expands `$1` before awk sees it | Single-quote the program |
| Using `awk` for CSV with quoted commas | Naive splitting breaks on `"a,b"` | Use a real CSV tool (or Python) |

## Exercises

### Easy: list the 404s

For a four-line access log, print the client IP and requested path of every request with status 404.

**Acceptance criteria**

- Output: `203.0.113.5 /missing` and `198.51.100.7 /old-page`.
- Uses a pattern, not an `if` inside the action.

### Medium: status report

Print a header and then one line per status code with the number of requests and the total bytes,
sorted by status. Use associative arrays and `printf` for alignment.

**Acceptance criteria**

- The header is `STATUS REQUESTS BYTES` aligned over the data.
- For the sample (five lines) status 200 shows 2 requests and 4166 bytes.
- Sorting happens with `sort -n` on the awk output.

### Hard: traffic report

For a ten-line log, print the **top 3 clients** with their request count and error rate (status
>= 400, as a whole percent), then the **busiest path**. Break ties alphabetically so output is
stable.

**Acceptance criteria**

- First line of the report is `203.0.113.5 ... 4 requests, 50% errors` (formatted as in the sample).
- Busiest path is `/index.html` with 3 hits.
- Only `awk`, `sort` and `head` are used; no loops in the shell.

### Break it

This script has **two bugs**. It should list the clients with status >= 400 (only the second and
third log lines) and print the total bytes. Save as `break-it.sh` and run it. If it seems to hang,
press Ctrl-D.

```bash
#!/usr/bin/env bash
printf '%s\n' \
  '100.64.0.9 - - [10/Oct/2025:13:55:36 +0000] "GET /index.html HTTP/1.1" 200 2326' \
  '198.51.100.7 - - [10/Oct/2025:13:56:01 +0000] "GET /missing HTTP/1.1" 404 153' \
  '192.0.2.44 - - [10/Oct/2025:13:56:12 +0000] "POST /api/login HTTP/1.1" 500 512' > access.log

limit=400
echo "clients with status >= $limit:"
awk '$9 >= $limit { print $1 }' access.log

echo "total bytes:"
awk '{ total += $10 } END { print total }'
```

**Expected output**

```text
clients with status >= 400:
100.64.0.9
198.51.100.7
192.0.2.44
total bytes:
```

<details>
<summary>Hint</summary>

The first line has a 200 status, so why does its client appear? And what does `awk` read when you
give it no file name? Compare the two `awk` lines.

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 12 easy: list the client and path of every 404.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"
cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2025:13:55:36 +0000] "GET /index.html HTTP/1.1" 200 2326
203.0.113.5 - - [10/Oct/2025:13:56:01 +0000] "GET /missing HTTP/1.1" 404 153
192.0.2.44 - - [10/Oct/2025:13:56:12 +0000] "POST /api/login HTTP/1.1" 200 512
198.51.100.7 - - [10/Oct/2025:13:56:40 +0000] "GET /old-page HTTP/1.1" 404 153
EOF

awk '$9 == 404 { print $1, $7 }' access.log

cd / && rm -rf -- "$work"
```

**Expected output**

```text
203.0.113.5 /missing
198.51.100.7 /old-page
```

</details>

<details>
<summary>Medium</summary>

Two arrays share the status key. `sort -n` sorts the lines numerically by the leading status code.

```bash
#!/usr/bin/env bash
# Day 12 medium: requests and bytes per status code, sorted by code.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"
cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2025:13:55:36 +0000] "GET /index.html HTTP/1.1" 200 2326
198.51.100.7 - - [10/Oct/2025:13:55:40 +0000] "GET /about.html HTTP/1.1" 200 1840
203.0.113.5 - - [10/Oct/2025:13:56:01 +0000] "GET /missing HTTP/1.1" 404 153
198.51.100.7 - - [10/Oct/2025:13:57:03 +0000] "GET /api/items HTTP/1.1" 500 87
203.0.113.5 - - [10/Oct/2025:13:57:30 +0000] "GET /logo.png HTTP/1.1" 304 0
EOF

printf '%-7s %8s %10s\n' STATUS REQUESTS BYTES
awk '
    { count[$9]++; bytes[$9] += $10 }
    END { for (s in count) printf "%-7s %8d %10d\n", s, count[s], bytes[s] }
' access.log | sort -n

cd / && rm -rf -- "$work"
```

**Expected output**

```text
STATUS  REQUESTS      BYTES
200            2       4166
304            1          0
404            1        153
500            1         87
```

</details>

<details>
<summary>Hard</summary>

The first `awk` produces `count ip rate`, the `sort` orders by count descending then IP, and a
second `awk` only formats. Splitting the work keeps each stage short and testable.

```bash
#!/usr/bin/env bash
# Day 12 hard: traffic report - top 3 clients with their error rate, plus the busiest path.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"
cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2025:13:55:36 +0000] "GET /index.html HTTP/1.1" 200 2326
198.51.100.7 - - [10/Oct/2025:13:55:40 +0000] "GET /about.html HTTP/1.1" 200 1840
203.0.113.5 - - [10/Oct/2025:13:56:01 +0000] "GET /missing HTTP/1.1" 404 153
192.0.2.44 - - [10/Oct/2025:13:56:12 +0000] "POST /api/login HTTP/1.1" 200 512
198.51.100.7 - - [10/Oct/2025:13:57:03 +0000] "GET /api/items HTTP/1.1" 500 87
203.0.113.5 - - [10/Oct/2025:13:57:30 +0000] "GET /logo.png HTTP/1.1" 304 0
192.0.2.44 - - [10/Oct/2025:13:58:11 +0000] "POST /api/login HTTP/1.1" 401 64
198.51.100.7 - - [10/Oct/2025:13:58:45 +0000] "GET /index.html HTTP/1.1" 200 2326
203.0.113.5 - - [10/Oct/2025:13:59:02 +0000] "GET /api/items HTTP/1.1" 503 87
192.0.2.44 - - [10/Oct/2025:13:59:30 +0000] "GET /index.html HTTP/1.1" 200 2326
EOF

echo "Top clients (requests, error rate):"
awk '
    { total[$1]++; if ($9 >= 400) errors[$1]++ }
    END {
        for (ip in total)
            printf "%d %s %.0f%%\n", total[ip], ip, 100 * errors[ip] / total[ip]
    }
' access.log | sort -k1,1nr -k2,2 | head -n 3 | awk '{ printf "  %-15s %2d requests, %s errors\n", $2, $1, $3 }'

echo "Busiest path:"
awk '{ hits[$7]++ } END { for (p in hits) print hits[p], p }' access.log | sort -k1,1nr -k2,2 | head -n 1

cd / && rm -rf -- "$work"
```

**Expected output**

```text
Top clients (requests, error rate):
  203.0.113.5      4 requests, 50% errors
  192.0.2.44       3 requests, 33% errors
  198.51.100.7     3 requests, 33% errors
Busiest path:
3 /index.html
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `$limit` inside single quotes is *awk's* `$` operator applied to an empty awk variable, i.e.
`$0`, so the status was compared with the whole line as text. The line starting with `100.64...` sorted
below `200`, so the 200 response leaked in. Pass the value with `-v`. Bug 2: the second `awk` had no
file argument, so it read from stdin and printed an empty line.

```bash
#!/usr/bin/env bash
# Fixed: pass shell values with -v (awk cannot see shell variables inside single quotes)
# and give awk the file name, otherwise it waits for standard input.
set -euo pipefail

printf '%s\n' \
  '100.64.0.9 - - [10/Oct/2025:13:55:36 +0000] "GET /index.html HTTP/1.1" 200 2326' \
  '198.51.100.7 - - [10/Oct/2025:13:56:01 +0000] "GET /missing HTTP/1.1" 404 153' \
  '192.0.2.44 - - [10/Oct/2025:13:56:12 +0000] "POST /api/login HTTP/1.1" 500 512' > access.log

limit=400
echo "clients with status >= $limit:"
awk -v limit="$limit" '$9 >= limit { print $1 }' access.log

echo "total bytes:"
awk '{ total += $10 } END { print total }' access.log
```

**Expected output**

```text
clients with status >= 400:
198.51.100.7
192.0.2.44
total bytes:
2991
```

</details>

Solution files live in [`solutions/day-12/`](solutions/day-12/).

## Self-check

1. What are `$1`, `$NF` and `NR`?
2. How do you set the separator to a comma?
3. How do you give `awk` a value from a shell variable?
4. What do `BEGIN` and `END` blocks do?
5. Why is `for (k in arr)` output unordered, and how do you cope?

<details>
<summary>Answers</summary>

1. The first field, the last field, and the current line number.
2. `awk -F, ...` (or `BEGIN { FS="," }`).
3. `awk -v name="$value" '...'`.
4. `BEGIN` runs once before the first line, `END` once after the last.
5. Awk arrays are hash tables; pipe the output through `sort`.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `awk '{print $1, $NF}' f` | First and last field |
| `awk -F: '{print $1}' f` | Custom separator |
| `awk '$3 > 10' f` | Lines where field 3 > 10 |
| `awk '/re/' f` | Lines matching a regex |
| `awk '{s+=$2} END{print s}' f` | Sum a column |
| `awk '{c[$1]++} END{for(k in c) print k, c[k]}' f` | Count by key |
| `awk -v x="$x" '...' f` | Pass a shell value |
| `awk 'NR==1, NR==3' f` | Line range |
| `printf "%-10s %5.1f\n", a, b` | Formatted output |

## Further reading

- [awk(1p) manual page](https://man7.org/linux/man-pages/man1/awk.1p.html): the POSIX definition of the `awk` language, its built-in variables and functions
  from shell scripts.
- [grymoire: Awk tutorial](https://www.grymoire.com/Unix/Awk.html): a long, example-driven tutorial.

**Next:** [Day 13](day-13.md)
