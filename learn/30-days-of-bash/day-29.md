# Day 29: Text Pipelines with `grep`, `cut`, `sort` and Friends

> **Time:** ~60 min · **Level:** Advanced
> **Prerequisites:** [Day 28](day-28.md)

## Goal

By the end of this lesson you can:

- Pick columns with `cut`, filter with `grep`, and count with `sort | uniq -c`.
- Build the classic "top N" pipeline and read it left to right.
- Triage a web server log: error rates, failing paths, requests per hour, and who is responsible.

## Concepts

The Unix philosophy: small tools that do one thing, joined by pipes. Days 11, 12 and 21 gave you
`sed`, `awk` and regexes. Today is the everyday toolkit that makes most log questions a one-liner.

### The tools

| Tool | Does | Key options |
|------|------|-------------|
| `cut` | Select columns | `-d' ' -f1,7` by delimiter and field, `-c1-10` by characters |
| `grep` | Select lines | `-E` regex, `-F` fixed text, `-v` invert, `-c` count, `-o` match only, `-A/-B/-C N` context, `-w` whole word, `-f file` patterns from a file |
| `sort` | Order lines | `-n` numeric, `-r` reverse, `-k2,2` by field, `-u` unique, `-h` human sizes, `-z` NUL |
| `uniq` | Collapse **adjacent** duplicates | `-c` count, `-d` only duplicates |
| `tr` | Translate or delete characters | `tr -s ' '` squeeze, `tr a-z A-Z`, `tr -d '\r'` |
| `wc` | Count | `-l` lines, `-w` words, `-c` bytes |
| `head` / `tail` | First / last lines | `-n 5`, `tail -f` follows a file |
| `paste` | Glue files side by side | `-d,` delimiter |
| `join` | Join two **sorted** files on a key | `join a.txt b.txt` |
| `column` | Align into a table | `-t` |

### The top-N pipeline

```bash
extract_column | sort | uniq -c | sort -k1,1nr | head -n 3
```

1. Extract the thing you are counting, one per line.
2. `sort` so equal values are adjacent (`uniq` only collapses neighbours).
3. `uniq -c` prefixes each distinct value with its count.
4. `sort -k1,1nr` orders by that count, biggest first (add a second key to break ties).
5. `head` keeps the top.

### Choosing tool: `grep` versus `awk`

`grep 404` finds the text "404" **anywhere** in the line: a byte count, a path, a time. If you mean "the
status code is 404", match the column: `awk '$9 == 404'` or a regex that includes the surrounding
quote and spaces: `grep '" 404 '`. Be exact about what you are matching.

### `cut` limits

`cut` splits on a single character, so repeated spaces make empty fields. When columns are aligned with
several spaces, squeeze first (`tr -s ' ' | cut -d' ' ...`) or use `awk`.

### Pipelines and errors

With `set -o pipefail`, a failing stage fails the pipeline. But `grep -c`, `grep -q` and `grep` in general
exit 1 for "no match", which is not an error for your purposes. Add `|| true` where an empty result is
fine.

## Worked example

A twelve-line access log and nine questions. Save as `pipeline.sh`.

