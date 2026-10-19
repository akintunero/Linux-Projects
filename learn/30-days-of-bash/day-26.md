# Day 26: JSON in Bash with `jq`

> **Time:** ~60 min · **Level:** Advanced
> **Prerequisites:** [Day 25](day-25.md)

## Goal

By the end of this lesson you can:

- Extract, filter and reshape JSON with `jq` instead of `grep` and `sed`.
- Pass shell variables into `jq` safely and loop over results that contain spaces.
- Update a JSON file atomically and validate it before replacing the original.

## Concepts

JSON is structured data; text tools see only characters. Parsing it with `grep`/`sed` breaks on
whitespace, nesting and escaped quotes. `jq` is a small query language for JSON. Install it with
`sudo apt install jq` (Debian/Ubuntu), `sudo dnf install jq` (Fedora) or `brew install jq`. The
examples below were run with jq 1.7.1.

### Reading values

| Filter | Result |
|--------|--------|
| `.` | The whole document, pretty-printed (also a validity check) |
| `.name` | Field `name` |
| `.servers[0]` | First array element |
| `.servers[]` | Every element, one result each |
| `.servers[].name` | The `name` of every element |
| `.servers \| length` | Pipe the result into another filter |
| `.a?` | Do not fail if `.a` is not an object |

Output options: `-r` prints strings **without** JSON quotes (what you want in scripts), `-c` prints compact
single-line JSON, `-e` sets the exit status from the result (non-zero for `null`/`false`/no output).

### Filtering and shaping

```bash
jq -r '.servers[] | select(.status == "down") | .name' file.json
jq -r '.servers[] | "\(.name) has address \(.ip)"' file.json      # string interpolation
jq -r '.servers[] | [.name, .cpu] | @csv' file.json                # also @tsv, @json, @sh
jq '[.servers[].cpu] | add / length' file.json                      # average
jq '.servers | group_by(.status) | map({status: .[0].status, count: length})' file.json
```

### Shell values go in with `--arg`

> [!WARNING]
> Never splice a shell variable into the filter text (`jq ".name == $x"`). It breaks on quotes and
> lets input change the program, the JSON equivalent of SQL injection. Use `--arg name value` (a string)
> or `--argjson name value` (a number, boolean or JSON), then refer to `$name` in the filter.

```bash
jq --arg n "$want" '.servers[] | select(.name == $n)' file.json
```

### Building and updating JSON

`jq -n` starts from nothing: `jq -n --arg host "$h" '{host: $host, ok: true}'` builds an object with all
quoting done correctly. `|=` updates in place: `.servers |= map(...)`. `jq` never edits a file itself:
write to a temp file, check it, then `mv`.

### Looping over results

```bash
mapfile -t names < <(jq -r '.servers[].name' file.json)
for n in "${names[@]}"; do ...; done
```

A name like `cache 01` stays in one piece because we split on lines, not on spaces.

### APIs

`curl -fsS URL | jq -r '.items[].id'` is the usual pattern. With `set -o pipefail`, a failing `curl` fails the
pipeline. Without `jq`, `python3 -m json.tool` pretty-prints and validates JSON.

## Worked example

Nine small demonstrations on a three-server inventory. Save as `jq.sh` and run it in an empty directory
(needs `jq`).

