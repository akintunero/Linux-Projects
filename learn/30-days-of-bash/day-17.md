# Day 17: Automating Bulk Work with `find`, `xargs` and Process Substitution

> **Time:** ~60 min · **Level:** Intermediate
> **Prerequisites:** [Day 16](day-16.md)

## Goal

By the end of this lesson you can:

- Select files with `find` (name, type, age) and act on them with `-exec`, `xargs` or a safe loop.
- Feed a loop with `< <(command)` so its variables survive.
- Preview every bulk change with a dry run before it touches anything.

## Concepts

### `find`: choose files by property

```bash
find DIR -type f -name '*.log' -mtime +7      # regular files named *.log, older than 7 days
find DIR -type d -empty                        # empty directories
find DIR -size +100M                           # bigger than 100 MiB
find DIR \( -name '*.jpg' -o -name '*.png' \)  # either pattern (note the escaped parentheses)
```

Quote the pattern (`'*.log'`) so the shell does not expand it first. Combine tests freely; they
mean "and" unless you write `-o`.

### Acting on matches

| Method | Use when |
|--------|----------|
| `-exec cmd {} \;` | One command per file |
| `-exec cmd {} +` | Many files per command call (fast) |
| `-delete` | Delete the matches (put it **last**) |
| `-print0 \| xargs -0 cmd` | The same as `+`, plus options like `-P` for parallelism |
| `-print0 \| while IFS= read -r -d ''` | You need shell logic per file |

> [!WARNING]
> **Dry-run first.** Replace `-delete` or `-exec rm` with `-print` and read the list. Run the real
> thing only when the list is what you expect. `-delete` before the tests (`find . -delete -name x`)
> deletes everything.

### `xargs`

`xargs` builds a command line from its input. `-0` reads NUL-separated names, `-n N` limits
arguments per run, `-P N` runs N jobs at once, and `-I{}` substitutes each item into a template.
Without `-0`, spaces and quotes in names break things.

### Process substitution

`<(command)` appears as a file name that contains the command's output; `> >(command)` is the output
version. Two uses matter most:

```bash
while IFS= read -r -d '' f; do count=$((count + 1)); done < <(find . -print0)   # no subshell
diff <(sort a.txt) <(sort b.txt)                                                # compare outputs
```

The first form avoids the pipe-subshell trap from Day 5: the loop runs in your shell, so `count`
is still set afterwards.

### Safe batch pattern

1. Build the list (`find ... -print0`, sorted with `sort -z` for stable order).
2. Print what you would do (`would rename: a -> b`).
3. Do it with `mv -n` (never overwrite) or a similar guard, and count the results.

## Worked example

Seven techniques on a small photo folder. Save as `auto.sh` and run it in an empty directory.

```bash
#!/usr/bin/env bash
# auto.sh - batch work with find, xargs and process substitution
set -euo pipefail

mkdir photos
touch "photos/IMG 001.JPG" "photos/IMG 002.JPG" photos/notes.txt
touch -d '10 days ago' photos/old.tmp
touch photos/fresh.tmp

echo "--- 1. find -exec runs a command per match ({} is the file)"
find photos -name '*.tmp' -exec ls -1 {} \; | sort

echo "--- 2. -exec ... {} + batches many files into one call"
find photos -name '*.JPG' -exec chmod 644 {} +

echo "--- 3. find has tests: files older than 7 days (dry run: -print first!)"
find photos -name '*.tmp' -mtime +7 -print

echo "--- 4. xargs turns lines/NULs into arguments; -0 pairs with -print0"
find photos -name '*.JPG' -print0 | sort -z | xargs -0 -n1 echo "file:"

echo "--- 5. a loop fed by process substitution: variables survive"
renamed=0
while IFS= read -r -d '' path; do
    dir="${path%/*}"
    base="${path##*/}"
    new="${base,,}"                       # lowercase
    new="${new// /-}"                     # spaces to dashes
    mv -n -- "$path" "${dir}/${new}"
    renamed=$(( renamed + 1 ))
done < <(find photos -name '*.JPG' -print0 | sort -z)
echo "renamed ${renamed} file(s)"
ls photos

echo "--- 6. compare two command outputs without temp files"
diff <(printf '%s\n' a b c) <(printf '%s\n' a c d) || true

echo "--- 7. xargs -P runs jobs in parallel; sort keeps the output stable"
printf '%s\n' 1 2 3 4 | xargs -P 4 -I{} sh -c 'echo "job {} done"' | sort
```

