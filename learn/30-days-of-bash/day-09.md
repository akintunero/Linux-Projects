# Day 09: Arrays

> **Time:** ~55 min · **Level:** Intermediate
> **Prerequisites:** [Day 08](day-08.md)

## Goal

By the end of this lesson you can:

- Create indexed arrays, loop over them with correct quoting, append, slice and measure them.
- Use associative arrays (`declare -A`) as lookup tables and counters.
- Read a file into an array with `mapfile` and build commands safely in an array.

## Concepts

### Indexed arrays

```bash
servers=(web01 db01 "cache 01")      # quote elements that contain spaces
echo "${servers[0]}"                 # web01
echo "${servers[-1]}"                # last element
echo "${#servers[@]}"                # number of elements: 3
servers+=(queue01)                   # append
```

| Expansion | Result |
|-----------|--------|
| `"${arr[@]}"` | Every element as a **separate word** (use this in loops and calls) |
| `"${arr[*]}"` | All elements joined into one word |
| `${#arr[@]}` | Element count |
| `${!arr[@]}` | The indices (or keys) |
| `${arr[@]:1:2}` | Slice: two elements from index 1 |
| `unset 'arr[1]'` | Remove an element (leaves a gap in the indices) |

> [!WARNING]
> `$arr` means only `${arr[0]}`, and unquoted `${arr[@]}` re-splits elements on spaces. Always write
> `"${arr[@]}"`.

### Associative arrays

An associative array maps string keys to values. It must be declared with `declare -A`; otherwise
Bash treats the keys as arithmetic and everything collapses into index 0.

```bash
declare -A port=([http]=80 [https]=443)
port[ssh]=22
echo "${port[ssh]}"
[[ -v port[ftp] ]] || echo "no ftp entry"     # test whether a key exists
```

Key order is **not** defined. Sort the keys if you need stable output.

Counting with a default: `count[$word]=$(( ${count[$word]:-0} + 1 ))`.

### Reading files into arrays

```bash
mapfile -t lines < list.txt          # one element per line, newline stripped (-t)
```

### Building commands safely

An array keeps arguments with spaces intact. This is how scripts assemble optional flags:

```bash
args=(-czf "backup 2025.tgz")
[[ -n ${EXCLUDE:-} ]] && args+=(--exclude "$EXCLUDE")
tar "${args[@]}" -C /srv data
```

## Worked example

Save as `arrays.sh` and run it in an empty directory.

```bash
#!/usr/bin/env bash
# arrays.sh - indexed and associative arrays
set -euo pipefail

# Indexed arrays: quote elements that contain spaces.
servers=(web01 db01 "cache 01")
echo "count: ${#servers[@]}"
echo "first: ${servers[0]}, last: ${servers[-1]}"

servers+=(queue01)                       # append
for s in "${servers[@]}"; do             # always "${arr[@]}" with the quotes
    echo "- $s"
done
echo "slice (2 items from index 1): ${servers[*]:1:2}"
echo "indices: ${!servers[*]}"

unset 'servers[1]'                       # remove db01: the indices now have a gap
echo "after unset, indices: ${!servers[*]} (count ${#servers[@]})"

# mapfile: read a file's lines into an array, one element per line.
printf '%s\n' alpha beta gamma > list.txt
mapfile -t lines < list.txt
echo "read ${#lines[@]} lines, second is ${lines[1]}"

# Building a command safely in an array.
find_args=(. -maxdepth 1 -name '*.txt')
find "${find_args[@]}"

# Associative arrays (Bash 4+): declare -A is required.
declare -A port=([http]=80 [https]=443 [ssh]=22)
port[smtp]=25
echo "ssh uses port ${port[ssh]}"
if [[ -v port[ftp] ]]; then
    echo "ftp is known"
else
    echo "ftp is not in the table"
fi
# Key order is not defined, so sort when you need stable output.
mapfile -t keys <<< "$(printf '%s\n' "${!port[@]}" | sort)"
for key in "${keys[@]}"; do
    printf '%-6s %s\n' "$key" "${port[$key]}"
done
```

**Expected output**

```text
count: 3
first: web01, last: cache 01
- web01
- db01
- cache 01
- queue01
slice (2 items from index 1): db01 cache 01
indices: 0 1 2 3
after unset, indices: 0 2 3 (count 3)
read 3 lines, second is beta
./list.txt
ssh uses port 22
ftp is not in the table
http   80
https  443
smtp   25
ssh    22
```

