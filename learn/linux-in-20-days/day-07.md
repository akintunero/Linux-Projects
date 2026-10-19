# Day 07: Text Processing With awk, sed and jq

> **Time:** ~60 min · **Level:** Intermediate
> **Prerequisites:** [Day 06](day-06.md)

## Goal

By the end of this lesson you can:

- Pull columns, filter rows and compute totals and per-key sums with `awk`.
- Substitute, delete and extract text with `sed`, and edit files in place with a backup.
- Read JSON from the command line with `jq` (and know what to install).

## Concepts

`grep` finds lines. `awk` and `sed` change them. Use `awk` when the data has **columns**, `sed` when you are **rewriting text**, and `jq` when the data is **JSON**.

### awk in five lines

`awk 'PATTERN { ACTION }' file` reads each line, splits it into fields `$1`, `$2`... (whitespace by default), and runs ACTION when PATTERN is true.

| Piece | Meaning |
|-------|---------|
| `$1`, `$NF`, `$0` | first field, last field, whole line |
| `NR` | current line number |
| `-F:` or `BEGIN{FS=":"}` | field separator |
| `BEGIN{...}` / `END{...}` | run before the first line / after the last |
| `a[$1]++` | associative array: counts per key |
| `printf "%-8s %d\n", $1, $2` | formatted output |

Use `==` to compare. A single `=` assigns, which is always true and changes your data.

### sed in five lines

| Command | Meaning |
|---------|---------|
| `sed 's/old/new/'` | substitute the first match on each line; add `g` for all matches |
| `sed 's#/a/b#/c/d#'` | any character can be the delimiter, handy for paths |
| `sed -n '2,4p'` | print only lines 2-4 (`-n` silences automatic printing) |
| `sed '/regex/d'` | delete matching lines |
| `sed -i.bak 's/x/y/' f` | edit in place, keep the original as `f.bak` |
| `sed -E` | extended regex (`+`, `?`, `\|`, `()` without backslashes) |

### jq in five lines

`jq` is a separate package (`sudo apt install jq` or `sudo dnf install jq`).

| Filter | Meaning |
|--------|---------|
| `.name` | field of an object |
| `.items[]` | every element of an array |
| `.items[] \| select(.size > 10)` | filter |
| `-r` | raw output, no quotes |
| `.items \| length` | count |

## Worked example

Scenario: the same access log as Day 06. Questions: which requests failed, how much data did we send, and what did each status code cost us?

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

Fields are: `$1` client, `$6` path, `$8` status, `$9` bytes.

Failed requests (status 400 or more) and the total bytes served:

```bash
awk '$8 >= 400 {print $1, $8}' access.log
awk '{sum += $9} END {print sum}' access.log
```

**Expected output:**

```text
198.51.100.7 404
203.0.113.5 500
192.0.2.44 404
6348
```

Per-status counts and bytes with an associative array. `for (k in a)` has no guaranteed order, so pipe through `sort`:

```bash
awk '{c[$8]++} END {for (k in c) print k, c[k]}' access.log | sort
awk '{b[$8] += $9} END {for (k in b) print k, b[k]}' access.log | sort
```

**Expected output:**

```text
200 4
302 1
404 2
500 1
200 5439
302 404
404 418
500 87
```

awk also parses structured files such as `/etc/passwd` (colon-separated). Here with two sample lines so the output is predictable:

```bash
awk -F: '$3 >= 1000 {printf "%-8s uid=%d\n", $1, $3}' <<'EOF'
root:x:0:0:root:/root:/bin/bash
alice:x:1000:1000::/home/alice:/bin/zsh
EOF
```

**Expected output:**

```text
alice    uid=1000
```

Now `sed`. Replace text and show lines 2-3. Note that `sed 's/404/NOTFOUND/'` would also hit the `/login` byte count, so anchor on the status column:

```bash
sed 's/" 404 /" NOTFOUND /' access.log | sed -n '2,3p'
```

**Expected output:**

```text
198.51.100.7 - - [10/Oct/2026:13:55:40] "GET /missing.png HTTP/1.1" NOTFOUND 209
203.0.113.5 - - [10/Oct/2026:13:56:01] "POST /login HTTP/1.1" 302 404
```

Edit a copy in place with a backup, using `#` as the delimiter because the pattern contains `/`:

```bash
cp access.log work.log
sed -i.bak 's#/index.html#/home.html#g' work.log
diff access.log work.log | grep -c '^<'
ls work.log*
```

**Expected output:**

```text
3
work.log
work.log.bak
```

Three lines changed; `work.log.bak` is the pre-edit file. Finally, rewrite each line into `client method path status` with captured groups (GNU sed syntax, as on Debian/Ubuntu/RHEL):

```bash
sed -n 's/^\([0-9.]*\) .*"\(GET\|POST\) \([^ ]*\).*" \([0-9]*\) .*/\1 \2 \3 \4/p' access.log | head -n 2
```

**Expected output:**

```text
203.0.113.5 GET /index.html 200
198.51.100.7 GET /missing.png 404
```

### jq (not run in this lesson's test environment)

`jq` was not installed where this lesson was tested, so the outputs below are described rather than pasted. Install it and compare with what you see:

```bash
cat > hosts.json <<'EOF'
{"hosts":[{"name":"web1","cpu":71,"up":true},{"name":"db1","cpu":23,"up":true},{"name":"cache1","cpu":95,"up":false}]}
EOF
jq -r '.hosts[].name' hosts.json                         # one name per line: web1, db1, cache1
jq -r '.hosts[] | select(.cpu > 70) | .name' hosts.json  # hosts above 70% CPU: web1 and cache1
jq '.hosts | length' hosts.json                          # the number 3
```