**Expected output**

```text
--- 1. find -exec runs a command per match ({} is the file)
photos/fresh.tmp
photos/old.tmp
--- 2. -exec ... {} + batches many files into one call
--- 3. find has tests: files older than 7 days (dry run: -print first!)
photos/old.tmp
--- 4. xargs turns lines/NULs into arguments; -0 pairs with -print0
file: photos/IMG 001.JPG
file: photos/IMG 002.JPG
--- 5. a loop fed by process substitution: variables survive
renamed 2 file(s)
fresh.tmp
img-001.jpg
img-002.jpg
notes.txt
old.tmp
--- 6. compare two command outputs without temp files
2d1
< b
3a3
> d
--- 7. xargs -P runs jobs in parallel; sort keeps the output stable
job 1 done
job 2 done
job 3 done
job 4 done
```

Section 5 is the pattern to remember: NUL-separated input, a `while read -d ''` loop fed by process
substitution, `mv -n`, and a counter that is still correct after the loop. In section 7 each job
runs in parallel, so we `sort` the output to make it predictable.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `find . -name *.txt` | The shell expands `*.txt` first if files match in the current directory | `-name '*.txt'` |
| `find ... \| xargs rm` | Names with spaces or newlines split into several arguments | `-print0 \| xargs -0 rm --` |
| `find . -delete -name '*.tmp'` | Tests are evaluated left to right: `-delete` ran first and removed everything | `find . -name '*.tmp' -delete` |
| `cmd \| while read ...; count++` | The loop is a subshell: the count is lost | `done < <(cmd)` |
| `for f in $(find ...)` | Word-splits on spaces | `find -print0` with a read loop |
| `mv "$f" "$new"` in a bulk rename | Silently overwrites on a name clash | `mv -n` (or check `[[ -e $new ]]`) |
| `-exec rm {} \;` on 100,000 files | One `rm` process per file: slow | `-exec rm -- {} +` |

## Exercises

### Easy: cleanup with a dry run

In a temp directory create two `*.tmp` files dated 10 days ago (`touch -d '10 days ago'`, one with a
space in its name), one fresh `*.tmp` and one `keep.txt`. Write `cleanup DIR APPLY` that always lists the
old `*.tmp` files and only deletes them when `APPLY=1`. Show the file count after the dry run and
after the real run.

**Acceptance criteria**

- Dry run lists the two old files, deletes nothing (4 files still present).
- Real run deletes exactly those two (2 files remain: `fresh.tmp` and `keep.txt`).
- Listing uses `find -mtime +7`; no `ls` parsing.

### Medium: batch-rename photos

Given `IMG 001.JPG`, `IMG 002.JPG`, `img 10.jpeg` and `notes.txt`, rename the three photos to
`holiday-001.jpg`, `holiday-002.jpg`, `holiday-003.jpg` in sorted order. Provide a `dry_run` switch
that only prints `would rename: old -> new`. Use `mv -n` and report how many files were processed.

**Acceptance criteria**

- Dry run changes nothing; real run renames all three and leaves `notes.txt`.
- Matching is case-insensitive (`-iname`) and covers both `.jpg` and `.jpeg`.
- Names with spaces work; the counter is correct after the loop.

### Hard: parallel checksums and tamper detection

In a temp tree with seven files (one named `deep file.txt` in a subdirectory), hash everything with
`sha256sum` using `find -print0 | xargs -0 -n 2 -P 3`, sorted by file name, into a snapshot file.
Verify it with `sha256sum -c --quiet`, then modify one file and show the failure and the exit status.
Finally, compare the old snapshot with a fresh one using `diff <(...) <(...)`.

**Acceptance criteria**

- First verification prints `all files match`.
- After tampering, `sha256sum -c` names the changed file as `FAILED` and returns 1.
- The `diff` shows exactly one changed line and uses process substitution, not temp files.

### Break it

This script has **two bugs**: it fails to delete a file with a space in its name, and it reports 0
text files although one exists. Save as `break-it.sh`, run it in an empty directory, and fix it.