```bash
#!/usr/bin/env bash
# jq.sh - reading, filtering and building JSON with jq
set -euo pipefail

cat > servers.json <<'EOF'
{
  "generated": "2025-10-10",
  "servers": [
    {"name": "web01",    "ip": "10.0.0.5", "status": "up",   "cpu": 0.42, "tags": ["web", "prod"]},
    {"name": "db01",     "ip": "10.0.0.9", "status": "down", "cpu": 0.00, "tags": ["db", "prod"]},
    {"name": "cache 01", "ip": "10.0.0.7", "status": "up",   "cpu": 0.91, "tags": ["cache"]}
  ]
}
EOF

echo "--- 1. pick values (-r removes the JSON quotes)"
jq -r '.generated' servers.json
jq -r '.servers[].name' servers.json
jq '.servers | length' servers.json

echo "--- 2. filter with select"
jq -r '.servers[] | select(.status == "down") | .name' servers.json
jq -r '.servers[] | select(.cpu > 0.5) | .name' servers.json
jq -r '.servers[] | select(.tags | index("prod")) | .name' servers.json

echo "--- 3. shape the output: string interpolation, tab-separated, CSV"
jq -r '.servers[] | "\(.name) has address \(.ip)"' servers.json
jq -r '.servers[] | [.name, .status] | @tsv' servers.json
jq -r '.servers[] | [.name, .cpu] | @csv' servers.json

echo "--- 4. compute: average CPU, counts per status"
jq '[.servers[].cpu] | add / length' servers.json
jq -c '.servers | group_by(.status) | map({status: .[0].status, count: length})' servers.json

echo "--- 5. pass shell values in with --arg (never paste them into the filter)"
want="db01"
jq --arg n "$want" '.servers[] | select(.name == $n) | .ip' servers.json

echo "--- 6. build new JSON safely; quotes in values are escaped for you"
jq -n --arg host "web \"main\"" --argjson port 8080 '{host: $host, port: $port, ok: true}'

echo "--- 7. update and write back through a temp file"
jq '.servers |= map(if .name == "db01" then .status = "up" else . end)' servers.json > tmp.json
mv tmp.json servers.json
jq -r '[.servers[].status] | join(",")' servers.json

echo "--- 8. loop over names that contain spaces"
mapfile -t names < <(jq -r '.servers[].name' servers.json)
printf 'name: [%s]\n' "${names[@]}"

echo "--- 9. exit status: -e fails on null/false, so scripts can test the data"
jq -e '.servers[] | select(.name == "nope")' servers.json >/dev/null || echo "no such server (exit $?)"
echo '{"broken": ' | jq . >/dev/null 2>&1 || echo "invalid JSON detected"
```

**Expected output**

```text
--- 1. pick values (-r removes the JSON quotes)
2025-10-10
web01
db01
cache 01
3
--- 2. filter with select
db01
cache 01
web01
db01
--- 3. shape the output: string interpolation, tab-separated, CSV
web01 has address 10.0.0.5
db01 has address 10.0.0.9
cache 01 has address 10.0.0.7
web01 up
db01 down
cache 01 up
"web01",0.42
"db01",0.00
"cache 01",0.91
--- 4. compute: average CPU, counts per status
0.44333333333333336
[{"status":"down","count":1},{"status":"up","count":2}]
--- 5. pass shell values in with --arg (never paste them into the filter)
"10.0.0.9"
--- 6. build new JSON safely; quotes in values are escaped for you
{
  "host": "web \"main\"",
  "port": 8080,
  "ok": true
}
--- 7. update and write back through a temp file
up,up,up
--- 8. loop over names that contain spaces
name: [web01]
name: [db01]
name: [cache 01]
--- 9. exit status: -e fails on null/false, so scripts can test the data
no such server (exit 4)
invalid JSON detected
```

In section 2, `select(.tags | index("prod"))` tests list membership. In section 9 `jq -e` exits 4 when
the filter produces no output, which a script can test with `if`.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `for n in $(jq '.servers[].name' f)` | Output keeps quotes and splits on spaces | `mapfile -t names < <(jq -r ... f)` |
| `jq ".name == $x"` | Shell text becomes jq code; strings need quoting | `jq --arg x "$x" '.name == $x'` |
| `jq ... f > f` | The shell empties `f` before `jq` reads it | Write to a temp file, then `mv` |
| Forgetting `-r` | Strings keep their JSON quotes | `jq -r` |
| `grep '"status"' f.json` | Breaks on formatting changes, nesting, escapes | `jq '.. \| .status?'` or a precise path |
| Number comparisons on strings | `"10" < "9"` as text | Check types, use `tonumber` |
| Using `-e` without knowing it | Exit status 1 or 4 for `null`, `false` or empty | Intentional only when testing data |
| Parsing very large files with `jq -s` | Slurping loads everything into memory | Stream with `jq -c '.[]'` or `--stream` |

## Exercises

### Easy: servers that are down

For a JSON document with three servers (one named `db 01`), print the names of those whose status is
`down`, indented two spaces, then the count.

**Acceptance criteria**

- Output lists `db 01` (with its space) and `queue01`, then `count: 2`.
- Uses `select`; no `grep` on JSON.
- `-r` is used, so there are no quotes around names.

### Medium: busy servers as CSV

Given four servers with a `cpu` value, print a `name,cpu` header and then a CSV line for each server
above a threshold held in a shell variable, sorted by CPU descending.

**Acceptance criteria**