After `unset 'servers[1]'` the indices are `0 2 3`, not `0 1 2`. That is why you loop with
`"${arr[@]}"` or `"${!arr[@]}"` and never assume `0..count-1`. Also note that `ssh` appears last
only because we sorted the keys.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `for f in ${files[@]}` | Re-splits `my file.txt` into two words | `for f in "${files[@]}"` |
| `echo "$files"` | Prints only the first element | `"${files[@]}"` or `${#files[@]}` for the count |
| `ports=([http]=80)` without `declare -A` | Keys become arithmetic: all land in index 0 | `declare -A ports=(...)` |
| `arr=$(ls)` | A string, not an array, and it splits badly | `mapfile -t arr < <(...)` or a glob: `arr=(*.txt)` |
| `${arr[@]}` where `*` was meant | `@` and `*` differ only inside quotes | `"${arr[@]}"` for lists, `"${arr[*]}"` for joining |
| Using index `n` after `unset` | Indices have gaps | Loop over `"${!arr[@]}"` |
| Assuming associative order | Order is arbitrary | Pipe the keys through `sort` |

## Exercises

### Easy: backup targets

Create an array of three backup targets (one with a space in the path), append a fourth, and print
`Backup targets (4):` followed by a numbered list `1. /etc`, `2. ...`, then the last element.

**Acceptance criteria**

- The path with a space prints intact on one line.
- The count comes from `${#targets[@]}`, not a literal.
- Numbering starts at 1 although indices start at 0.

### Medium: status-code counter

Given the array `statuses=(200 200 404 500 200 404 301 503)`, count how many times each code occurs
with an associative array. Print the codes in ascending order as `200: 3`, and at the end print the
total number of 5xx responses.

**Acceptance criteria**

- Output lines in order: 200, 301, 404, 500, 503.
- `server errors (5xx): 2`.
- Adding another code to the array changes the report without touching the logic.

### Hard: group files by extension

In a temporary directory create `a.txt b.txt c.jpg d.jpg e.jpg Makefile notes.md "my doc.txt"`. Build
two associative arrays: a count per extension and a comma-separated list of names per extension.
Files without a dot belong to `(none)`. Print one aligned line per extension, sorted by extension.

**Acceptance criteria**

- `txt` shows a count of 3 and includes `my doc.txt` with its space.
- `(none)` lists `Makefile`.
- The directory is cleaned up afterwards and the script uses `nullglob`.

### Break it

This script has **three bugs**. Save it as `break-it.sh`, run it, and fix it so that it lists two
items, reports `count: 2`, and `http is 80` with 2 entries.

```bash
#!/usr/bin/env bash
files=("my file.txt" b.txt)

for f in ${files[@]}; do
    echo "item: $f"
done

echo "count: $files"

ports=([http]=80 [https]=443)
echo "http is ${ports[http]}"
echo "entries: ${#ports[@]}"
```

**Expected output**

```text
item: my
item: file.txt
item: b.txt
count: my file.txt
http is 443
entries: 1
```

<details>
<summary>Hint</summary>

Compare the number of `item:` lines with the number of files. Then ask what `$files` alone expands
to, and what Bash does with `[http]` when the array is not associative.

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 09 easy: a backup target list as an array, with a numbered report.
set -euo pipefail

targets=("/etc" "/var/log" "/home/shared files")
targets+=("/srv/www")

echo "Backup targets (${#targets[@]}):"
for i in "${!targets[@]}"; do
    echo "$(( i + 1 )). ${targets[i]}"
done
echo "Last target: ${targets[-1]}"
```

**Expected output**

```text
Backup targets (4):
1. /etc
2. /var/log
3. /home/shared files
4. /srv/www
Last target: /srv/www
```

</details>

<details>
<summary>Medium</summary>

Keys come from `${!hits[@]}`; `sort -n` orders them numerically and `mapfile` brings them back into
an array. The pattern `5??` in `[[ ]]` is a glob: "5 followed by any two characters".

```bash
#!/usr/bin/env bash
# Day 09 medium: count HTTP status codes with an associative array.
set -euo pipefail

statuses=(200 200 404 500 200 404 301 503)
declare -A hits

