# Day 21: Regular Expressions

> **Time:** ~60 min · **Level:** Intermediate
> **Prerequisites:** [Day 20](day-20.md)

## Goal

By the end of this lesson you can:

- Read and write regular expressions with anchors, classes, quantifiers, groups and alternation.
- Use them in `grep -E`, `sed -E` and Bash's `[[ string =~ regex ]]`, including capture groups.
- Avoid the classic traps: quoting, escaping the dot, and expecting a regex to check numeric ranges.

## Concepts

A **regular expression** (regex) is a pattern describing a set of strings. Globs (`*.txt`) match
file names; regexes match text *inside* strings and are far more expressive.

### Building blocks

| Pattern | Matches |
|---------|---------|
| `.` | any one character |
| `\.` | a literal dot |
| `[abc]`, `[a-z]`, `[^0-9]` | one character from the set, in the range, not in the set |
| `[[:digit:]]`, `[[:alpha:]]`, `[[:space:]]` | POSIX classes (locale-safe) |
| `^`, `$` | start / end of the line |
| `\b` | word boundary (GNU) |
| `*`, `+`, `?` | zero or more, one or more, zero or one of the previous item |
| `{3}`, `{2,4}` | exactly 3, between 2 and 4 |
| `( )` | group (and capture) |
| `a\|b` | `a` or `b` (written `a\|b` in extended regex) |

Quantifiers are **greedy**: `.*` takes as much as it can.

### Basic vs extended

Plain `grep` and `sed` use **basic** regex, where `+ ? | ( ) { }` are literal unless backslashed.
Use `-E` for **extended** regex, which behaves the way you expect. Always write `grep -E` and
`sed -E`. Bash's `=~` uses extended regex too.

### `grep` options worth knowing

```bash
grep -E 'pattern' file      # extended regex
grep -o ...                 # print only the matching part
grep -c ...                 # count matching lines
grep -v ...                 # invert: lines that do NOT match
grep -i ...                 # ignore case
grep -n ...                 # show line numbers
grep -r ... dir             # search a directory tree
grep -q ...                 # quiet: only set the exit status (0 = found)
```

### `[[ string =~ regex ]]`

```bash
re='^([0-9]{4})-([0-9]{2})$'
if [[ $date =~ $re ]]; then
    echo "year ${BASH_REMATCH[1]}, month ${BASH_REMATCH[2]}"
fi
```

`BASH_REMATCH[0]` is the whole match; `[1]`, `[2]` are the groups.

> [!WARNING]
> **Never quote the regex on the right of `=~`.** `[[ $x =~ "^a+$" ]]` compares *literal text*, so it
> never matches. Put the pattern in a variable (or write it bare) and leave `$re` unquoted.

### What regex cannot do well

Regex checks shape, not meaning. `[0-9]{1,3}` happily accepts `999`, so after matching an IPv4
address check each octet is `<= 255` in arithmetic. Do not parse HTML or JSON with regex (Day 26
covers JSON).

## Worked example

Seven demonstrations on a three-line sample. Save as `regex.sh`.

```bash
#!/usr/bin/env bash
# regex.sh - regular expressions with grep -E, [[ =~ ]] and sed -E
set -euo pipefail

cat > sample.txt <<'EOF'
alice@example.com logged in from 203.0.113.5 on 2025-10-10
bob@example.org failed login from 198.51.100.7 on 2025-10-11
carol(at)example.com sent order #4521 total $19.99
EOF

echo "--- 1. grep -E: extended regex. -o prints only the match"
grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' sample.txt

echo "--- 2. anchors, classes, quantifiers"
grep -E '^[a-z]+@' sample.txt | cut -c1-20      # starts with letters then @
grep -cE 'order #[0-9]+' sample.txt             # how many lines contain an order number

echo "--- 3. alternation and groups"
grep -oE 'logged in|failed login' sample.txt

echo "--- 4. literal dot: escape it (or put it in brackets)"
printf 'v1.2.3\nv1x2y3\n' | grep -E 'v[0-9]\.[0-9]\.[0-9]'

echo "--- 5. [[ =~ ]] gives you capture groups in BASH_REMATCH"
line="2025-10-10 13:55:36 ERROR disk /dev/sda1 is 93% full"
re='^([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9:]+) ([A-Z]+) (.*)$'   # in a variable, UNQUOTED when used
if [[ $line =~ $re ]]; then
    echo "year=${BASH_REMATCH[1]} month=${BASH_REMATCH[2]} day=${BASH_REMATCH[3]}"
    echo "level=${BASH_REMATCH[5]} message=${BASH_REMATCH[6]}"
fi

echo "--- 6. validating input"
is_ipv4() {
    local ip="$1" octet
    [[ $ip =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]] || return 1
    for octet in "${BASH_REMATCH[@]:1}"; do
        (( 10#$octet <= 255 )) || return 1               # the regex cannot check the range
    done
}
for candidate in 10.0.0.5 10.0.0.256 10.0.0 ab.cd.ef.gh; do
    if is_ipv4 "$candidate"; then echo "valid:   $candidate"; else echo "invalid: $candidate"; fi
done

echo "--- 7. sed -E rewrites with groups: 2025-10-10 -> 10/10/2025"
sed -E 's#([0-9]{4})-([0-9]{2})-([0-9]{2})#\3/\2/\1#' sample.txt | head -n 2 | cut -c1-70
```