```bash
#!/usr/bin/env bash
touch "a b.tmp" c.tmp d.txt

find . -name '*.tmp' | xargs rm
ls

count=0
find . -name '*.txt' | while read f; do
    count=$((count + 1))
done
echo "text files: $count"
```

**Expected output**

```text
rm: cannot remove './a': No such file or directory
rm: cannot remove 'b.tmp': No such file or directory
a b.tmp
break-it.sh
d.txt
text files: 0
```

<details>
<summary>Hint</summary>

`xargs` is splitting `a b.tmp` into two arguments. And the `while` loop is on the right-hand side
of a pipe, so it runs in a subshell.

</details>

## Solutions

<details>
<summary>Easy</summary>

`-printf '  %f\n'` prints just the file name, indented, so the output is easy to read and does not depend
on the temp path. `-delete` repeats exactly the same tests as the preview.

```bash
#!/usr/bin/env bash
# Day 17 easy: clean up *.tmp files older than 7 days - dry run first, delete only on request.
# Temporary files only.
set -euo pipefail

cleanup() {
    local dir="$1" apply="$2"
    echo "candidates (older than 7 days):"
    find "$dir" -type f -name '*.tmp' -mtime +7 -printf '  %f\n' | sort
    if (( apply )); then
        find "$dir" -type f -name '*.tmp' -mtime +7 -delete
        echo "deleted."
    else
        echo "dry run: nothing deleted (call with apply=1 to delete)"
    fi
}

work="$(mktemp -d)"
touch -d '10 days ago' "${work}/old one.tmp" "${work}/old two.tmp"
touch "${work}/fresh.tmp" "${work}/keep.txt"

cleanup "$work" 0
echo "--- files still present: $(find "$work" -type f | wc -l)"
cleanup "$work" 1
echo "--- files still present: $(find "$work" -type f | wc -l)"

rm -rf -- "$work"
```

**Expected output**

```text
candidates (older than 7 days):
  old one.tmp
  old two.tmp
dry run: nothing deleted (call with apply=1 to delete)
--- files still present: 4
candidates (older than 7 days):
  old one.tmp
  old two.tmp
deleted.
--- files still present: 2
```

</details>

<details>
<summary>Medium</summary>

`\( ... -o ... \)` groups the two name tests. `sort -z` makes the numbering deterministic. The
function takes `dry_run` as an argument, so the very same code path prints or acts.

```bash
#!/usr/bin/env bash
# Day 17 medium: batch-rename photos to holiday-001.jpg, holiday-002.jpg ... with a dry-run switch.
# Temporary files only.
set -euo pipefail

rename_photos() {
    local dir="$1" dry_run="$2" n=0 path new
    while IFS= read -r -d '' path; do
        n=$(( n + 1 ))
        new="$(printf '%s/holiday-%03d.jpg' "$dir" "$n")"
        if (( dry_run )); then
            echo "would rename: ${path##*/} -> ${new##*/}"
        else
            mv -n -- "$path" "$new"
            echo "renamed:      ${path##*/} -> ${new##*/}"
        fi
    done < <(find "$dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) -print0 | sort -z)
    echo "${n} file(s) processed"
}

work="$(mktemp -d)"
touch "${work}/IMG 001.JPG" "${work}/IMG 002.JPG" "${work}/img 10.jpeg" "${work}/notes.txt"

rename_photos "$work" 1
echo "--- real run"
rename_photos "$work" 0
echo "--- result"
ls "$work"

rm -rf -- "$work"
```

**Expected output**

```text
would rename: IMG 001.JPG -> holiday-001.jpg
would rename: IMG 002.JPG -> holiday-002.jpg
would rename: img 10.jpeg -> holiday-003.jpg
3 file(s) processed
--- real run
renamed:      IMG 001.JPG -> holiday-001.jpg
renamed:      IMG 002.JPG -> holiday-002.jpg
renamed:      img 10.jpeg -> holiday-003.jpg
3 file(s) processed
--- result
holiday-001.jpg
holiday-002.jpg
holiday-003.jpg
notes.txt
```

</details>

<details>
<summary>Hard</summary>

`cut -c1-12,65-` keeps the first 12 characters of the hash and the file name, so the diff stays
readable. `sha256sum -c` exits 1 when any file fails.