```bash
#!/usr/bin/env bash
# pipeline.sh - answering questions about a log with small tools joined by pipes
set -euo pipefail

cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2025:13:05:36 +0000] "GET /index.html HTTP/1.1" 200 2326
198.51.100.7 - - [10/Oct/2025:13:15:40 +0000] "GET /about.html HTTP/1.1" 200 1840
203.0.113.5 - - [10/Oct/2025:13:25:01 +0000] "GET /missing HTTP/1.1" 404 153
192.0.2.44 - - [10/Oct/2025:14:06:12 +0000] "POST /api/login HTTP/1.1" 200 512
198.51.100.7 - - [10/Oct/2025:14:07:03 +0000] "GET /api/items HTTP/1.1" 500 87
203.0.113.5 - - [10/Oct/2025:14:17:30 +0000] "GET /logo.png HTTP/1.1" 200 404
192.0.2.44 - - [10/Oct/2025:14:18:11 +0000] "POST /api/login HTTP/1.1" 401 64
198.51.100.7 - - [10/Oct/2025:15:08:45 +0000] "GET /index.html HTTP/1.1" 200 2326
203.0.113.5 - - [10/Oct/2025:15:09:02 +0000] "GET /api/items HTTP/1.1" 503 87
192.0.2.44 - - [10/Oct/2025:15:19:30 +0000] "GET /index.html HTTP/1.1" 200 2326
198.51.100.7 - - [10/Oct/2025:15:20:00 +0000] "GET /old-page HTTP/1.1" 404 153
203.0.113.5 - - [10/Oct/2025:15:21:10 +0000] "GET /index.html HTTP/1.1" 200 2326
EOF

echo "--- 1. cut: columns by delimiter. Field 1 = client IP"
cut -d' ' -f1 access.log | head -n 3

echo "--- 2. cut with another delimiter: the quoted request is field 2 between double quotes"
cut -d'"' -f2 access.log | head -n 3

echo "--- 3. count by value: sort, then uniq -c, then sort by the count"
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn

echo "--- 4. the pattern: extract | sort | uniq -c | sort -rn | head"
cut -d'"' -f2 access.log | cut -d' ' -f2 | sort | uniq -c | sort -k1,1nr -k2 | head -n 3

echo "--- 5. grep: count lines, invert, fixed strings"
echo "status 404 (field match): $(awk '$9 == 404' access.log | wc -l)"
echo "lines containing the text '404' anywhere: $(grep -c 404 access.log)"
echo "requests that are not GET: $(grep -vc 'GET' access.log)"
grep -F '/api/' access.log | cut -d' ' -f1,7,9 | head -n 2

echo "--- 6. context around a match (-B before, -A after)"
grep -B1 -A1 ' 503 ' access.log | cut -c1-48

echo "--- 7. requests per hour: cut twice, then count"
cut -d'[' -f2 access.log | cut -d: -f2 | sort | uniq -c

echo "--- 8. tr squeezes and translates; wc counts; paste glues columns"
echo "a   b    c" | tr -s ' ' ','
echo "lines: $(wc -l < access.log), words: $(wc -w < access.log)"
paste -d' ' <(cut -d' ' -f1 access.log | head -n 3) <(cut -d' ' -f9 access.log | head -n 3)

echo "--- 9. join two sorted files on a key; column -t aligns the result"
printf '%s\n' '192.0.2.44 office' '198.51.100.7 partner' '203.0.113.5 customer' > owners.txt
cut -d' ' -f1 access.log | sort | uniq -c | awk '{ print $2, $1 }' | sort > counts.txt
join owners.txt counts.txt | column -t
```

**Expected output**

```text
--- 1. cut: columns by delimiter. Field 1 = client IP
203.0.113.5
198.51.100.7
203.0.113.5
--- 2. cut with another delimiter: the quoted request is field 2 between double quotes
GET /index.html HTTP/1.1
GET /about.html HTTP/1.1
GET /missing HTTP/1.1
--- 3. count by value: sort, then uniq -c, then sort by the count
      5 203.0.113.5
      4 198.51.100.7
      3 192.0.2.44
--- 4. the pattern: extract | sort | uniq -c | sort -rn | head
      4 /index.html
      2 /api/items
      2 /api/login
--- 5. grep: count lines, invert, fixed strings
status 404 (field match): 2
lines containing the text '404' anywhere: 3
requests that are not GET: 2
192.0.2.44 /api/login 200
198.51.100.7 /api/items 500
--- 6. context around a match (-B before, -A after)
198.51.100.7 - - [10/Oct/2025:15:08:45 +0000] "G
203.0.113.5 - - [10/Oct/2025:15:09:02 +0000] "GE
192.0.2.44 - - [10/Oct/2025:15:19:30 +0000] "GET
--- 7. requests per hour: cut twice, then count
      3 13
      4 14
      5 15
--- 8. tr squeezes and translates; wc counts; paste glues columns
a,b,c
lines: 12, words: 120
203.0.113.5 200
198.51.100.7 200
203.0.113.5 404
--- 9. join two sorted files on a key; column -t aligns the result
192.0.2.44    office    3
198.51.100.7  partner   4
203.0.113.5   customer  5
```

