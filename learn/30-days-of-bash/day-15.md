# Day 15: Error Handling, Exit Codes and `trap`

> **Time:** ~60 min · **Level:** Intermediate
> **Prerequisites:** [Day 14](day-14.md)

## Goal

By the end of this lesson you can:

- Decide which failures to handle yourself and which to let `set -e` stop.
- Use `trap` to clean up temp files and locks on exit, on errors and on signals.
- Give your scripts meaningful exit codes and error messages.

## Concepts

### Three layers of defence

1. **Strict mode** (`set -euo pipefail`): stop on surprises.
2. **Explicit checks** for failures you can foresee (`if ! cmd; then`, `[[ -f ... ]] || die`).
3. **Traps** for guaranteed cleanup and diagnostics.

### What `set -e` does not catch

`set -e` is ignored in several places, so never treat it as a safety net:

- commands in an `if`, `while`, `until` condition, or before `&&`/`||`
- any command in a pipeline except the last (unless `pipefail`)
- commands inside a function that is itself called in one of those contexts

Conversely it can surprise you: `matches=$(grep -c x file)` **exits the script** when there are no
matches, because `grep` returns 1. Write `|| true` when "no match" is fine.

### Handling a failure on purpose

```bash
if ! cp "$src" "$dst"; then            # test the command itself
    die 1 "cannot copy $src"
fi
status=0; some_cmd || status=$?        # capture the code without dying
```

### Exit codes you can choose

`0` success, `1` generic failure, `2` usage error, `64-78` the BSD `sysexits` range (`66` no input
file, `75` temporary failure), `126` found but not executable, `127` not found, `128+N` killed by
signal `N` (`130` Ctrl-C, `143` SIGTERM). Document the ones your script uses.

### `trap`

```bash
trap 'rm -rf -- "$work"' EXIT          # run on ANY exit (success, error, exit command)
trap 'echo "failed at line $LINENO"' ERR
trap 'echo "interrupted"; exit 130' INT TERM
```

- Use **single quotes** so the command is expanded when the trap *fires*, not when it is set.
- The `EXIT` trap is the right place for cleanup. It also runs after `exit` and after errors under `set -e`.
- `set -E` makes the `ERR` trap fire inside functions and subshells too.
- An `EXIT` trap runs after functions have returned, so it cannot see `local` variables.
  Use a global (or set the trap in the code that owns the variable).
- `SIGKILL` (`kill -9`) cannot be trapped. That is one reason to prefer `SIGTERM` for stopping things.

### Temp files and locks

```bash
work="$(mktemp -d)"                    # private, unique, mode 700
mkdir -- "$lockdir" || exit 75         # mkdir is atomic: a cheap, portable lock
```

## Worked example

`errors.sh` combines strict mode, handled failures, an ERR trap and an EXIT trap. Its last command
fails on purpose, so the script ends with status 2. Save it and run it.

```bash
#!/usr/bin/env bash
# errors.sh - exit codes, handled failures, traps and cleanup
set -Eeuo pipefail            # -E: ERR trap also fires inside functions

work="$(mktemp -d)"

cleanup() {
    rm -rf -- "$work"
    echo "cleanup: removed the temp dir"
}
on_error() {
    echo "ERROR: line $1 exited with status $2" >&2
}
trap cleanup EXIT                      # runs on every exit, success or failure
trap 'on_error "$LINENO" "$?"' ERR     # runs when a command fails (single quotes!)

echo "1. working in a private temp dir"
[[ -d $work ]] && echo "   it exists"

echo "2. expected failures: test them yourself"
if ! grep -q needle /dev/null; then
    echo "   needle not found (handled)"
fi
cp /no/such/file "$work/" 2>/dev/null || echo "   copy failed (handled)"

echo "3. capture a status without dying"
status=0
grep -q needle /dev/null || status=$?
echo "   grep returned $status"

echo "4. a command that may legitimately fail"
matches="$(grep -c needle /dev/null || true)"
echo "   matches: $matches"

echo "5. pipefail: the first stage fails, so the pipeline fails"
if ! false | cat; then
    echo "   pipeline reported failure"
fi

echo "6. an unhandled failure stops the script"
ls /no/such/dir
echo "never printed"
```

**Expected output**

```text
1. working in a private temp dir
   it exists
2. expected failures: test them yourself
   needle not found (handled)
   copy failed (handled)
3. capture a status without dying
   grep returned 1
4. a command that may legitimately fail
   matches: 0
5. pipefail: the first stage fails, so the pipeline fails
   pipeline reported failure
6. an unhandled failure stops the script
ls: cannot access '/no/such/dir': No such file or directory
ERROR: line 41 exited with status 2
cleanup: removed the temp dir
```