```bash
#!/usr/bin/env bash
# Day 17 hard: checksum a tree in parallel, then detect a changed file.
# Temporary files only.
set -euo pipefail

work="$(mktemp -d)"
mkdir -p "${work}/data/sub"
for i in 1 2 3 4 5 6; do
    echo "content ${i}" > "${work}/data/file${i}.txt"
done
echo "nested" > "${work}/data/sub/deep file.txt"
cd "${work}/data"

snapshot() {
    # -print0/-0 keeps "deep file.txt" in one piece; -P 3 -n 2 hashes 3 batches at a time.
    find . -type f -print0 | xargs -0 -n 2 -P 3 sha256sum | sort -k2
}

snapshot > ../before.sha
echo "hashed $(wc -l < ../before.sha) files in parallel"

echo "--- verify: everything should be OK"
sha256sum -c --quiet ../before.sha && echo "all files match"

echo "--- change one file"
echo "tampered" > file3.txt
status=0
sha256sum -c --quiet ../before.sha 2>&1 || status=$?
echo "verify exit status: ${status}"

echo "--- compare two snapshots without temporary files"
diff <(cut -c1-12,65- ../before.sha) <(snapshot | cut -c1-12,65-) || true

cd / && rm -rf -- "$work"
```

**Expected output**

```text
hashed 7 files in parallel
--- verify: everything should be OK
all files match
--- change one file
./file3.txt: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
verify exit status: 1
--- compare two snapshots without temporary files
3c3
< 6457faf377c6  ./file3.txt
---
> 92e78d0b0329  ./file3.txt
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `find | xargs rm` splits `a b.tmp` into `a` and `b.tmp`; use `-print0` with `xargs -0`.
Bug 2: the `while` loop ran inside a pipeline subshell, so `count` stayed 0 in the parent; feed it with
`< <(find ... -print0)`. Also `read` needed `-r`.

```bash
#!/usr/bin/env bash
# Fixed: NUL-separated names for xargs, and a process substitution so the loop runs
# in the current shell and the counter survives.
set -euo pipefail

touch "a b.tmp" c.tmp d.txt

find . -name '*.tmp' -print0 | xargs -0 rm --
ls

count=0
while IFS= read -r -d '' f; do
    count=$(( count + 1 ))
done < <(find . -name '*.txt' -print0)
echo "text files: $count"
```

**Expected output**

```text
break-it.fixed.sh
d.txt
text files: 1
```

</details>

Solution files live in [`solutions/day-17/`](solutions/day-17/).

## Self-check

1. Why must `-name` patterns be quoted?
2. What is the difference between `-exec ... \;` and `-exec ... +`?
3. What does `xargs -0` pair with?
4. Why does `done < <(cmd)` keep variables but `cmd | while ...` does not?
5. What is a dry run, and how do you do one with `find`?

<details>
<summary>Answers</summary>

1. So the shell does not expand the pattern before `find` sees it.
2. `\;` runs the command once per file; `+` batches many files into one invocation.
3. `find -print0` (or any NUL-separated input).
4. The first runs the loop in the current shell; the second runs it in a subshell.
5. Showing what would happen without doing it; replace `-delete`/`-exec rm` with `-print`.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `find DIR -type f -name 'x*' -mtime +7` | Select files |
| `find ... -print0 \| xargs -0 cmd` | Safe batch |
| `find ... -exec cmd {} +` | Batch without xargs |
| `find ... -delete` | Delete matches (last!) |
| `xargs -P4 -n2` | 4 parallel jobs, 2 args each |
| `while IFS= read -r -d '' f; do ...; done < <(...)` | Safe loop, no subshell |
| `diff <(cmd1) <(cmd2)` | Compare outputs |
| `mv -n` | Never overwrite |
| `sort -z` | Sort NUL-separated data |

## Further reading

- [Greg's Wiki: UsingFind](https://mywiki.wooledge.org/UsingFind): how to use `find` correctly with
  `-exec` and loops.
- [Greg's Wiki: ProcessSubstitution](https://mywiki.wooledge.org/ProcessSubstitution): what `<(...)`
  really is and when to use it.
- [Greg's Wiki: BashFAQ/030](https://mywiki.wooledge.org/BashFAQ/030): how to rename many files safely.

**Next:** [Day 18](day-18.md)
