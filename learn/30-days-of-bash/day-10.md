# Day 10: Parameter Expansion and String Handling

> **Time:** ~55 min · **Level:** Intermediate
> **Prerequisites:** [Day 09](day-09.md)

## Goal

By the end of this lesson you can:

- Cut paths and file names apart with `${var#}`, `${var%}`, `${var/}` and `${var:}` without
  spawning `sed`, `cut` or `basename`.
- Change case, supply defaults and trim whitespace using only Bash.
- Format text with `printf` and split a string with `read -ra`.

## Concepts

All of these are **parameter expansions**: they work on the value of a variable inside `${...}`.
They are faster than calling external tools in a loop and they handle odd characters correctly.

### Length and substrings

```bash
s="v2.7.10"
echo "${#s}"        # 7  (length)
echo "${s:1}"       # 2.7.10  (from offset 1)
echo "${s:0:3}"     # v2.  (offset 0, length 3)
echo "${s: -2}"     # 10  (from the end; note the space before -)
```

### Remove a prefix or suffix

| Form | Removes |
|------|---------|
| `${v#pat}` | Shortest match of `pat` from the **start** |
| `${v##pat}` | Longest match from the start |
| `${v%pat}` | Shortest match from the **end** |
| `${v%%pat}` | Longest match from the end |

Mnemonic: `#` is on the left of `%` on a US keyboard, as the start is on the left of the end.

```bash
f="archive.tar.gz"
echo "${f%.gz}"     # archive.tar
echo "${f%%.*}"     # archive   (longest suffix starting at the first dot)
echo "${f##*.}"     # gz        (longest prefix ending at the last dot)
p="/var/log/app.log"
echo "${p##*/} ${p%/*}"   # app.log /var/log  (like basename and dirname)
```

### Search and replace

```bash
t="a b c"
echo "${t/ /_}"     # a_b c   (first match)
echo "${t// /_}"    # a_b_c   (all matches)
```

### Case

`${v^^}` uppercases, `${v,,}` lowercases, `${v^}` capitalises the first letter.

### Defaults and alternatives

| Form | Meaning |
|------|---------|
| `${v:-x}` | `x` if `v` is unset or empty |
| `${v:=x}` | Same, and also assigns `x` to `v` |
| `${v:+x}` | `x` if `v` is set and non-empty, otherwise empty |
| `${v:?msg}` | Abort with `msg` if unset or empty |

### Formatting and splitting

```bash
printf 'invoice-%05d.pdf\n' 42            # invoice-00042.pdf
printf '%-10s|%8.2f|\n' "total" 3.14159   # padding and precision
IFS=. read -ra octets <<< "10.0.12.7"     # split on dots into an array
```

Prefer `printf` over `echo` whenever the text might start with `-` or contains backslashes.

## Worked example

A tour of every form, using a path, a version string, a padded line and an IP address. Save as
`strings.sh` and run it.

```bash
#!/usr/bin/env bash
# strings.sh - parameter expansion and string handling without external tools
set -euo pipefail

path="/var/log/nginx/access.log.gz"

echo "length:       ${#path}"
echo "file name:    ${path##*/}"          # remove longest prefix matching */
echo "directory:    ${path%/*}"           # remove shortest suffix matching /*
file="${path##*/}"
echo "first ext:    ${file#*.}"           # remove shortest prefix up to the first dot
echo "last ext:     ${file##*.}"          # remove longest prefix up to the last dot
echo "stem:         ${file%%.*}"          # remove longest suffix from the first dot
echo "no .gz:       ${file%.gz}"

# Substring: ${var:offset:length}
version="v2.7.10"
echo "number part:  ${version:1}"
echo "first 3 chars:${version:0:3}"

# Replace: one match with /, all matches with //
title="my  holiday  photo"
echo "one:          ${title/ /_}"
echo "all:          ${title//  /_}"

# Case conversion
word="Bash"
echo "upper/lower:  ${word^^} ${word,,}"

# Defaults and alternatives
unset maybe || true
echo "default:      ${maybe:-none}"
maybe="set"
echo "alternative:  ${maybe:+is set}"

# Trim whitespace without sed or xargs
padded="   hello world   "
trimmed="${padded#"${padded%%[![:space:]]*}"}"      # strip leading
trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"    # strip trailing
echo "trimmed:      [${trimmed}]"

# Splitting on a delimiter with read -a
IFS=. read -ra parts <<< "10.0.12.7"
echo "octets:       ${#parts[@]} (${parts[0]} ... ${parts[3]})"

# printf for padding and formatting
printf 'invoice-%05d.pdf\n' 42
printf '%-10s|%8.2f|\n' "total" 3.14159
```

