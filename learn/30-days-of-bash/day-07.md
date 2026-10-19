# Day 07: Writing a Real Script

> **Time:** ~60 min · **Level:** Beginner
> **Prerequisites:** [Day 06](day-06.md)

## Goal

By the end of this lesson you can:

- Lay out a script with the standard skeleton: header, strict mode, helper functions, `main`.
- Validate arguments, print a usage message and exit with meaningful codes.
- Build a small but real tool: a directory backup script.

## Concepts

### The skeleton

Every script in this course from now on follows this shape:

```bash
#!/usr/bin/env bash
# name.sh - one line saying what it does.
# Usage: name.sh ARG...
# Exit:  0 ok, 1 runtime error, 2 bad usage
set -euo pipefail

usage() { echo "Usage: ${0##*/} ARG" >&2; exit 2; }
die()   { echo "error: $*" >&2; exit 1; }

main() {
    (( $# == 1 )) || usage
    local arg="$1"
    # ... real work ...
}

main "$@"
```

Why this layout:

- **Header comment** tells the next reader (often you in six months) what the script is for.
- **`set -euo pipefail`** stops on mistakes instead of ploughing on.
- **Functions first, call last.** `main "$@"` runs only after everything is defined.
- **`local` inside `main`** means your variables cannot leak or collide.
- **`usage` and `die`** give every failure a clear message on stderr and a clear exit code.

### Useful pieces

| Piece | Meaning |
|-------|---------|
| `"${0##*/}"` | The script's own name without its directory |
| `$#` | Number of arguments |
| `"$@"` | All arguments, individually quoted |
| `basename -- "$p"`, `dirname -- "$p"` | File name / directory of a path |
| `mktemp -d` | Create a private temporary directory |
| `${VAR:-default}` | Allow an environment override with a default |

### Exit codes you choose

Use `0` for success, `1` for an error at run time, `2` for wrong usage. Document them in the header.
Callers (cron, CI, other scripts) rely on them.

### Make it executable

```bash
chmod +x backup.sh
./backup.sh site out
```

## Worked example

`backup.sh` archives a directory into `DEST/NAME-TIMESTAMP.tar.gz`. Setting `BACKUP_STAMP` fixes
the timestamp, which makes the demo repeatable. Save this as `backup.sh`:

```bash
#!/usr/bin/env bash
# backup.sh - create a timestamped .tar.gz of a directory.
# Usage: backup.sh SOURCE_DIR DEST_DIR
# Exit:  0 ok, 1 runtime error, 2 bad usage
set -euo pipefail

usage() {
    echo "Usage: ${0##*/} SOURCE_DIR DEST_DIR" >&2
    exit 2
}

die() {
    echo "error: $*" >&2
    exit 1
}

main() {
    (( $# == 2 )) || usage
    local src="$1" dest="$2"

    [[ -d $src ]] || die "source '$src' is not a directory"
    mkdir -p -- "$dest"

    local name stamp archive
    name="$(basename -- "$src")"
    stamp="${BACKUP_STAMP:-$(date +%Y%m%d-%H%M%S)}"
    archive="${dest}/${name}-${stamp}.tar.gz"

    tar -czf "$archive" -C "$(dirname -- "$src")" -- "$name"
    echo "created ${archive}"
}

main "$@"
```

Now try it: first the wrong ways, then the right way, then look inside the archive. Save this as
`session.sh` next to `backup.sh` and run `bash session.sh`.

```bash
mkdir -p site/css
echo "<h1>Hi</h1>" > site/index.html
echo "body { margin: 0 }" > site/css/main.css

bash backup.sh
echo "exit status: $?"

bash backup.sh no-such-dir out
echo "exit status: $?"

BACKUP_STAMP=20250101-120000 bash backup.sh site out
echo "exit status: $?"

tar -tzf out/site-20250101-120000.tar.gz | sort
```

**Expected output**

```text
Usage: backup.sh SOURCE_DIR DEST_DIR
exit status: 2
error: source 'no-such-dir' is not a directory
exit status: 1
created out/site-20250101-120000.tar.gz
exit status: 0
site/
site/css/
site/css/main.css
site/index.html
```