**Expected output**

```text
--- 1. grep -E: extended regex. -o prints only the match
203.0.113.5
198.51.100.7
--- 2. anchors, classes, quantifiers
alice@example.com lo
bob@example.org fail
1
--- 3. alternation and groups
logged in
failed login
--- 4. literal dot: escape it (or put it in brackets)
v1.2.3
--- 5. [[ =~ ]] gives you capture groups in BASH_REMATCH
year=2025 month=10 day=10
level=ERROR message=disk /dev/sda1 is 93% full
--- 6. validating input
valid:   10.0.0.5
invalid: 10.0.0.256
invalid: 10.0.0
invalid: ab.cd.ef.gh
--- 7. sed -E rewrites with groups: 2025-10-10 -> 10/10/2025
alice@example.com logged in from 203.0.113.5 on 10/10/2025
bob@example.org failed login from 198.51.100.7 on 11/10/2025
```

In section 6 the regex establishes the *shape* and a loop checks the *range*: that is the usual
division of labour. `10#$octet` forces base 10 so `08` is not treated as octal.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `[[ $ip =~ "^[0-9]+$" ]]` | Quoted regex is a literal string | `re='^[0-9]+$'; [[ $ip =~ $re ]]` |
| `grep '[0-9]+'` | Basic regex: `+` is a literal plus | `grep -E '[0-9]+'` |
| `v[0-9].[0-9]` for a version | `.` matches any character, including `x` | `v[0-9]\.[0-9]` |
| `grep 'a.*b'` and surprise at long matches | Greedy | Use a tighter class: `a[^b]*b` |
| `\d`, `\w`, `\s` in `grep -E` | Perl shorthand: not universally supported | `[0-9]`, `[[:alnum:]_]`, `[[:space:]]` |
| Unanchored validation `[0-9]+` | Matches `abc123def` | Anchor: `^[0-9]+$` |
| Escaping rules differ between tools | `grep -E '\('` vs `sed 's/(/x/'` | Test with `echo ... \| grep -E` first |
| Using `-P` everywhere | Perl regex is not available on macOS grep | Prefer `-E` unless you really need lookaheads |

## Exercises

### Easy: semantic versions

Write a regex for versions like `v2.7.10`, `1.0.0` and `1.0.0-rc1` (optional leading `v`, three
numbers without leading zeros, optional `-suffix`). Test it against seven strings and print the
major, minor and patch numbers for the valid ones.

**Acceptance criteria**

- Valid: `v2.7.10`, `1.0.0`, `1.0.0-rc1`. Invalid: `1.0`, `v1.02.3`, `1.2.3.4`, `latest`.
- The regex is stored in a variable and used unquoted.
- Groups are read from `BASH_REMATCH`.

### Medium: addresses in a log

From a five-line log, extract every IPv4 address with `grep -oE`, count how often each appears with
`sort | uniq -c`, and list them most frequent first. Also count the lines containing `refused` or
`failed`. The text `version 1.2.3` must not be counted as an address.

**Acceptance criteria**

- `203.0.113.5` appears 3 times; `192.0.2.44` twice; `198.51.100.7` and `10.0.0.1` once.
- Ties are ordered by address.
- `1.2.3` is not reported.

### Hard: SSH brute-force report

Given a sample `auth.log`, extract the user name and source address from each
`Failed password for [invalid user] NAME from IP port N` line using `=~` and `BASH_REMATCH`. Print a
table of source, attempts and users tried, then flag every source with three or more attempts.
(Read-only: it analyses a sample, not your real `/var/log`.)