Follow the order at the end: the failing `ls` triggers the `ERR` trap (which reports the line), `set -e`
ends the script, and the `EXIT` trap still removes the temp directory.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `trap "rm -rf $work" EXIT` | Double quotes expand `$work` immediately, maybe while empty | `trap 'rm -rf -- "$work"' EXIT` |
| `count=$(grep -c x f)` under `set -e` | `grep` returns 1 on no match and kills the script | `count=$(grep -c x f \|\| true)` |
| `local work` and an EXIT trap using it | The local is gone when the trap runs: `unbound variable` | Make it a global |
| `cmd \|\| echo "failed"` then carrying on | The script continues in a bad state | `cmd \|\| die 1 "..."` |
| Relying on `set -e` inside `if f; then` | `-e` is disabled for the whole body of `f` | Check each critical step explicitly |
| Cleaning up only at the end of the script | An error or Ctrl-C skips it | `trap ... EXIT` |
| Using `kill -9` to stop a job | Cannot be trapped, so no cleanup | `kill -TERM` first |

## Exercises

### Easy: `die` with exit codes

Write `die CODE MESSAGE...` that prints `error: MESSAGE` to stderr and exits with `CODE`. Use it in
`require_file` (exit 66 when the file is missing). Run the check in a subshell for an existing and
a missing file and print each exit status.

**Acceptance criteria**

- Existing file: `exit status 0`. Missing file: the error message and `exit status 66`.
- The error message goes to stderr.

### Medium: cleanup that always runs

Write a function `job` that creates a temp directory, registers an `EXIT` trap to remove it, writes
a file, then returns status 3 (a simulated failure). Call it in a subshell and prove afterwards that
the exit status was 3 and the directory is gone.

**Acceptance criteria**

- Prints `job exit status: 3` and `temp dir was removed`.
- The trap uses single quotes.
- The variable that the trap needs is not `local`.

### Hard: lock and signals

Write a child job that takes a lock with `mkdir`, creates a work directory, and removes both in an
`EXIT` trap. Make it handle `TERM` and `INT` by printing a message and exiting `143` / `130`. Have
the job send itself `SIGTERM` (`kill -TERM $$`) and verify from the parent that the lock and work
directory are gone and the status is 143. Then pre-create the lock and show that a second instance
refuses to run with status 75.

**Acceptance criteria**

- Parent prints `lock released` and `temp work dirs left: 0`.
- Second instance prints `job: already running` and exit status 75.
- Everything happens inside a temp directory the script removes at the end.

### Break it

This script has **three bugs**: it exits silently, it leaves its temp directory behind, and it
passes an empty value to `rm`. Save as `break-it.sh`, run it, and fix it so it prints
`matches: 0`, status `0` and `leftover temp dirs: 0`.

```bash
#!/usr/bin/env bash
export TMPDIR="$PWD/tmp"
mkdir -p "$TMPDIR"

(
    set -e
    trap "rm -rf $work" EXIT
    work="$(mktemp -d)"
    echo "data" > "$work/file"
    matches="$(grep -c needle "$work/file")"
    echo "matches: $matches"
)
echo "subshell exit status: $?"
echo "leftover temp dirs: $(ls "$TMPDIR" | wc -l)"
```

**Expected output**

```text
subshell exit status: 1
leftover temp dirs: 1
```

<details>
<summary>Hint</summary>

Where is `work` assigned, relative to the line that mentions it in the `trap`? And what status does
`grep -c` return when the count is zero?

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 15 easy: a die() helper and meaningful exit codes.
# Runs the checks in subshells so this demo itself can report each exit status.
set -euo pipefail

die() {
    local code="$1"
    shift
    echo "error: $*" >&2
    exit "$code"
}

require_file() {
    [[ -f $1 ]] || die 66 "required file '$1' not found"
}

status=0
( require_file /etc/os-release ) || status=$?
echo "existing file: exit status ${status}"

status=0
( require_file /no/such/config.ini ) || status=$?
echo "missing file:  exit status ${status}"
```

**Expected output**

```text
existing file: exit status 0
error: required file '/no/such/config.ini' not found
missing file:  exit status 66
```

</details>

<details>
<summary>Medium</summary>

Running `job` inside `( ... )` gives it its own EXIT trap: the trap fires when the subshell ends,
which stands in for "when the script ends".

```bash
#!/usr/bin/env bash
# Day 15 medium: a temp directory that is always cleaned up, even when the job fails.
set -euo pipefail

marker="$(mktemp -u)"          # name of a marker file the job will use to tell us its temp dir

job() {
    # Not "local": an EXIT trap runs after the function has returned, when locals are gone.
    work="$(mktemp -d)"
    trap 'rm -rf -- "$work"' EXIT          # single quotes: expand when the trap runs
    echo "$work" > "$marker"
    echo "job: working in a temp dir"
    echo "payload" > "$work/data.txt"
    return 3                                # simulate a failure
}

status=0
( job ) || status=$?
work_dir="$(< "$marker")"

echo "job exit status: ${status}"
if [[ -e $work_dir ]]; then
    echo "temp dir LEFT BEHIND"
else
    echo "temp dir was removed"