**Expected output**

```text
length:       28
file name:    access.log.gz
directory:    /var/log/nginx
first ext:    log.gz
last ext:     gz
stem:         access
no .gz:       access.log
number part:  2.7.10
first 3 chars:v2.
one:          my_ holiday  photo
all:          my_holiday_photo
upper/lower:  BASH bash
default:      none
alternative:  is set
trimmed:      [hello world]
octets:       4 (10 ... 7)
invoice-00042.pdf
total     |    3.14|
```

Read the `stem`, `first ext` and `last ext` lines carefully. They differ only in `#` versus `##` and
`%` versus `%%`. The trim trick strips whitespace in two steps: the inner `${padded%%[![:space:]]*}`
is "the leading whitespace", which the outer `#` then removes.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `${file%.*}` for `archive.tar.gz` | Shortest suffix: gives `archive.tar` | `${file%%.*}` for `archive` |
| `${file#*.}` expecting the last extension | Shortest prefix: gives `tar.gz` | `${file##*.}` |
| `echo "${name}"` meaning length | That prints the value | `${#name}` |
| `${s:-2}` meaning "last two characters" | `:-` is the default operator | `${s: -2}` (space) |
| `${v/a/b}` replacing every `a` | Only the first match | `${v//a/b}` |
| `"$v" == pattern*` quoted pattern | Quoted patterns are literal | Leave the pattern unquoted |
| `echo -n "$x"` in portable scripts | `echo` flags vary | `printf '%s' "$x"` |

## Exercises

### Easy: split a path

From `path="/home/ada/reports/q3-summary.final.pdf"` print `dir`, `file`, `stem` (name without the
last extension) and `ext`. Use only parameter expansion.

**Acceptance criteria**

- `dir: /home/ada/reports`, `stem: q3-summary.final`, `ext: pdf`.
- No call to `basename`, `dirname`, `sed`, `cut` or `awk`.

### Medium: photo rename plan

Given the array `("IMG 0042.JPG" "Holiday  Beach.JPEG" "IMG_7.png")`, print `old -> new` where
`new` is lowercase, spaces and underscores are replaced by `-` (a double space becomes one `-`), and
`.jpeg` becomes `.jpg`. This is a **dry run**: do not rename anything.

**Acceptance criteria**

- `IMG 0042.JPG -> img-0042.jpg`, `Holiday  Beach.JPEG -> holiday-beach.jpg` and
  `IMG_7.png -> img-7.png`.
- `.png` is left alone (no `.jpg` appended).
- Names with spaces survive intact in the left column.

### Hard: parse a URL

Take `https://deploy@example.com:8443/app/status?verbose=1&fmt=json` apart into scheme, user, host,
port, path and query using only parameter expansion and `[[ ]]`. If there is no port, default to 443
for `https` and 80 for `http`.

**Acceptance criteria**

- Prints `host example.com`, `port 8443`, `path /app/status`, `query verbose=1&fmt=json`.
- Changing the URL to `http://example.org/` yields port 80, path `/` and empty user and query.
- No external commands.

### Break it

This script has **three bugs**: it should print stem `archive`, extension `gz` and length `14`. Save
it as `break-it.sh`, run it and fix it.

```bash
#!/usr/bin/env bash
file="archive.tar.gz"

echo "stem: ${file%.*}"
echo "ext: ${file#*.}"
echo "length: ${file}"
```

**Expected output**

```text
stem: archive.tar
ext: tar.gz
length: archive.tar.gz
```

<details>
<summary>Hint</summary>

Two of the bugs are one character each: single versus doubled `%` or `#`. The third is a missing
symbol in front of the variable name.

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 10 easy: split a path into parts with parameter expansion only.
set -euo pipefail

path="/home/ada/reports/q3-summary.final.pdf"

dir="${path%/*}"
file="${path##*/}"
stem="${file%.*}"
ext="${file##*.}"

echo "dir:  ${dir}"
echo "file: ${file}"
echo "stem: ${stem}"
echo "ext:  ${ext}"
```

**Expected output**

```text
dir:  /home/ada/reports
file: q3-summary.final.pdf
stem: q3-summary.final
ext:  pdf
```

</details>

<details>
<summary>Medium</summary>

The `.jpeg` fix lives in an `if` so that `.png` is not touched. Without the condition, `${new%.jpeg}`
removes nothing on `.png` and the unconditional `.jpg` would be appended anyway.

```bash
#!/usr/bin/env bash
# Day 10 medium: dry-run plan for renaming camera photos. Nothing is renamed.
set -euo pipefail