for code in "${statuses[@]}"; do
    hits[$code]=$(( ${hits[$code]:-0} + 1 ))
done

mapfile -t codes <<< "$(printf '%s\n' "${!hits[@]}" | sort -n)"

server_errors=0
for code in "${codes[@]}"; do
    printf '%s: %s\n' "$code" "${hits[$code]}"
    if [[ $code == 5?? ]]; then
        server_errors=$(( server_errors + hits[$code] ))
    fi
done
echo "server errors (5xx): ${server_errors}"
```

**Expected output**

```text
200: 3
301: 1
404: 2
500: 1
503: 1
server errors (5xx): 2
```

</details>

<details>
<summary>Hard</summary>

`names[$ext]+="..."` appends to a string element. The trailing `", "` is removed with
`${names[$ext]%, }`.

```bash
#!/usr/bin/env bash
# Day 09 hard: group the files of a directory by extension.
# Works on a temporary directory only.
set -euo pipefail
shopt -s nullglob

work="$(mktemp -d)"
cd "$work"
touch a.txt b.txt c.jpg d.jpg e.jpg Makefile notes.md "my doc.txt"

declare -A count names
for f in *; do
    [[ -f $f ]] || continue
    if [[ $f == *.* ]]; then
        ext="${f##*.}"
    else
        ext="(none)"
    fi
    count[$ext]=$(( ${count[$ext]:-0} + 1 ))
    names[$ext]+="${f}, "
done

mapfile -t exts <<< "$(printf '%s\n' "${!count[@]}" | sort)"
for ext in "${exts[@]}"; do
    list="${names[$ext]%, }"                      # strip the trailing ", "
    printf '%-7s %d  %s\n' "$ext" "${count[$ext]}" "$list"
done

cd / && rm -rf -- "$work"
```

**Expected output**

```text
(none)  1  Makefile
jpg     3  c.jpg, d.jpg, e.jpg
md      1  notes.md
txt     3  a.txt, b.txt, my doc.txt
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `${files[@]}` unquoted splits `my file.txt`. Bug 2: `$files` is just the first element; the
count is `${#files[@]}`. Bug 3: without `declare -A`, `[http]` and `[https]` are both evaluated as
the number 0, so the second assignment overwrote the first.

```bash
#!/usr/bin/env bash
# Fixed: quote "${files[@]}", use ${#files[@]} for the count, and declare -A for string keys.
set -euo pipefail

files=("my file.txt" b.txt)

for f in "${files[@]}"; do
    echo "item: $f"
done

echo "count: ${#files[@]}"

declare -A ports=([http]=80 [https]=443)
echo "http is ${ports[http]}"
echo "entries: ${#ports[@]}"
```

**Expected output**

```text
item: my file.txt
item: b.txt
count: 2
http is 80
entries: 2
```

</details>

Solution files live in [`solutions/day-09/`](solutions/day-09/).

## Self-check

1. How do you get the number of elements of `arr`?
2. What is the difference between `"${arr[@]}"` and `"${arr[*]}"`?
3. What must you do before using string keys?
4. How do you append one element?
5. Which command reads a file into an array, one line per element?

<details>
<summary>Answers</summary>

1. `${#arr[@]}`.
2. `@` gives each element as its own word; `*` joins them into one word using the first character of
   `IFS`.
3. Declare the array with `declare -A`.
4. `arr+=(value)`.
5. `mapfile -t arr < file` (also called `readarray`).

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `a=(x y "z w")` | Create |
| `"${a[@]}"` | All elements, safely |
| `${#a[@]}` | Count |
| `${!a[@]}` | Indices / keys |
| `a+=(v)` | Append |
| `${a[@]:i:n}` | Slice |
| `unset 'a[i]'` | Remove element |
| `declare -A m; m[k]=v` | Associative array |
| `[[ -v m[k] ]]` | Key exists? |
| `mapfile -t a < file` | File lines to array |

## Further reading

- [Greg's Wiki: BashGuide/Arrays](https://mywiki.wooledge.org/BashGuide/Arrays): a beginner-friendly
  tour with the quoting pitfalls explained.
- [Greg's Wiki: BashFAQ/005](https://mywiki.wooledge.org/BashFAQ/005): how to use arrays, with many
  practical recipes.

**Next:** [Day 10](day-10.md)