**Acceptance criteria**

- `203.0.113.50` shows 3 attempts with users `root root admin`.
- Only that address is flagged; accepted logins (`Accepted publickey`) and other lines are ignored.
- The regex handles both `for user` and `for invalid user`.

### Break it

This script has **three bugs**: a valid IP is rejected, a number is not found, and a version check
over-counts. Save as `break-it.sh`, run it, and fix it to print `valid ip`, a match for the order
line, and a count of `1`.

```bash
#!/usr/bin/env bash
ip="10.0.0.5"
if [[ $ip =~ "^[0-9]+(\.[0-9]+){3}$" ]]; then
    echo "valid ip"
else
    echo "invalid ip"
fi

printf 'order 42 shipped\n' | grep '[0-9]+' || echo "no number found"

printf 'v1x2y3\nv1.2.3\n' | grep -c 'v[0-9].[0-9].[0-9]'
```

**Expected output**

```text
invalid ip
no number found
2
```

<details>
<summary>Hint</summary>

One bug is the quotes on the right of `=~`, one is the missing `-E`, and one is an unescaped dot.

</details>

## Solutions

<details>
<summary>Easy</summary>

`(0|[1-9][0-9]*)` means "zero, or a number that does not start with 0", which rejects `02`.

```bash
#!/usr/bin/env bash
# Day 21 easy: validate semantic version strings such as v2.7.10 or 1.0.0-rc1.
set -euo pipefail

semver='^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.]+)?$'

for v in v2.7.10 1.0.0 1.0.0-rc1 1.0 v1.02.3 1.2.3.4 latest; do
    if [[ $v =~ $semver ]]; then
        echo "valid:   $v (major ${BASH_REMATCH[1]}, minor ${BASH_REMATCH[2]}, patch ${BASH_REMATCH[3]})"
    else
        echo "invalid: $v"
    fi
done
```

**Expected output**

```text
valid:   v2.7.10 (major 2, minor 7, patch 10)
valid:   1.0.0 (major 1, minor 0, patch 0)
valid:   1.0.0-rc1 (major 1, minor 0, patch 0)
invalid: 1.0
invalid: v1.02.3
invalid: 1.2.3.4
invalid: latest
```

</details>

<details>
<summary>Medium</summary>

`\b` marks word boundaries so a 4-octet pattern does not match inside longer numbers. `1.2.3` has only
three groups, so it fails to match.

```bash
#!/usr/bin/env bash
# Day 21 medium: pull every IPv4 address out of a log and count how often each appears.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/app.log" <<'EOF'
connect from 203.0.113.5 ok
connect from 198.51.100.7 refused
retry 203.0.113.5 then 192.0.2.44
proxy 10.0.0.1 forwarded 203.0.113.5 -> 192.0.2.44
version 1.2.3 started
EOF

echo "unique addresses, most frequent first:"
grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' "${work}/app.log" \
    | sort | uniq -c | sort -k1,1nr -k2,2 | awk '{ printf "%3d  %s\n", $1, $2 }'

echo "lines mentioning refused or failed: $(grep -cE 'refused|failed' "${work}/app.log")"

rm -rf -- "$work"
```

**Expected output**

```text
unique addresses, most frequent first:
  3  203.0.113.5
  2  192.0.2.44
  1  10.0.0.1
  1  198.51.100.7
lines mentioning refused or failed: 1
```

</details>

<details>
<summary>Hard</summary>

The optional group `(invalid user )?` makes `BASH_REMATCH[1]` empty for ordinary users, so the
interesting groups are `[2]` (user) and `[3]` (address). Associative arrays do the counting.