Notice the exit codes: `2` for misuse, `1` for a runtime error, `0` for success. `tar -C DIR NAME`
stores `site/...` paths relative to the parent, not your absolute path.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `main` called without `"$@"` | The function gets no arguments: `$1: unbound variable` | `main "$@"` |
| Using a helper before defining it | Bash only knows what it has already read | Define functions at the top |
| `die` prints to stdout | Callers capturing output see the error as data | `echo ... >&2` |
| Always exiting 0 | Cron and CI cannot see failures | `exit 1` on error; let `set -e` propagate |
| `tar czf archive.tar.gz /abs/path` | Stores absolute paths (and warns) | `tar -C parent name` |
| Timestamps with `:` or spaces in file names | Awkward on some file systems and shells | `date +%Y%m%d-%H%M%S` |
| Hard-coding paths like `/home/ada` | Breaks for everyone else | Take arguments or `$HOME` |

## Exercises

### Easy: system summary

Using the skeleton, write `sysinfo.sh` that prints four lines: `Kernel:`, `Arch:`, `CPUs:` and
`Shell:` using `uname -s`, `uname -m`, `nproc` and `${SHELL##*/}` (your login shell's name). All logic lives in `main`.

**Acceptance criteria**

- Output has exactly the four labelled lines.
- The script contains `set -euo pipefail`, a `main` function and the call `main "$@"`.

### Medium: safe backup

Extend the backup logic into a function `backup_dir SRC DEST STAMP` that **refuses to overwrite** an
existing archive (return 3) and **verifies** a new archive with `tar -tzf` (return 4 on failure).
Call it twice with the same stamp in a temporary directory and report the exit status of the second
run.

**Acceptance criteria**

- First call prints `created and verified site-20250101-120000.tar.gz`.
- Second call prints an error on stderr and the script then prints `second run exit status: 3`.
- All temporary data is removed at the end.

### Hard: retention

Create five fake archives `site-20250101.tar.gz` to `site-20250105.tar.gz` in a temp directory and
write `prune DEST NAME KEEP` that deletes all but the newest `KEEP`. Because the timestamps sort
alphabetically, a glob already gives you oldest-to-newest order. Print each file it prunes and then
the files that remain.

**Acceptance criteria**

- With `KEEP=3` the two oldest are deleted; `20250103` to `20250105` remain.
- With `KEEP=10` nothing is deleted (no error from a negative loop count).
- A destination with no archives at all does not crash (`shopt -s nullglob`).

### Break it

This script has **three bugs**. Save it as `break-it.sh`, run it, fix the first error, run it again
(try `bash break-it.sh /tmp` and `bash break-it.sh /nope`), and keep going until it behaves.

```bash
#!/usr/bin/env bash
set -euo pipefail

main() {
    local dest="$1"
    [ -d $dest ] || die "no such directory: $dest"
    echo "cleaning $dest"
}

main
```

**Expected output**

```text
break-it.sh: line 5: $1: unbound variable
```

<details>
<summary>Hint</summary>

`$1` is unbound because `main` was called with nothing. After that is fixed, see what happens for a
directory that does not exist: is `die` defined anywhere?

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 07 easy: a system summary using the standard script skeleton.
set -euo pipefail

main() {
    echo "Kernel: $(uname -s)"
    echo "Arch:   $(uname -m)"
    echo "CPUs:   $(nproc)"
    echo "Shell:  ${SHELL##*/}"
}

main "$@"
```

**Expected output**

```text
Kernel: Linux
Arch:   x86_64
CPUs:   2
Shell:  bash
```

</details>

<details>
<summary>Medium</summary>

Distinct return codes let a caller react differently to "already exists" (3) and "corrupt" (4).
`second=$?` style capture uses `|| status=$?` so `set -e` does not stop the script.

```bash
#!/usr/bin/env bash
# Day 07 medium: backup that refuses to overwrite and verifies the archive.
# Works on temporary data only.
set -euo pipefail

err() { echo "error: $*" >&2; }

backup_dir() {
    local src="$1" dest="$2" stamp="$3" archive
    archive="${dest}/$(basename -- "$src")-${stamp}.tar.gz"
    mkdir -p -- "$dest"
    if [[ -e $archive ]]; then
        err "$(basename -- "$archive") already exists"
        return 3
    fi
    tar -czf "$archive" -C "$(dirname -- "$src")" -- "$(basename -- "$src")"
    if ! tar -tzf "$archive" >/dev/null; then
        err "archive failed verification"
        return 4
    fi
    echo "created and verified $(basename -- "$archive")"
}

main() {
    local work status=0
    work="$(mktemp -d)"
    mkdir -p "$work/site"
    echo "hello" > "$work/site/index.html"

    backup_dir "$work/site" "$work/out" "20250101-120000"
    backup_dir "$work/site" "$work/out" "20250101-120000" || status=$?
    echo "second run exit status: ${status}"

    rm -rf -- "$work"
}

main "$@"
```

**Expected output**

```text
created and verified site-20250101-120000.tar.gz
error: site-20250101-120000.tar.gz already exists
second run exit status: 3
```

</details>

<details>
<summary>Hard</summary>

`(( i < total - keep ))` is false at once when `keep >= total`, so the loop body never runs and
nothing is deleted.

```bash
#!/usr/bin/env bash
# Day 07 hard: backup with retention. Keep only the newest N archives.
# Works on temporary data only.
set -euo pipefail
shopt -s nullglob

prune() {
    local dest="$1" name="$2" keep="$3"
    local archives=("${dest}/${name}"-*.tar.gz)   # glob results are sorted; timestamps sort too
    local total="${#archives[@]}" i
    for (( i = 0; i < total - keep; i++ )); do
        echo "pruning $(basename -- "${archives[i]}")"
        rm -- "${archives[i]}"
    done
}

main() {
    local work stamp
    work="$(mktemp -d)"
    mkdir -p "$work/site" "$work/out"
    echo "data" > "$work/site/file.txt"

    for stamp in 20250101 20250102 20250103 20250104 20250105; do
        tar -czf "$work/out/site-${stamp}.tar.gz" -C "$work" site
    done

    prune "$work/out" site 3

    echo "remaining:"
    for f in "$work"/out/*.tar.gz; do
        basename -- "$f"
    done

    rm -rf -- "$work"
}

main "$@"
```

**Expected output**

```text
pruning site-20250101.tar.gz
pruning site-20250102.tar.gz
remaining:
site-20250103.tar.gz
site-20250104.tar.gz
site-20250105.tar.gz
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `main` was called without `"$@"`. Bug 2: `die` was never defined, so a bad directory produced
"command not found" instead of a message. Bug 3: `[ -d $dest ]` is unquoted `[ ]`; use
`[[ -d $dest ]]`. The fix also checks the argument count. This version defaults to `/tmp` when called
with no arguments so the test run is self-contained.

```bash
#!/usr/bin/env bash
# Fixed: pass arguments to main, check them, define die, and use [[ ]] with quotes.
# Run it as:  bash break-it.fixed.sh /tmp
set -euo pipefail

die() {
    echo "error: $*" >&2
    exit 1
}

main() {
    (( $# == 1 )) || die "usage: ${0##*/} DIRECTORY"
    local dest="$1"
    [[ -d $dest ]] || die "no such directory: $dest"
    echo "cleaning $dest"
}

