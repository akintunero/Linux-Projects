# Day 25: Reusable, Testable Scripts

> **Time:** ~60 min · **Level:** Advanced
> **Prerequisites:** [Day 24](day-24.md)

## Goal

By the end of this lesson you can:

- Split code into a sourced library and a thin script that finds it from any directory.
- Use a main guard so a script can be both executed and sourced for tests.
- Write a minimal test harness and a checklist for scripts that others can trust.

## Concepts

### Script, library, test: three kinds of file

| File | Executed or sourced | Rules |
|------|---------------------|-------|
| Script (`app.sh`) | Executed | Has `main`, parses arguments, returns exit codes |
| Library (`lib.sh`) | **Sourced** | Only definitions; no side effects when loaded; no `exit` at load time |
| Test (`test-lib.sh`) | Executed | Sources the code, calls functions, checks results |

### Finding your own directory

`source lib/util.sh` is relative to the *current directory*, not the script. Use:

```bash
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/lib.sh"
```

`BASH_SOURCE[0]` is the file being executed. Prefer it to `$0`, which is wrong inside a sourced file.

### The main guard

```bash
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
```

When the file is run, `BASH_SOURCE[0]` equals `$0`, so `main` runs. When another file sources it, they
differ and nothing runs, so tests can load the functions safely.

### A library template

```bash
[[ -n ${_LIB_LOADED:-} ]] && return 0      # load once
_LIB_LOADED=1
log()  { ...; }                            # functions only; use local variables
```

- Name functions with a prefix if the library is large (`fs_copy`, `net_wait`) to avoid collisions.
- Libraries must not change shell options (`set -e`) or traps unexpectedly; leave that to the script.
- Use `return`, not `exit`, in code that may be sourced (except `die`, which is explicit).

### Checklist for a trustworthy script

1. `#!/usr/bin/env bash`, a header comment with usage, and `set -euo pipefail`.
2. Everything in functions; `main "$@"` at the bottom, behind the guard.
3. All variables `local`; every expansion quoted.
4. Errors to stderr with a non-zero exit code; success quiet or clearly reported.
5. Temp files via `mktemp`, cleanup via `trap ... EXIT`.
6. Dependencies checked early (`require_cmd`).
7. Idempotent: safe to run twice.
8. `shellcheck` clean, and a few tests.
9. A `--help`/usage message and documented environment variables.

### Testing in plain Bash

You do not need a framework to start. A function that compares expected and actual output, counts
failures and exits non-zero is a test harness:

```bash
assert_eq() { [[ $1 == "$2" ]] && echo "ok $3" || { echo "FAIL $3"; failed=1; }; }
```