Compare sections 3 and 4: the same shape, different columns. In section 5 the plain text `404` matched
three lines (one of them a byte count) while the column match found two. That difference is exactly the
bug in this lesson's "Break it".

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `uniq -c` without `sort` first | Only adjacent duplicates are merged | `sort \| uniq -c` |
| `sort -rn` vs `sort -r` on counts | Without `-n`, `10` sorts before `9` | `sort -n` for numbers |
| `grep 404 log` to find "not found" | Matches any 404 in any column | Match the status column |
| `cut -d' ' -f5` on space-aligned output | Repeated spaces create empty fields | `tr -s ' '` first, or `awk` |
| `join a b` with unsorted input | Silently misses matches | `sort` both files on the join key |
| `grep -c` under `set -e` with zero matches | Exit status 1 stops the script | `\|\| true` |
| `grep` pattern containing `.` or `/` | `.` matches any character | `grep -F` for literal text |
| Reading a huge file several times | Slow | One pass with `awk`, or save the filtered subset |

## Exercises

### Easy: the busiest paths

For a seven-line access log print the three most requested paths with their counts, breaking ties
alphabetically. The path is the second word of the quoted request.

**Acceptance criteria**

- Output: `3 /index.html`, `2 /api/login`, `1 /about.html`.
- Built from `cut`, `sort`, `uniq -c` and `head` only.
- The tie between `/about.html`, `/api/...` entries is broken by path, not by chance.

### Medium: requests per hour

From a nine-line log print a text histogram: the hour, a bar of `#` (one per request) and the count. Hours
without traffic do not appear.

**Acceptance criteria**

- Lines: `13:00 ###    3`, `14:00 ##     2`, `16:00 ####   4`.
- The hour is extracted with `cut`, not `awk`.
- The bar is made with `printf '%*s'` and `tr`.

### Hard: error triage

For an eleven-line log print: total requests and error rate (status 400 or above); errors split into
`4xx` and `5xx`; the failing paths, worst first; and the clients behind the errors joined with an owner
table (`office`, `partner`, `customer`), worst first.

**Acceptance criteria**

- `requests: 11, errors: 6 (54%)`; 3 client and 3 server errors.
- `/api/items` appears first with 3 errors.
- The owner table is aligned with `column -t` and uses `join` on sorted input.
- Status codes are matched as a column (`" 404`), so a byte count never counts as an error.

### Break it

This script has **two bugs**: it reports too many 404s and the "top clients" list is wrong. Save as
`break-it.sh`, run it, and fix it. The right answers are `404 responses: 1` and `203.0.113.5` with 3
requests on top.

```bash
#!/usr/bin/env bash
cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2025:13:05:36 +0000] "GET /index.html HTTP/1.1" 200 404
198.51.100.7 - - [10/Oct/2025:13:15:40 +0000] "GET /missing HTTP/1.1" 404 153
203.0.113.5 - - [10/Oct/2025:13:25:01 +0000] "GET /index.html HTTP/1.1" 200 2326
192.0.2.44 - - [10/Oct/2025:14:06:12 +0000] "GET /index.html HTTP/1.1" 200 2326
203.0.113.5 - - [10/Oct/2025:14:07:03 +0000] "GET /about.html HTTP/1.1" 200 1840
EOF

echo "404 responses: $(grep -c 404 access.log)"

echo "top clients:"
cut -d' ' -f1 access.log | uniq -c | sort | tail -n 2
```

**Expected output**

```text
404 responses: 2
top clients:
      1 203.0.113.5
      1 203.0.113.5
```

<details>
<summary>Hint</summary>

Look at the first log line: its *byte count* is 404. And what must happen to the IP list before `uniq -c`,
and how should the counts be sorted?

</details>

## Solutions

<details>
<summary>Easy</summary>

`sort -k1,1nr -k2` orders by count (numeric, reversed) and then by the second column, which makes ties
deterministic.

```bash
#!/usr/bin/env bash
# Day 29 easy: the three most requested paths.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/access.log" <<'EOF'
203.0.113.5 - - [10/Oct/2025:13:05:36 +0000] "GET /index.html HTTP/1.1" 200 2326
198.51.100.7 - - [10/Oct/2025:13:15:40 +0000] "GET /about.html HTTP/1.1" 200 1840
203.0.113.5 - - [10/Oct/2025:13:25:01 +0000] "GET /missing HTTP/1.1" 404 153
192.0.2.44 - - [10/Oct/2025:14:06:12 +0000] "POST /api/login HTTP/1.1" 200 512
198.51.100.7 - - [10/Oct/2025:14:07:03 +0000] "GET /index.html HTTP/1.1" 200 2326
203.0.113.5 - - [10/Oct/2025:14:17:30 +0000] "POST /api/login HTTP/1.1" 401 64
192.0.2.44 - - [10/Oct/2025:15:19:30 +0000] "GET /index.html HTTP/1.1" 200 2326
EOF

echo "top paths:"
cut -d'"' -f2 "${work}/access.log" | cut -d' ' -f2 | sort | uniq -c | sort -k1,1nr -k2 | head -n 3

rm -rf -- "$work"
```

