# Day 11: Editing Streams with `sed`

> **Time:** ~55 min · **Level:** Intermediate
> **Prerequisites:** [Day 10](day-10.md)

## Goal

By the end of this lesson you can:

- Substitute, delete and print lines with `sed`, using line numbers and patterns as addresses.
- Edit a configuration file in place with a backup, and explain how to undo it.
- Write an idempotent "set this option" helper that is safe to run twice.

## Concepts

`sed` (stream editor) reads input line by line, applies commands, and writes the result to stdout.
**It does not change the input file** unless you ask with `-i`.

### Substitute: the command you will use 90% of the time

```bash
sed 's/old/new/' file          # first match on each line
sed 's/old/new/g' file         # every match on each line
sed 's/old/new/I' file         # ignore case (GNU sed)
sed 's#/var/lib#/srv#' file    # any character can be the delimiter: handy for paths
```

In the replacement, `&` stands for the whole match and `\1`, `\2` for captured groups. Use `-E`
for extended regular expressions (groups with plain `( )`, `+`, `?`, `|`).

### Addresses: which lines to act on

| Address | Lines |
|---------|-------|
| `3` | line 3 |
| `2,4` | lines 2 to 4 |
| `$` | the last line |
| `/regex/` | lines matching the pattern |
| `/start/,/end/` | from the first match of `start` to the next match of `end` |
| `!` after address | invert: `/^#/!d` |

### Common commands

| Command | Meaning |
|---------|---------|
| `p` | print (use with `-n` to suppress default printing) |
| `d` | delete the line |
| `s` | substitute |
| `i\`, `a\`, `c\` | insert before / append after / change the line |
| `y/abc/xyz/` | transliterate characters |

### Editing in place, safely

```bash
sed -i.bak 's/^port=.*/port=9090/' app.conf   # edits app.conf, keeps app.conf.bak
```

> [!WARNING]
> `sed -i` rewrites the file immediately. Always pass a backup suffix while learning, test your
> command **without** `-i` first, and remember the undo: `mv app.conf.bak app.conf`.
> On macOS (BSD sed) the syntax is `sed -i '' ...`; GNU sed accepts `-i` with or without a suffix.

### Quoting rules for `sed` in scripts

- Single quotes keep the shell away from your pattern (`$`, `\`, `*`).
- To use a **shell variable** inside the expression, switch to double quotes:
  `sed "s/^host=.*/host=${new_host}/"`. Make sure the value contains no delimiter character.
- Never redirect to the same file you are reading: `sed ... f > f` empties `f`.

## Worked example

Save as `sed.sh` and run it in an empty directory. Each numbered section is one idea.

```bash
#!/usr/bin/env bash
# sed.sh - stream editing: substitute, print, delete, edit in place
set -euo pipefail

cat > app.conf <<'EOF'
# Application settings
port=8080
debug=true
#log_level=info
data_dir=/var/lib/app
EOF

echo "--- 1. substitute (first match per line)"
sed 's/debug=true/debug=false/' app.conf

echo "--- 2. print only matching lines (-n with p)"
sed -n '/^port/p' app.conf

echo "--- 3. delete comment lines"
sed '/^#/d' app.conf

echo "--- 4. line ranges"
sed -n '2,3p' app.conf

echo "--- 5. other delimiter for paths"
sed 's#/var/lib/app#/srv/app#' app.conf | tail -n 1

echo "--- 6. uncomment, using two expressions"
sed -e 's/^#log_level/log_level/' -e 's/info/debug/' app.conf | tail -n 2

echo "--- 7. & is the whole match; -E enables extended regex"
sed -E 's/[0-9]+/<&>/' app.conf | sed -n '2p'
sed -E 's/^([a-z_]+)=(.*)$/\2 <- \1/' app.conf | sed -n '2,3p'