fi
rm -f -- "$marker"
```

**Expected output**

```text
job: working in a temp dir
job exit status: 3
temp dir was removed
```

</details>

<details>
<summary>Hard</summary>

The child is written with a quoted here-doc (`<<'EOF'`) so nothing in it is expanded by the parent.
`exit 143` inside the `TERM` trap still runs the `EXIT` trap, which does the cleanup.

```bash
#!/usr/bin/env bash
# Day 15 hard: a job with a lock and a temp dir that survives signals.
# The script writes a child job, sends that job SIGTERM, and checks the cleanup.
# Temporary files only.
set -euo pipefail

root="$(mktemp -d)"
cat > "${root}/job.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
lock="$1/job.lock"
work="$(mktemp -d "$1/work.XXXXXX")"

cleanup() {
    rm -rf -- "$work"
    rmdir -- "$lock" 2>/dev/null || true
}
trap cleanup EXIT                       # always runs
trap 'echo "job: caught SIGTERM"; exit 143' TERM
trap 'echo "job: caught SIGINT"; exit 130' INT

if ! mkdir -- "$lock" 2>/dev/null; then # mkdir is atomic: only one process wins
    echo "job: already running" >&2
    exit 75
fi
echo "job: lock taken, working"
kill -TERM $$                           # simulate someone stopping the job
echo "job: not reached"
EOF

status=0
bash "${root}/job.sh" "$root" || status=$?
echo "job exit status: ${status} (143 = terminated by SIGTERM)"

if [[ -e ${root}/job.lock ]]; then
    echo "lock LEFT BEHIND"
else
    echo "lock released"
fi
leftover="$(find "$root" -maxdepth 1 -name 'work.*' | wc -l)"
echo "temp work dirs left: ${leftover}"

echo "--- second instance while the lock is held"
mkdir "${root}/job.lock"
status=0
bash "${root}/job.sh" "$root" || status=$?
echo "second instance exit status: ${status}"

rm -rf -- "$root"
```

**Expected output**

```text
job: lock taken, working
job: caught SIGTERM
job exit status: 143 (143 = terminated by SIGTERM)
lock released
temp work dirs left: 0
--- second instance while the lock is held
job: already running
second instance exit status: 75
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `trap "rm -rf $work" EXIT` expanded `$work` when empty, so the trap ran `rm -rf` on nothing
and left the directory behind. Bug 2: `grep -c` returns 1 for zero matches, so `set -e` killed the
subshell with no message. Bug 3: the unquoted `rm -rf $work` is fragile for the same reason as any
unquoted variable. The fix assigns first, single-quotes the trap, and adds `|| true`.

```bash
#!/usr/bin/env bash
# Fixed: define the variable before the trap, single-quote the trap so it expands at exit
# time, and tolerate grep's "no match" status on purpose.
export TMPDIR="$PWD/tmp"
mkdir -p "$TMPDIR"

(
    set -e
    work="$(mktemp -d)"
    trap 'rm -rf -- "$work"' EXIT
    echo "data" > "$work/file"
    matches="$(grep -c needle "$work/file" || true)"
    echo "matches: $matches"
)
echo "subshell exit status: $?"
echo "leftover temp dirs: $(ls "$TMPDIR" | wc -l)"
```

**Expected output**

```text
matches: 0
subshell exit status: 0
leftover temp dirs: 0
```

</details>

Solution files live in [`solutions/day-15/`](solutions/day-15/).

## Self-check

1. Name two situations where `set -e` does **not** stop the script.
2. Why single quotes around a `trap` command?
3. Which exit code means "killed by SIGTERM"?
4. What does `trap ... EXIT` guarantee that cleanup code at the end of the script does not?
5. Why is `mkdir` a good lock primitive?

<details>
<summary>Answers</summary>

1. Commands in an `if` condition, and in a `&&` / `||` list (also pipeline stages except the last
   without `pipefail`).
2. So the command text is expanded when the trap runs, not when it is defined.
3. 143 (128 + 15).
4. It also runs when the script fails, is interrupted, or calls `exit` early.
5. Creating a directory is atomic: exactly one process can succeed.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `set -Eeuo pipefail` | Strict mode (and ERR trap in functions) |
| `cmd \|\| true` | Allow failure |
| `cmd \|\| status=$?` | Capture status |
| `if ! cmd; then ...; fi` | Handle failure |
| `trap 'cleanup' EXIT` | Run on any exit |
| `trap 'echo $LINENO' ERR` | Report failing line |
| `trap '...; exit 143' TERM` | Handle signals |
| `mktemp -d` | Private temp dir |
| `mkdir lockdir` | Atomic lock |
| `exit N` | Exit with code N |

## Further reading

- [Greg's Wiki: BashFAQ/105](https://mywiki.wooledge.org/BashFAQ/105): why `set -e` is unreliable
  and what to do instead.
- [Greg's Wiki: SignalTrap](https://mywiki.wooledge.org/SignalTrap): practical guidance on `trap`.
- [sysexits.h exit codes](https://man.freebsd.org/cgi/man.cgi?query=sysexits&sektion=3): the
  conventional `64-78` exit codes and their meanings.

**Next:** [Day 16](day-16.md)