**Expected output**

```text
top paths:
      3 /index.html
      2 /api/login
      1 /about.html
```

</details>

<details>
<summary>Medium</summary>

`printf '%*s' "$count" ''` prints `count` spaces, and `tr ' ' '#'` turns them into bars. The loop reads
`count hour` pairs straight from `uniq -c` output.

```bash
#!/usr/bin/env bash
# Day 29 medium: a text histogram of requests per hour.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/access.log" <<'EOF'
1.1.1.1 - - [10/Oct/2025:13:05:36 +0000] "GET /a HTTP/1.1" 200 1
1.1.1.1 - - [10/Oct/2025:13:15:40 +0000] "GET /a HTTP/1.1" 200 1
1.1.1.1 - - [10/Oct/2025:13:25:01 +0000] "GET /a HTTP/1.1" 200 1
1.1.1.1 - - [10/Oct/2025:14:06:12 +0000] "GET /a HTTP/1.1" 200 1
1.1.1.1 - - [10/Oct/2025:14:07:03 +0000] "GET /a HTTP/1.1" 200 1
1.1.1.1 - - [10/Oct/2025:16:17:30 +0000] "GET /a HTTP/1.1" 200 1
1.1.1.1 - - [10/Oct/2025:16:18:11 +0000] "GET /a HTTP/1.1" 200 1
1.1.1.1 - - [10/Oct/2025:16:19:30 +0000] "GET /a HTTP/1.1" 200 1
1.1.1.1 - - [10/Oct/2025:16:20:00 +0000] "GET /a HTTP/1.1" 200 1
EOF

echo "requests per hour"
cut -d'[' -f2 "${work}/access.log" | cut -d: -f2 | sort | uniq -c |
    while read -r count hour; do
        bar="$(printf '%*s' "$count" '' | tr ' ' '#')"
        printf '%s:00 %-6s %d\n' "$hour" "$bar" "$count"
    done

rm -rf -- "$work"
```

**Expected output**

```text
requests per hour
13:00 ###    3
14:00 ##     2
16:00 ####   4
```

</details>

<details>
<summary>Hard</summary>

`grep -oE '" [45][0-9]{2} '` keeps only the status field; `tr -d '" '` strips the delimiters and `cut -c1`
keeps the class digit. `join` needs both inputs sorted on the key, so the counts are sorted first.

```bash
#!/usr/bin/env bash
# Day 29 hard: error triage report - counts by class, top failing paths, noisiest owners.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"
cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2025:13:05:36 +0000] "GET /index.html HTTP/1.1" 200 2326
198.51.100.7 - - [10/Oct/2025:13:15:40 +0000] "GET /about.html HTTP/1.1" 200 1840
203.0.113.5 - - [10/Oct/2025:13:25:01 +0000] "GET /missing HTTP/1.1" 404 153
192.0.2.44 - - [10/Oct/2025:14:06:12 +0000] "POST /api/login HTTP/1.1" 200 512
198.51.100.7 - - [10/Oct/2025:14:07:03 +0000] "GET /api/items HTTP/1.1" 500 87
203.0.113.5 - - [10/Oct/2025:14:17:30 +0000] "GET /logo.png HTTP/1.1" 200 404
192.0.2.44 - - [10/Oct/2025:14:18:11 +0000] "POST /api/login HTTP/1.1" 401 64
198.51.100.7 - - [10/Oct/2025:15:08:45 +0000] "GET /api/items HTTP/1.1" 503 87
203.0.113.5 - - [10/Oct/2025:15:09:02 +0000] "GET /api/items HTTP/1.1" 503 87
192.0.2.44 - - [10/Oct/2025:15:19:30 +0000] "GET /index.html HTTP/1.1" 200 2326
198.51.100.7 - - [10/Oct/2025:15:20:00 +0000] "GET /old-page HTTP/1.1" 404 153
EOF
printf '%s\n' '192.0.2.44 office' '198.51.100.7 partner' '203.0.113.5 customer' > owners.txt

# Status code is the 3rd-from-last space-separated field; the status class is its first digit.
total="$(wc -l < access.log)"
errors="$(grep -cE '" [45][0-9]{2} ' access.log)"
echo "requests: ${total}, errors: ${errors} ($(( errors * 100 / total ))%)"

echo "--- errors by class"
grep -oE '" [45][0-9]{2} ' access.log | tr -d '" ' | cut -c1 | sort | uniq -c |
    sed -e 's/ 4$/ 4xx client errors/' -e 's/ 5$/ 5xx server errors/'

echo "--- failing paths, worst first"
grep -E '" [45][0-9]{2} ' access.log | cut -d'"' -f2 | cut -d' ' -f2 | sort | uniq -c | sort -k1,1nr -k2

echo "--- who causes the errors"
grep -E '" [45][0-9]{2} ' access.log | cut -d' ' -f1 | sort | uniq -c | awk '{ print $2, $1 }' | sort > err-counts.txt
join owners.txt err-counts.txt | sort -k3,3nr | column -t

cd / && rm -rf -- "$work"
```