echo "--- 8. edit in place, keeping a backup"
sed -i.bak 's/^port=.*/port=9090/' app.conf
diff app.conf.bak app.conf || true
```

**Expected output**

```text
--- 1. substitute (first match per line)
# Application settings
port=8080
debug=false
#log_level=info
data_dir=/var/lib/app
--- 2. print only matching lines (-n with p)
port=8080
--- 3. delete comment lines
port=8080
debug=true
data_dir=/var/lib/app
--- 4. line ranges
port=8080
debug=true
--- 5. other delimiter for paths
data_dir=/srv/app
--- 6. uncomment, using two expressions
log_level=debug
data_dir=/var/lib/app
--- 7. & is the whole match; -E enables extended regex
port=<8080>
8080 <- port
true <- debug
--- 8. edit in place, keeping a backup
2c2
< port=8080
---
> port=9090
```

Section 8 ends with `diff`. A status of 1 from `diff` simply means "the files differ", which is why
the line ends with `|| true`.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `sed 's/x/$var/'` | Single quotes: the text `$var` is inserted literally | Use double quotes: `sed "s/x/${var}/"` |
| `sed 's/a/usr/local/b/'` | The `/` inside the text ends the expression early | Use another delimiter: `s\|a\|/usr/local\|` |
| `sed 's/a/b/' f > f` | The shell truncates `f` before `sed` reads it | `sed -i.bak ...` or a temp file |
| Forgetting `g` | Only the first match per line changes | `s/a/b/g` |
| Unescaped `.` in a pattern | `.` matches any character | `\.` for a literal dot |
| `sed -i` with no test run | One typo rewrites the file | Run without `-i` first; keep `.bak` |
| `sed 's/(a)/\1/'` | Basic regex treats `(` literally | Add `-E` |

## Exercises

### Easy: flip one setting

In a temporary directory write `app.conf` with `port=8080`, `debug=true` and `name=shop`. Use
`sed -i.bak` to set `debug=false`, then show the difference between the backup and the new file.

**Acceptance criteria**

- `app.conf.bak` still has `debug=true`; `app.conf` has `debug=false`; other lines are untouched.
- The `diff` output shows exactly one changed line.
- The script does not fail even though `diff` exits with status 1.

### Medium: anonymise an access log

Given three nginx log lines, replace the last octet of each client IP with `x`
(`203.0.113.5` becomes `203.0.113.x`) and write the result to `access.anon.log`. Prove no full IP
is left by counting matching lines with `grep -c`.

**Acceptance criteria**

- Only the IP at the start of the line is changed; timestamps and numbers elsewhere are untouched.
- The original file is unchanged.
- The proof line reports `0`.

### Hard: idempotent `set_option`

Write `set_option FILE KEY VALUE`. If `KEY=` exists, even commented out with `#`, replace that line
with `KEY=VALUE`; otherwise append `KEY=VALUE`. Apply it to a file for `port`, `log_level` (currently
commented) and `workers` (missing), then apply the same three calls again and prove with `cmp -s`
that nothing changed.

**Acceptance criteria**

- Final file: `# settings`, `port=9090`, `log_level=debug`, `workers=4`.
- Second run leaves the file byte-for-byte identical.
- Only temporary files are touched.

### Break it

This script has **three bugs**. Save it as `break-it.sh`, run it in an empty directory, and fix it so
the final file shows `host = cache.example.com` and `base = /opt`.

```bash
#!/usr/bin/env bash
printf 'host=db.example.com\nbase=/usr/local\n' > app.conf
new_host=cache.example.com

sed -i 's/host=.*/host=$new_host/' app.conf
cat app.conf

sed -i 's/=/usr/local/=/opt/' app.conf

sed 's/=/ = /' app.conf > app.conf
echo "final:"
cat app.conf
```

**Expected output**

```text
host=$new_host
base=/usr/local
sed: -e expression #1, char 9: unknown option to `s'
final:
```

<details>
<summary>Hint</summary>

The first `cat` shows the text `$new_host` literally. The error message names the character where
`sed` gave up parsing. Finally, what is in `app.conf` after `> app.conf`?

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 11 easy: change one setting in a config file, keep a backup, show the difference.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"
printf 'port=8080\ndebug=true\nname=shop\n' > app.conf

sed -i.bak 's/^debug=.*/debug=false/' app.conf

echo "--- diff (old vs new)"
diff app.conf.bak app.conf || true
echo "--- new file"
cat app.conf

cd / && rm -rf -- "$work"
```

**Expected output**

```text
--- diff (old vs new)
2c2
< debug=true
---
> debug=false
--- new file
port=8080
debug=false
name=shop
```

</details>

<details>
<summary>Medium</summary>

`-E` makes `( )` capture groups; `\1` re-inserts the first three octets. The `^` anchor limits the
change to the start of the line.

```bash
#!/usr/bin/env bash
# Day 11 medium: anonymise client IPs in an access log by masking the last octet.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"
cat > access.log <<'EOF'
203.0.113.5 - - [10/Oct/2025:13:55:36 +0000] "GET /index.html HTTP/1.1" 200 2326
198.51.100.7 - - [10/Oct/2025:13:56:01 +0000] "GET /missing HTTP/1.1" 404 153
192.0.2.44 - - [10/Oct/2025:13:56:12 +0000] "POST /api/login HTTP/1.1" 200 512
EOF

sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+/\1.x/' access.log > access.anon.log

cat access.anon.log
echo "--- lines with a bare IP left: $(grep -cE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ' access.anon.log || true)"

cd / && rm -rf -- "$work"
```

**Expected output**

```text
203.0.113.x - - [10/Oct/2025:13:55:36 +0000] "GET /index.html HTTP/1.1" 200 2326
198.51.100.x - - [10/Oct/2025:13:56:01 +0000] "GET /missing HTTP/1.1" 404 153
192.0.2.x - - [10/Oct/2025:13:56:12 +0000] "POST /api/login HTTP/1.1" 200 512
--- lines with a bare IP left: 0
```

</details>

<details>
<summary>Hard</summary>

`grep -qE` decides between replace and append, using the same pattern as the `sed` command, so the
two cannot disagree. Run twice, the replace branch writes the identical line.

```bash
#!/usr/bin/env bash
# Day 11 hard: set_option FILE KEY VALUE - idempotent config updater.
# Replaces "key=..." (even if commented out) or appends it. Temporary files only.
set -euo pipefail

set_option() {
    local file="$1" key="$2" value="$3"
    if grep -qE "^#?[[:space:]]*${key}=" "$file"; then
        sed -i -E "s|^#?[[:space:]]*${key}=.*|${key}=${value}|" "$file"
    else
        printf '%s=%s\n' "$key" "$value" >> "$file"
    fi
}

work="$(mktemp -d)"
conf="${work}/app.conf"
printf '# settings\nport=8080\n#log_level=info\n' > "$conf"

set_option "$conf" port 9090           # replace existing
set_option "$conf" log_level debug     # uncomment and change
set_option "$conf" workers 4           # append new
cp "$conf" "${work}/after-first-run"

set_option "$conf" port 9090           # run again: nothing should change
set_option "$conf" log_level debug
set_option "$conf" workers 4

cat "$conf"
if cmp -s "$conf" "${work}/after-first-run"; then
    echo "idempotent: second run changed nothing"
fi

rm -rf -- "$work"
```

**Expected output**

```text
# settings
port=9090
log_level=debug
workers=4
idempotent: second run changed nothing
```

</details>

<details>
<summary>Break it</summary>

Bug 1: single quotes kept `$new_host` literal. Bug 2: the slashes in `/usr/local` ended the `s`
command; use `|` as the delimiter. Bug 3: `> app.conf` truncated the input before `sed` read it; write
to a new file and `mv` it into place.

```bash
#!/usr/bin/env bash
# Fixed: double quotes so the shell expands $new_host, a different delimiter so slashes
# need no escaping, and a temporary file instead of reading and writing the same file.
set -euo pipefail

printf 'host=db.example.com\nbase=/usr/local\n' > app.conf
new_host=cache.example.com

sed -i "s/^host=.*/host=${new_host}/" app.conf
cat app.conf

sed -i 's|^base=/usr/local|base=/opt|' app.conf

sed 's/=/ = /' app.conf > app.conf.new && mv app.conf.new app.conf
echo "final:"
cat app.conf
```

**Expected output**

```text
host=cache.example.com
base=/usr/local
final:
host = cache.example.com
base = /opt
```

</details>

Solution files live in [`solutions/day-11/`](solutions/day-11/).

## Self-check

1. Does `sed 's/a/b/' file` change `file`?
2. What does the `g` flag do?
3. How do you delete every line that starts with `#`?
4. Why use `-i.bak` instead of plain `-i` while learning?
5. How can you use a shell variable inside a `sed` expression?

<details>
<summary>Answers</summary>

1. No, it prints the edited text to stdout; use `-i` to change the file.
2. It replaces all matches on a line, not just the first.
3. `sed '/^#/d' file`.
4. It leaves a backup copy so a mistake is undone with `mv`.
5. Use double quotes (and make sure the value cannot break the expression).

</details>

## Cheat sheet

| Command | Meaning |
|---------|---------|
| `sed 's/a/b/g' f` | Replace all `a` with `b` |
| `sed -n '/re/p' f` | Print matching lines only |
| `sed '/re/d' f` | Delete matching lines |
| `sed -n '2,4p' f` | Print lines 2-4 |
| `sed -E 's/(x)(y)/\2\1/' f` | Extended regex with groups |
| `sed 's#a#b#' f` | Alternate delimiter |
| `sed -i.bak '...' f` | Edit in place with backup |
| `sed -e '...' -e '...' f` | Several commands |
| `sed '$d'`, `sed '1d'` | Drop last / first line |

## Further reading

- [Greg's Wiki: BashFAQ/021](https://mywiki.wooledge.org/BashFAQ/021): how to do search and replace in
  files safely.
- [grymoire: Sed tutorial](https://www.grymoire.com/Unix/Sed.html): a long, example-driven walk
  through sed from basics to advanced scripts.

**Next:** [Day 12](day-12.md)