- Output: header, `"cache 01",0.91`, `"db01",0.77`.
- The threshold is passed with `--argjson`, not interpolated.
- Names with spaces survive.

### Hard: safe status updates

Write `set_status FILE NAME STATUS`: reject statuses other than `up`, `down`, `maintenance` (return 2),
reject unknown servers (return 1), write the change to a temp file, verify it is valid JSON with `jq -e .`,
and only then `mv` it over the original. Print a per-status summary before and after, and show that no
temp files remain.

**Acceptance criteria**

- After setting `db01` to up and `cache 01` to maintenance the summary reads `maintenance: 1`, `up: 2`.
- Unknown server exit 1, bad status exit 2, both with a message on stderr.
- `leftover temp files: 0`.

### Break it

This script has **three bugs**: names split on spaces, the filter is built from shell text, and the file
is read and written in one command. Save as `break-it.sh`, run it, and fix it. The end result must
list both names, show the `web01` object, and leave a non-empty `s.json` with `checked=true`.

```bash
#!/usr/bin/env bash
echo '{"servers":[{"name":"cache 01"},{"name":"web01"}]}' > s.json

for n in $(jq '.servers[].name' s.json); do
    echo "server: $n"
done

want="web01"
jq ".servers[] | select(.name == $want)" s.json 2>&1 | head -n 2

jq '.servers |= map(.checked = true)' s.json > s.json
echo "s.json is now $(wc -c < s.json) bytes"
```

**Expected output**

```text
server: "cache
server: 01"
server: "web01"
jq: error: web01/0 is not defined at <top-level>, line 1:
.servers[] | select(.name == web01)
s.json is now 0 bytes
```

<details>
<summary>Hint</summary>

Use `-r` with `mapfile`, `--arg` for `want`, and a temp file (then `mv`) for the update.

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 26 easy: list the servers that are down. Needs jq.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/servers.json" <<'EOF'
{"servers": [
  {"name": "web01", "status": "up"},
  {"name": "db 01", "status": "down"},
  {"name": "queue01", "status": "down"}
]}
EOF

echo "servers that are down:"
jq -r '.servers[] | select(.status == "down") | "  " + .name' "${work}/servers.json"
echo "count: $(jq '[.servers[] | select(.status == "down")] | length' "${work}/servers.json")"

rm -rf -- "$work"
```

**Expected output**

```text
servers that are down:
  db 01
  queue01
count: 2
```

</details>

<details>
<summary>Medium</summary>

`sort_by(-.cpu)` sorts descending by negating the key. `@csv` quotes strings and leaves numbers
bare, which is what CSV consumers expect.

```bash
#!/usr/bin/env bash
# Day 26 medium: a CSV report of busy servers, sorted by CPU, with a threshold passed safely. Needs jq.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/servers.json" <<'EOF'
{"servers": [
  {"name": "web01",    "cpu": 0.42},
  {"name": "cache 01", "cpu": 0.91},
  {"name": "db01",     "cpu": 0.77},
  {"name": "queue01",  "cpu": 0.10}
]}
EOF

threshold=0.5
echo "name,cpu"
jq -r --argjson t "$threshold" \
    '.servers | map(select(.cpu > $t)) | sort_by(-.cpu) | .[] | [.name, .cpu] | @csv' \
    "${work}/servers.json"

rm -rf -- "$work"
```

**Expected output**

```text
name,cpu
"cache 01",0.91
"db01",0.77
```

</details>

<details>
<summary>Hard</summary>

`mktemp "${file}.XXXXXX"` creates the temp file next to the target, so `mv` is an atomic rename on the
same file system. The validity check runs before the replace, so a `jq` error can never destroy the
original.

```bash
#!/usr/bin/env bash
# Day 26 hard: set_status NAME STATUS - update a JSON file atomically, validate it, summarise it.
# Needs jq. Temporary files only.
set -euo pipefail

set_status() {                                  # set_status FILE NAME STATUS
    local file="$1" name="$2" status="$3" tmp
    case "$status" in up|down|maintenance) ;; *) echo "bad status: ${status}" >&2; return 2 ;; esac
    jq -e --arg n "$name" '.servers[] | select(.name == $n)' "$file" >/dev/null \
        || { echo "no such server: ${name}" >&2; return 1; }
    tmp="$(mktemp "${file}.XXXXXX")"
    jq --arg n "$name" --arg s "$status" \
        '.servers |= map(if .name == $n then .status = $s else . end)' "$file" > "$tmp"
    jq -e . "$tmp" >/dev/null                   # the new file must still be valid JSON
    mv -- "$tmp" "$file"
}