photos=("IMG 0042.JPG" "Holiday  Beach.JPEG" "IMG_7.png")

for old in "${photos[@]}"; do
    new="${old,,}"            # lowercase
    new="${new//  /-}"        # double spaces to a dash
    new="${new// /-}"         # single spaces to a dash
    new="${new//_/-}"         # underscores to a dash
    if [[ $new == *.jpeg ]]; then
        new="${new%.jpeg}.jpg"   # normalise .jpeg to .jpg
    fi
    printf '%-22s -> %s\n' "$old" "$new"
done
```

**Expected output**

```text
IMG 0042.JPG           -> img-0042.jpg
Holiday  Beach.JPEG    -> holiday-beach.jpg
IMG_7.png              -> img-7.png
```

</details>

<details>
<summary>Hard</summary>

Peel the URL from the outside in: scheme, then query, then path, then user, then port. Each step
removes what it has consumed. `\?` is a literal question mark (a bare `?` is a glob).

```bash
#!/usr/bin/env bash
# Day 10 hard: take a URL apart with parameter expansion only.
set -euo pipefail

url="https://deploy@example.com:8443/app/status?verbose=1&fmt=json"

scheme="${url%%://*}"
rest="${url#*://}"                  # deploy@example.com:8443/app/status?verbose=1&fmt=json

query=""
if [[ $rest == *\?* ]]; then
    query="${rest#*\?}"
    rest="${rest%%\?*}"
fi

hostport="${rest%%/*}"
path="/${rest#*/}"
[[ $rest == */* ]] || path="/"

user=""
if [[ $hostport == *@* ]]; then
    user="${hostport%@*}"
    hostport="${hostport#*@}"
fi

host="${hostport%%:*}"
port=""
if [[ $hostport == *:* ]]; then
    port="${hostport##*:}"
else
    case "$scheme" in https) port=443 ;; http) port=80 ;; esac
fi

printf '%-7s %s\n' scheme "$scheme" user "$user" host "$host" port "$port" path "$path" query "$query"
```

**Expected output**

```text
scheme  https
user    deploy
host    example.com
port    8443
path    /app/status
query   verbose=1&fmt=json
```

</details>

<details>
<summary>Break it</summary>

Bug 1 and 2: `%` and `#` remove the **shortest** match; `%%` and `##` remove the longest, which is
what we want here. Bug 3: `${#file}` is the length; `${file}` is the value.

```bash
#!/usr/bin/env bash
# Fixed: %% / ## take the LONGEST match, % / # the shortest; ${#var} is the length.
set -euo pipefail

file="archive.tar.gz"

echo "stem: ${file%%.*}"
echo "ext: ${file##*.}"
echo "length: ${#file}"
```

**Expected output**

```text
stem: archive
ext: gz
length: 14
```

</details>

Solution files live in [`solutions/day-10/`](solutions/day-10/).

## Self-check

1. What does `${f##*/}` give for `f=/etc/hosts`?
2. How do you uppercase a variable in Bash 4+?
3. What is the difference between `${v:-x}` and `${v:=x}`?
4. How do you replace all spaces in `$s` with underscores?
5. Why prefer `printf` to `echo` for arbitrary data?

<details>
<summary>Answers</summary>

1. `hosts`.
2. `${v^^}`.
3. Both yield `x` when `v` is unset or empty; `:=` also stores `x` in `v`.
4. `${s// /_}`.
5. `echo` may treat the data as options or interpret escapes; `printf '%s\n' "$x"` is predictable.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `${#v}` | Length |
| `${v:o:n}` | Substring |
| `${v#p}`, `${v##p}` | Strip prefix (short, long) |
| `${v%p}`, `${v%%p}` | Strip suffix (short, long) |
| `${v/p/r}`, `${v//p/r}` | Replace first / all |
| `${v^^}`, `${v,,}` | Upper / lower case |
| `${v:-d}`, `${v:=d}`, `${v:+a}`, `${v:?m}` | Defaults, alternatives, required |
| `printf '%05d\n' 42` | Formatted output |
| `IFS=. read -ra a <<< "$s"` | Split into an array |

## Further reading

- [Greg's Wiki: BashFAQ/100](https://mywiki.wooledge.org/BashFAQ/100): string manipulation in Bash
  with worked examples.
- [Greg's Wiki: ParamExpansion](https://mywiki.wooledge.org/BashGuide/Parameters#Parameter_Expansion):
  the beginner guide to parameter expansion.

**Next:** [Day 11](day-11.md)