**Expected output**

```text
requests: 11, errors: 6 (54%)
--- errors by class
      3 4xx client errors
      3 5xx server errors
--- failing paths, worst first
      3 /api/items
      1 /api/login
      1 /missing
      1 /old-page
--- who causes the errors
198.51.100.7  partner   3
203.0.113.5   customer  2
192.0.2.44    office    1
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `grep -c 404` also matched the byte count `404`; match the status column `'" 404 '`. Bug 2:
`uniq -c` without `sort` only merged neighbours, and `sort` without `-n` ordered the counts as text.
Sort first, count, then `sort -rn`.

```bash
#!/usr/bin/env bash
# Fixed: match the status column, not any "404" in the line; sort BEFORE uniq; sort counts numerically.
set -euo pipefail

cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2025:13:05:36 +0000] "GET /index.html HTTP/1.1" 200 404
198.51.100.7 - - [10/Oct/2025:13:15:40 +0000] "GET /missing HTTP/1.1" 404 153
203.0.113.5 - - [10/Oct/2025:13:25:01 +0000] "GET /index.html HTTP/1.1" 200 2326
192.0.2.44 - - [10/Oct/2025:14:06:12 +0000] "GET /index.html HTTP/1.1" 200 2326
203.0.113.5 - - [10/Oct/2025:14:07:03 +0000] "GET /about.html HTTP/1.1" 200 1840
EOF

echo "404 responses: $(grep -c '" 404 ' access.log)"

echo "top clients:"
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head -n 2
```

**Expected output**

```text
404 responses: 1
top clients:
      3 203.0.113.5
      1 198.51.100.7
```

</details>

Solution files live in [`solutions/day-29/`](solutions/day-29/).

## Self-check

1. Why must you `sort` before `uniq -c`?
2. How do you sort counts from largest to smallest?
3. What is the difference between `grep 404` and an exact status match?
4. What does `cut -d' ' -f1` print?
5. What must be true of the inputs to `join`?

<details>
<summary>Answers</summary>

1. `uniq` only collapses adjacent duplicate lines.
2. `sort -rn` (or `-k1,1nr`).
3. `grep 404` matches the text anywhere in the line; an exact match checks the status column only.
4. The first space-separated field of each line.
5. Both must be sorted on the join key.

</details>

## Cheat sheet

| Pipeline | Meaning |
|----------|---------|
| `cut -d' ' -f1 f \| sort \| uniq -c \| sort -rn \| head` | Top values of column 1 |
| `grep -E 'a\|b' f` | Lines with a or b |
| `grep -v x f` / `grep -c x f` | Invert / count |
| `grep -B1 -A1 x f` | Context lines |
| `grep -F 'a.b' f` | Literal text |
| `tr -s ' '` | Squeeze repeated spaces |
| `wc -l < f` | Line count |
| `paste a b` | Side by side |
| `join a b \| column -t` | Join sorted files, align |
| `sort -k2,2 -n` | Sort by field 2 numerically |

## Further reading

- [Greg's Wiki: BashFAQ/002](https://mywiki.wooledge.org/BashFAQ/002): why you should avoid parsing
  command output you do not control, and what to do instead.
- [Unix as IDE: filters](https://blog.sanctum.geek.nz/series/unix-as-ide/): an essay series on using small
  filters together (an optional read).

**Next:** [Day 30](day-30.md)