```bash
#!/usr/bin/env bash
# Day 21 hard: find brute-force SSH attempts in an auth log and report offenders.
# Read-only: it analyses a sample log it creates itself.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/auth.log" <<'EOF'
Oct 10 03:12:01 srv sshd[811]: Failed password for root from 203.0.113.50 port 51122 ssh2
Oct 10 03:12:03 srv sshd[811]: Failed password for root from 203.0.113.50 port 51124 ssh2
Oct 10 03:12:06 srv sshd[813]: Failed password for invalid user admin from 203.0.113.50 port 51130 ssh2
Oct 10 03:14:40 srv sshd[820]: Accepted publickey for ada from 192.0.2.10 port 40022 ssh2
Oct 10 03:15:12 srv sshd[825]: Failed password for deploy from 198.51.100.9 port 60011 ssh2
Oct 10 03:15:15 srv sshd[826]: Failed password for invalid user test from 198.51.100.9 port 60013 ssh2
Oct 10 03:16:02 srv sshd[830]: Failed password for ada from 192.0.2.10 port 40050 ssh2
Oct 10 03:16:44 srv CRON[900]: session opened for user root
EOF

re='Failed password for (invalid user )?([A-Za-z0-9_.-]+) from ([0-9.]+) port'
declare -A attempts users
threshold=3

while IFS= read -r line; do
    if [[ $line =~ $re ]]; then
        ip="${BASH_REMATCH[3]}"
        attempts[$ip]=$(( ${attempts[$ip]:-0} + 1 ))
        users[$ip]+="${BASH_REMATCH[2]} "
    fi
done < "${work}/auth.log"

mapfile -t ips <<< "$(printf '%s\n' "${!attempts[@]}" | sort)"
printf '%-16s %-9s %s\n' "SOURCE" "ATTEMPTS" "USERS TRIED"
for ip in "${ips[@]}"; do
    printf '%-16s %-9d %s\n' "$ip" "${attempts[$ip]}" "${users[$ip]% }"
done

echo "--- offenders (>= ${threshold} attempts)"
for ip in "${ips[@]}"; do
    if (( attempts[$ip] >= threshold )); then
        echo "BLOCK CANDIDATE: $ip"
    fi
done

rm -rf -- "$work"
```

**Expected output**

```text
SOURCE           ATTEMPTS  USERS TRIED
192.0.2.10       1         ada
198.51.100.9     2         deploy test
203.0.113.50     3         root root admin
--- offenders (>= 3 attempts)
BLOCK CANDIDATE: 203.0.113.50
```

</details>

<details>
<summary>Break it</summary>

Bug 1: the quoted regex was compared as literal text. Bug 2: basic `grep` treats `+` literally. Bug 3:
the unescaped `.` matched `x` and `y`, so both lines counted.

```bash
#!/usr/bin/env bash
# Fixed: keep the regex unquoted (in a variable), use -E for +, and escape the literal dots.
set -euo pipefail

ip="10.0.0.5"
re='^[0-9]+(\.[0-9]+){3}$'
if [[ $ip =~ $re ]]; then
    echo "valid ip"
else
    echo "invalid ip"
fi

printf 'order 42 shipped\n' | grep -E '[0-9]+' || echo "no number found"

printf 'v1x2y3\nv1.2.3\n' | grep -cE 'v[0-9]\.[0-9]\.[0-9]'
```

**Expected output**

```text
valid ip
order 42 shipped
1
```

</details>

Solution files live in [`solutions/day-21/`](solutions/day-21/).

## Self-check

1. What is the difference between `grep` and `grep -E`?
2. How do you match a literal dot?
3. Why must the regex on the right of `=~` not be quoted?
4. What does `BASH_REMATCH[2]` contain?
5. Why can a regex alone not validate an IPv4 address?

<details>
<summary>Answers</summary>

1. `-E` selects extended syntax, where `+ ? | ( ) { }` are operators.
2. `\.` or `[.]`.
3. Quoted text is matched literally, not as a pattern.
4. The text matched by the second capture group.
5. It checks shape, not numeric range; you still have to compare each octet to 255.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `^ $` | Line start / end |
| `. [abc] [^abc] [a-z]` | Any, set, negated set, range |
| `* + ? {n,m}` | Repetition |
| `( ) \|` | Group, alternation |
| `\. \b` | Literal dot, word boundary |
| `grep -E -o -c -v -i -n -q` | Common flags |
| `sed -E 's/(a)(b)/\2\1/'` | Rewrite with groups |
| `[[ $s =~ $re ]]` | Match; groups in `BASH_REMATCH` |
| `[[:digit:]] [[:space:]]` | POSIX classes |

## Further reading

- [Greg's Wiki: RegularExpression](https://mywiki.wooledge.org/RegularExpression): how Bash's `=~`
  works and why the quoting rules matter.
- [regex101.com](https://regex101.com/): an interactive tester that explains each part of an
  expression (choose the "ERE"/POSIX flavour closest to `grep -E` when available).
- [Regular-Expressions.info](https://www.regular-expressions.info/): a thorough, tool-neutral
  reference on how regexes work.

**Next:** [Day 22](day-22.md)