main "${@:-/tmp}"
```

**Expected output**

```text
cleaning /tmp
```

</details>

Solution files live in [`solutions/day-07/`](solutions/day-07/).

## Self-check

1. Why do we call `main "$@"` at the very bottom?
2. Which exit code do we use for wrong usage?
3. What does `${0##*/}` produce?
4. Why send error messages to stderr?
5. Why does `tar -C parent name` beat `tar /full/path`?

<details>
<summary>Answers</summary>

1. All functions must be defined before they are used, and `"$@"` forwards the arguments.
2. `2` (by convention in this course).
3. The script name without any directory part.
4. So callers can capture real output separately and still see the errors.
5. The archive holds relative paths, so it extracts anywhere without absolute-path surprises.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `#!/usr/bin/env bash` + `set -euo pipefail` | Header and strict mode |
| `main "$@"` | Run the program with its arguments |
| `usage`, `die` | Standard exit helpers |
| `(( $# == 2 )) \|\| usage` | Argument count check |
| `${0##*/}` | Script name |
| `mktemp -d` | Temporary directory |
| `tar -czf out.tgz -C parent name` | Create archive |
| `tar -tzf out.tgz` | List/verify archive |
| `exit 0/1/2` | Success / error / bad usage |

## Further reading

- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html): a widely used set
  of conventions for script layout, naming and error handling.
- [Greg's Wiki: BashGuide/Practices](https://mywiki.wooledge.org/BashGuide/Practices): habits that
  keep scripts safe and readable.

**Next:** [Day 08](day-08.md)