summary() {
    jq -r '.servers | group_by(.status) | map("\(.[0].status): \(length)") | .[]' "$1"
}

work="$(mktemp -d)"
cat > "${work}/servers.json" <<'EOF'
{"servers": [
  {"name": "web01", "status": "up"},
  {"name": "db01", "status": "down"},
  {"name": "cache 01", "status": "up"}
]}
EOF

echo "before:"; summary "${work}/servers.json"
set_status "${work}/servers.json" "db01" up
set_status "${work}/servers.json" "cache 01" maintenance
echo "after:"; summary "${work}/servers.json"

status=0; set_status "${work}/servers.json" "ghost" up 2>&1 || status=$?
echo "unknown server -> exit ${status}"
status=0; set_status "${work}/servers.json" "web01" exploded 2>&1 || status=$?
echo "bad status -> exit ${status}"
echo "leftover temp files: $(find "$work" -name 'servers.json.*' | wc -l)"

rm -rf -- "$work"
```

**Expected output**

```text
before:
down: 1
up: 2
after:
maintenance: 1
up: 2
no such server: ghost
unknown server -> exit 1
bad status: exploded
bad status -> exit 2
leftover temp files: 0
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `$(jq ...)` kept the quotes and split `cache 01` into two words. Bug 2: `$want` was pasted into the
filter, giving `.name == web01`, which `jq` reads as an undefined function. Bug 3: `> s.json` truncated the
file before `jq` read it (0 bytes).

```bash
#!/usr/bin/env bash
# Fixed: -r plus mapfile for names with spaces, --arg for shell values, a temp file for in-place edits.
set -euo pipefail

echo '{"servers":[{"name":"cache 01"},{"name":"web01"}]}' > s.json

mapfile -t names < <(jq -r '.servers[].name' s.json)
for n in "${names[@]}"; do
    echo "server: $n"
done

want="web01"
jq --arg n "$want" '.servers[] | select(.name == $n)' s.json

jq '.servers |= map(.checked = true)' s.json > s.json.new && mv s.json.new s.json
echo "s.json now has checked=$(jq '[.servers[].checked] | all' s.json)"
```

**Expected output**

```text
server: cache 01
server: web01
{
  "name": "web01"
}
s.json now has checked=true
```

</details>

Solution files live in [`solutions/day-26/`](solutions/day-26/).

## Self-check

1. What does `jq -r` change?
2. How do you pass a shell variable into a `jq` filter safely?
3. Why can't you run `jq ... f > f`?
4. What does `.servers[] | select(.cpu > 0.5)` return?
5. How do you turn the results of `jq` into a Bash array?

<details>
<summary>Answers</summary>

1. Strings are printed raw, without the surrounding JSON quotes.
2. `--arg name "$value"` (string) or `--argjson` (JSON value), then use `$name`.
3. The shell truncates `f` before `jq` starts reading.
4. Each server object whose `cpu` is greater than 0.5.
5. `mapfile -t arr < <(jq -r '...' file)`.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `jq . f` | Pretty-print / validate |
| `jq -r '.a.b' f` | Raw string value |
| `jq -r '.xs[].name' f` | One value per line |
| `jq '.xs[] \| select(.k == "v")' f` | Filter |
| `jq --arg v "$x" '... $v'` | Safe variable |
| `jq -n '{a: 1}'` | Build JSON |
| `jq '.a \|= 2' f > tmp && mv tmp f` | Update safely |
| `jq -e FILTER f` | Exit status from the result |
| `@csv`, `@tsv`, `@sh` | Output formats |
| `jq -c`, `length`, `add`, `group_by(.k)` | Compact, count, sum, group |

## Further reading

- [jq manual](https://jqlang.github.io/jq/manual/): every filter and option, with runnable examples.
- [jq tutorial](https://jqlang.github.io/jq/tutorial/): a short hands-on introduction using a real API.
- [Greg's Wiki: BashFAQ/050](https://mywiki.wooledge.org/BashFAQ/050): why putting commands in
  variables is hard; relevant to building `jq` filters safely.
- [RFC 8259: the JSON specification](https://www.rfc-editor.org/rfc/rfc8259): the exact grammar, short
  and readable.

**Next:** [Day 27](day-27.md)