For larger projects, [Bats](https://github.com/bats-core/bats-core) adds structure, and
[ShellCheck](https://www.shellcheck.net/) finds bugs before you run anything.

## Worked example

Three files: a library, a script that uses it, and a session that runs the script in several ways. Save
the first two as `lib.sh` and `app.sh` in the same directory.

`lib.sh`:

```bash
# lib.sh - reusable helpers. Source this file; do not execute it.
# shellcheck shell=bash

# Load only once, even if sourced from several places.
[[ -n ${_LIB_SH_LOADED:-} ]] && return 0
_LIB_SH_LOADED=1

readonly LIB_VERSION="1.0"
LOG_LEVEL="${LOG_LEVEL:-info}"              # debug | info | warn | error
declare -A _LOG_RANK=([debug]=0 [info]=1 [warn]=2 [error]=3)

# log LEVEL MESSAGE... : write to stderr when LEVEL is at or above LOG_LEVEL
log() {
    local level="$1"
    shift
    (( ${_LOG_RANK[$level]} >= ${_LOG_RANK[$LOG_LEVEL]} )) || return 0
    printf '[%s] %s\n' "${level^^}" "$*" >&2
}

# die MESSAGE... : log an error and exit 1
die() {
    log error "$*"
    exit 1
}

# require_cmd TOOL... : fail early with a clear message when a dependency is missing
require_cmd() {
    local tool
    for tool in "$@"; do
        command -v "$tool" >/dev/null 2>&1 || die "required command not found: $tool"
    done
}

# slugify TEXT : "  Hello, World!! " -> "hello-world"
slugify() {
    local s="${1,,}"
    s="${s//[^a-z0-9]/-}"
    while [[ $s == *--* ]]; do s="${s//--/-}"; done
    s="${s#-}"
    s="${s%-}"
    printf '%s\n' "$s"
}
```

`app.sh`:

```bash
#!/usr/bin/env bash
# app.sh - turn titles into URL-friendly slugs.
# Usage: app.sh TITLE...
# Env:   LOG_LEVEL=debug|info|warn|error
set -euo pipefail

# Find our own directory, so the library is found no matter where we are run from.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/lib.sh"

main() {
    (( $# > 0 )) || die "usage: ${0##*/} TITLE..."
    local title
    for title in "$@"; do
        log debug "converting: ${title}"
        printf '%s -> %s\n' "$title" "$(slugify "$title")"
    done
    log info "converted $# title(s)"
}

# Run main only when executed, not when sourced (so tests can source this file).
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
```

Now save this as `session.sh` next to them and run `bash session.sh`:

```bash
echo "--- run it from the same directory"
bash app.sh "Hello, World!" "  Mixed CASE__title  "

echo "--- run it from a different directory (the library is still found)"
here="$PWD"
( cd / && bash "${here}/app.sh" "Second Run" )

echo "--- debug logging switched on with an environment variable"
LOG_LEVEL=debug bash app.sh "One More" 2>&1

echo "--- no arguments: a clear error and a failing exit status"
bash app.sh; echo "exit status: $?"

echo "--- sourcing app.sh does NOT run main, so you can test its functions"
bash -c 'source ./app.sh; slugify "  Already -- a--slug  "'
```

**Expected output**

```text
--- run it from the same directory
Hello, World! -> hello-world
  Mixed CASE__title   -> mixed-case-title
[INFO] converted 2 title(s)
--- run it from a different directory (the library is still found)
Second Run -> second-run
[INFO] converted 1 title(s)
--- debug logging switched on with an environment variable
[DEBUG] converting: One More
One More -> one-more
[INFO] converted 1 title(s)
--- no arguments: a clear error and a failing exit status
[ERROR] usage: app.sh TITLE...
exit status: 1
--- sourcing app.sh does NOT run main, so you can test its functions
already-a-slug
```

Notice that the second run works from `/` (the library is found through `script_dir`), that
`LOG_LEVEL=debug` changes the logging without touching the code, and that sourcing `app.sh` loads
`slugify` without running `main`.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `source lib/util.sh` | Relative to the current directory | `source "${script_dir}/lib/util.sh"` |
| Library function sets globals (`name=...`) | Overwrites the caller's variables | `local name=...` |
| Library calls `main` or `exit` while loading | Sourcing it runs the program or kills your shell | Definitions only; main guard in scripts |
| `$0` used to locate files in a sourced file | `$0` is the top-level script | `BASH_SOURCE[0]` |
| Library sets `set -e` or `trap` | Changes the behaviour of the whole caller | Leave options to the script |
| Copy-pasting helpers between scripts | Bugs get fixed in one copy only | One library, many scripts |
| No tests for "obvious" helpers | The edge case (`!!!`, empty input) breaks in production | A few `assert_eq` lines |
| `source`-ing a file from an untrusted directory | Runs arbitrary code | Only source files you control |

## Exercises

### Easy: extract a library

In a temp directory create `lib/common.sh` with `log` and `die`, and `tool.sh` that sources it using
`script_dir`. Run `tool.sh` from its own directory, from another directory, and with an argument that
makes it fail (`die`).

**Acceptance criteria**

- All three runs find the library.
- The failing run prints `[ERROR] asked to fail` and exit status 1.
- Logging goes to stderr.

### Medium: a main guard

Write `temperature.sh` with `c_to_f` (integer, rounded) and a `main` that prints `100 C = 212 F`.
Add the main guard. Run it, then source it in a subshell and call `c_to_f` for `-40 0 37 100`.

**Acceptance criteria**

- Executing prints `100 C = 212 F`; sourcing prints nothing by itself.
- `c_to_f 37` gives `99` and `c_to_f -40` gives `-40`.
- Running with no argument exits 2.

### Hard: test harness

Write `assert_eq EXPECTED ACTUAL NAME` and `assert_status CODE NAME CMD...`, a `summary` that exits
non-zero if anything failed, and at least five tests for `slugify` (punctuation, trimming, repeated
separators, digits, empty result). Add a *negative control*: prove the harness detects a wrong
expectation.

**Acceptance criteria**

- Output ends with `7 run, 7 passed, 0 failed` for the sample tests.
- The planted failure prints `FAIL ...` with expected and actual values, and the harness reports that it was detected.
- The script exits 0 only if all real tests pass.

### Break it

This script has **two bugs**: the library is not found when the script is run from another
directory, and the library silently changes the caller's variable. Save as `break-it.sh`, run it, and fix
the generated files so both runs print `name is now Ada`.

```bash
#!/usr/bin/env bash
mkdir -p lib
cat > lib/util.sh <<'EOF'
greet() {
    name="$1"
    echo "Hello, $name"
}
EOF

cat > run.sh <<'EOF'
#!/usr/bin/env bash
source lib/util.sh
name="Ada"
greet "Bob"
echo "name is now $name"
EOF

echo "--- from the script's own directory"
bash run.sh

echo "--- from somewhere else"
job="$PWD/run.sh"
(cd / && bash "$job")
```

**Expected output**

```text
--- from the script's own directory
Hello, Bob
name is now Bob
--- from somewhere else
/tmp/bash-lab/run.sh: line 2: lib/util.sh: No such file or directory
/tmp/bash-lab/run.sh: line 4: greet: command not found
name is now Ada
```

<details>
<summary>Hint</summary>

The second run fails to find `lib/util.sh`; fix the `source` line with the `script_dir` idiom. The first
run succeeds but prints `Bob`: what is missing in `greet`?

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 25 easy: move shared helpers into a library and source it relative to the script itself.
# Works in a temporary directory.
set -euo pipefail

work="$(mktemp -d)"
mkdir -p "${work}/lib" "${work}/elsewhere"

cat > "${work}/lib/common.sh" <<'EOF'
log()  { printf '[%s] %s\n' "$1" "${*:2}" >&2; }
die()  { log ERROR "$*"; exit 1; }
EOF

cat > "${work}/tool.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/lib/common.sh"
log INFO "tool started"
[[ ${1:-} == fail ]] && die "asked to fail"
echo "tool finished"
EOF

echo "--- run from the script directory"
(cd "$work" && bash tool.sh 2>&1)
echo "--- run from a different directory"
(cd "${work}/elsewhere" && bash ../tool.sh 2>&1)
echo "--- a failing run"
status=0
bash "${work}/tool.sh" fail 2>&1 || status=$?
echo "exit status: ${status}"

rm -rf -- "$work"
```

**Expected output**

```text
--- run from the script directory
[INFO] tool started
tool finished
--- run from a different directory
[INFO] tool started
tool finished
--- a failing run
[INFO] tool started
[ERROR] asked to fail
exit status: 1
```

</details>

<details>
<summary>Medium</summary>

The generated `temperature.sh` is written with a quoted here-doc so nothing inside is expanded by
the outer script. `(c * 9 + (c >= 0 ? 2 : -2)) / 5` rounds half away from zero in integer math.

```bash
#!/usr/bin/env bash
# Day 25 medium: make a script testable with a main guard, then test it by sourcing it.
# Works in a temporary directory.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/temperature.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# c_to_f CELSIUS : integer Fahrenheit, rounded
c_to_f() {
    local c="$1"
    echo $(( (c * 9 + (c >= 0 ? 2 : -2)) / 5 + 32 ))
}

main() {
    (( $# == 1 )) || { echo "usage: temperature.sh CELSIUS" >&2; exit 2; }
    echo "$1 C = $(c_to_f "$1") F"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
EOF

echo "--- executed: main runs"
bash "${work}/temperature.sh" 100

echo "--- sourced: only the function is loaded"
(
    source "${work}/temperature.sh"
    echo "no output from sourcing"
    for c in -40 0 37 100; do
        echo "c_to_f ${c} = $(c_to_f "$c")"
    done
)

status=0
bash "${work}/temperature.sh" 2>/dev/null || status=$?
echo "no argument -> exit ${status}"

rm -rf -- "$work"
```

**Expected output**

```text
--- executed: main runs
100 C = 212 F
--- sourced: only the function is loaded
no output from sourcing
c_to_f -40 = -40
c_to_f 0 = 32
c_to_f 37 = 99
c_to_f 100 = 212
no argument -> exit 2
```

</details>

<details>
<summary>Hard</summary>

`assert_status` runs the command with `|| actual=$?`, so a failing command does not abort the test
run under `set -e`. The negative control checks the harness itself: a test suite that cannot fail is
worthless.

```bash
#!/usr/bin/env bash
# Day 25 hard: a tiny test harness (assert_eq / assert_status) and tests for slugify.
# Prints a summary and exits non-zero when any test fails.
set -euo pipefail

# ---- the code under test (normally: source ./lib.sh) ------------------------------------
slugify() {
    local s="${1,,}"
    s="${s//[^a-z0-9]/-}"
    while [[ $s == *--* ]]; do s="${s//--/-}"; done
    s="${s#-}"
    s="${s%-}"
    printf '%s\n' "$s"
}

# ---- the harness ------------------------------------------------------------------------
tests_run=0
tests_failed=0

assert_eq() {                                  # assert_eq EXPECTED ACTUAL NAME
    tests_run=$(( tests_run + 1 ))
    if [[ $1 == "$2" ]]; then
        printf 'ok    %s\n' "$3"
    else
        tests_failed=$(( tests_failed + 1 ))
        printf 'FAIL  %s\n      expected: [%s]\n      actual:   [%s]\n' "$3" "$1" "$2"
    fi
}

assert_status() {                              # assert_status EXPECTED_STATUS NAME CMD...
    local expected="$1" name="$2" actual=0
    shift 2
    "$@" >/dev/null 2>&1 || actual=$?
    assert_eq "$expected" "$actual" "$name"
}

summary() {
    echo "${tests_run} run, $(( tests_run - tests_failed )) passed, ${tests_failed} failed"
    (( tests_failed == 0 ))
}

# ---- the tests --------------------------------------------------------------------------
assert_eq "hello-world"  "$(slugify 'Hello, World!')"        "punctuation becomes dashes"
assert_eq "mixed-case"   "$(slugify '  Mixed CASE  ')"       "trims and lowercases"
assert_eq "a-b"          "$(slugify 'a___b')"                "collapses repeated separators"
assert_eq "2025-report"  "$(slugify '2025 Report')"          "digits are kept"
assert_eq ""             "$(slugify '!!!')"                  "only punctuation gives an empty slug"
assert_status 0 "true succeeds"  true
assert_status 1 "false fails"    false

echo "--- negative control: the harness must notice a wrong expectation"
before=$tests_failed
assert_eq "wrong" "$(slugify 'Hello')" "deliberately wrong expectation" || true
if (( tests_failed == before + 1 )); then
    tests_failed=$before                      # forgive the planted failure...
    tests_run=$(( tests_run - 1 ))            # ...and do not count it as a real test
    echo "harness detected the planted failure"
fi

summary
```

**Expected output**

```text
ok    punctuation becomes dashes
ok    trims and lowercases
ok    collapses repeated separators
ok    digits are kept
ok    only punctuation gives an empty slug
ok    true succeeds
ok    false fails
--- negative control: the harness must notice a wrong expectation
FAIL  deliberately wrong expectation
      expected: [wrong]
      actual:   [hello]
harness detected the planted failure
7 run, 7 passed, 0 failed
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `source lib/util.sh` depends on the working directory. Bug 2: `name="$1"` inside `greet` is a
global assignment, so it replaced `Ada` with `Bob`. The fix is `script_dir` and `local name`.

```bash
#!/usr/bin/env bash
# Fixed: source the library relative to the script's own location, and keep the
# function's variable local so it cannot overwrite the caller's.
mkdir -p lib
cat > lib/util.sh <<'EOF'
greet() {
    local name="$1"
    echo "Hello, $name"
}
EOF

cat > run.sh <<'EOF'
#!/usr/bin/env bash
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/lib/util.sh"
name="Ada"
greet "Bob"
echo "name is now $name"
EOF

echo "--- from the script's own directory"
bash run.sh

echo "--- from somewhere else"
job="$PWD/run.sh"
(cd / && bash "$job")
```

**Expected output**

```text
--- from the script's own directory
Hello, Bob
name is now Ada
--- from somewhere else
Hello, Bob
name is now Ada
```

</details>

Solution files live in [`solutions/day-25/`](solutions/day-25/).

## Self-check

1. Why is `BASH_SOURCE[0]` better than `$0` for locating files?
2. What does the main guard do?
3. What should a sourced library avoid doing?
4. How do you make a function's variable private?
5. Why add a negative control to a test suite?

<details>
<summary>Answers</summary>

1. It is correct inside sourced files too; `$0` always names the top-level script.
2. Runs `main` only when the file is executed, not when it is sourced.
3. Side effects at load time: running code, `exit`, changing shell options, or overwriting globals.
4. Declare it with `local`.
5. To prove the tests can actually fail; a harness that always passes is no protection.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` | Directory of this file |
| `source "${script_dir}/lib.sh"` | Load a library |
| `[[ ${BASH_SOURCE[0]} == "$0" ]] && main "$@"` | Main guard |
| `[[ -n ${_LOADED:-} ]] && return 0` | Load once |
| `local v` | Private variable |
| `require_cmd tool` | Dependency check |
| `trap '...' EXIT` | Cleanup |
| `assert_eq expected actual name` | Test |
| `shellcheck script.sh` | Static analysis |

## Further reading

- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html): file layout,
  naming, comments and when not to write Bash.
- [ShellCheck wiki](https://www.shellcheck.net/wiki/): the explanation of every warning ShellCheck can
  give you.
- [Bats-core documentation](https://bats-core.readthedocs.io/): a testing framework for Bash, once
  your tests outgrow plain `assert_eq`.
- [Greg's Wiki: BashGuide/Practices](https://mywiki.wooledge.org/BashGuide/Practices): habits for
  portable, maintainable scripts.

**Next:** [Day 26](day-26.md)