> [!WARNING]
> `sed -i` rewrites the file immediately. Always use `-i.bak` (or run without `-i` and review the output
> first). On macOS/BSD `sed -i` requires a suffix argument, so scripts that must run on both should avoid
> `-i` or use `perl -pi.bak`.

**Undo:** `mv work.log.bak work.log`.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `awk '$8 = 200'` | `=` assigns; it is always true and overwrites the field | `awk '$8 == 200'` |
| `sed 's/a/b/'` only changes the first match per line | No `g` flag | `s/a/b/g` |
| `sed 's/var/www/x/y/'` : "unknown option to s" | `/` inside the pattern ends it early | `sed 's#/var/www/x#/y#'` |
| Awk output order looks random | `for (k in arr)` is unordered | pipe to `sort` |
| `awk` average gives "division by zero" | no rows matched | `END { if (n > 0) print s/n }` |
| `awk -v x="$var"` mangles `\n` or backslashes | `-v` processes escapes | read `ENVIRON["VAR"]` instead |
| Parsing JSON with `grep` | JSON is not line-oriented | use `jq` |
| `sed -i` on a symlink or without backup | Original lost | `-i.bak`; check with `diff` |

## Exercises

Reference solutions: [`solutions/day-07/`](solutions/day-07/). Use the log above.

### Easy

Print the total number of bytes served (field 9).

**Acceptance criteria:**

- Output is `6348`.
- Prints `0`, not an empty line, for an empty log (`sum + 0`).

### Medium

For each status code print `STATUS REQUESTS BYTES`, sorted by status.

**Acceptance criteria:**

- Output is exactly `200 4 5439`, `302 1 404`, `404 2 418`, `500 1 87`.
- A single `awk` command does the counting.

### Hard

Write `confset.sh FILE KEY VALUE` that sets `KEY=VALUE` in a config file.

**Acceptance criteria:**

- An active `KEY=...` line is replaced; a commented `#KEY=...` line is left alone.
- A missing key is appended as the last line.
- `FILE.bak` holds the previous contents.
- A `VALUE` containing `/` or `&` (for example `/srv/site/a&b`) is written literally.
- A missing file or a key with spaces gives an error and non-zero exit status.

### Break it

[`solutions/day-07/break-it.sh`](solutions/day-07/break-it.sh) should print the average size of 200 responses (`1043`) and rename `/var/www/index.html` to `/var/www/home.html` in the log. It has three bugs.

**Acceptance criteria:** prints `1043`, and `access.log` contains `/var/www/home.html`.

## Solutions

<details>
<summary>Easy</summary>

```bash
awk '{sum += $9} END {print sum + 0}' access.log
```

Script: [`easy.sh`](solutions/day-07/easy.sh).

</details>

<details>
<summary>Medium</summary>

```bash
awk '{n[$8]++; b[$8] += $9} END {for (s in n) print s, n[s], b[s]}' access.log | sort
```

Script: [`medium.sh`](solutions/day-07/medium.sh).

</details>

<details>
<summary>Hard</summary>

Doing the replacement in awk, with the value passed through the environment, avoids every sed escaping problem:

```bash
cp -p -- "$file" "$file.bak"
K=$key V=$value awk -F= 'BEGIN{OFS="="; k=ENVIRON["K"]; v=ENVIRON["V"]}
                         $1 == k {print k, v; next} {print}' "$file.bak" > "$file"
```

Because the key is compared to field 1 with `==`, `#port` never equals `port`. If `grep -q "^${key}="` finds nothing, append with `printf '%s=%s\n'`. Script with `--self-test`: [`hard.sh`](solutions/day-07/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. `$8 = 200` assigns. Use `$8 == 200`.
2. `s / n` divides by zero when nothing matches. Guard with `if (n > 0)`.
3. The `sed` expression uses `/` as the delimiter while the pattern contains `/`. Use `#`.

Fixed script: [`break-it.fixed.sh`](solutions/day-07/break-it.fixed.sh).

</details>

## Self-check

1. Which awk variable holds the last field of a line?
2. What is the difference between `sed 's/a/b/'` and `sed 's/a/b/g'`?
3. Why is `-i.bak` safer than `-i`?
4. How do you make awk split `/etc/passwd` lines?
5. Which tool would you use for `{"a":[1,2,3]}`?

<details>
<summary>Answers</summary>

1. `$NF`.
2. Without `g` only the first match on each line changes; with `g` all do.
3. It keeps the original as `file.bak`, so a bad edit can be reversed.
4. `awk -F:` (or `BEGIN{FS=":"}`).
5. `jq`.

</details>

## Cheat sheet

```bash
awk '{print $1, $NF}' f                    # columns
awk -F: '$3 >= 1000 {print $1}' /etc/passwd
awk '{s += $9} END {print s + 0}' f        # total
awk '{c[$8]++} END {for (k in c) print k, c[k]}' f | sort
sed 's/old/new/g' f                        # substitute
sed -n '2,4p' f                            # print lines 2-4
sed '/^#/d' f                              # drop comments
sed -i.bak 's#/a#/b#' f                    # in place with backup
jq -r '.items[] | select(.n > 1) | .name' f.json
```

## Further reading

- [jq manual](https://jqlang.org/manual/): the official filter reference for `jq`.
- [Bash Day 04](../30-days-of-bash/day-04.md): turn these one-liners into scripts with proper exit codes.

**Next:** [Day 08](day-08.md)
