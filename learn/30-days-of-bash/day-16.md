# Day 16: Command-Line Arguments and `getopts`

> **Time:** ~60 min · **Level:** Intermediate
> **Prerequisites:** [Day 15](day-15.md)

## Goal

By the end of this lesson you can:

- Use `$1`, `$#`, `"$@"` and `shift` correctly, including arguments that contain spaces.
- Parse short options with `getopts` (flags, options with values, error cases).
- Parse long options (`--lines=5`) with a `while`/`case`/`shift` loop and honour `--`.

## Concepts

### Positional parameters

| Name | Meaning |
|------|---------|
| `$0` | The script's name |
| `$1`, `$2`, ... `${10}` | Arguments (use braces from the tenth) |
| `$#` | How many arguments |
| `"$@"` | All arguments, each as its own word. **Use this one.** |
| `"$*"` | All arguments glued into one word |
| `shift [n]` | Discard the first `n` arguments and renumber the rest |

`set -- a b c` replaces the arguments, which is handy for tests and defaults.

### `getopts`: short options

```bash
while getopts ":n:vh" opt; do
    case "$opt" in
        n) lines="$OPTARG" ;;     # -n takes a value (the colon after n)
        v) verbose=1 ;;
        h) usage; exit 0 ;;
        :) echo "-$OPTARG needs a value" >&2; exit 2 ;;
        \?) echo "unknown option -$OPTARG" >&2; exit 2 ;;
    esac
done
shift $(( OPTIND - 1 ))           # what is left in "$@" are the real arguments
```

- The option string lists letters; a `:` after a letter means "takes a value", found in `$OPTARG`.
- A **leading** `:` selects silent mode: you handle errors yourself (`:` = missing value,
  `?` = unknown option).
- `OPTIND` is the index of the next argument; `shift $((OPTIND-1))` removes the parsed options.
- It understands bundled flags (`-vn 5`) and stops at the first non-option or at `--`.
- Inside a function, declare `local OPTIND=1` so the function can be called more than once.

### Long options: do it by hand

`getopts` knows nothing about `--lines`. A small loop handles them:

```bash
while (( $# > 0 )); do
    case "$1" in
        --lines=*) lines="${1#*=}"; shift ;;
        --lines)   lines="$2"; shift 2 ;;
        --)        shift; break ;;           # end of options
        -*)        echo "unknown option $1" >&2; exit 2 ;;
        *)         files+=("$1"); shift ;;
    esac
done
```

### Good behaviour for a command-line tool

1. `-h`/`--help` prints usage and exits 0.
2. Bad input prints a one-line error plus usage to **stderr** and exits 2.
3. Validate values (is `-n` a number? does the file exist?) before doing any work.
4. `--` means "everything after this is a file name", even if it starts with `-`.

## Worked example

`lines.sh` shows the first lines of each file. Save it, then save the second block as `session.sh`
next to it and run `bash session.sh`.

```bash
#!/usr/bin/env bash
# lines.sh - show the first N lines of each file. Demonstrates getopts.
# Usage: lines.sh [-n LINES] [-v] [-h] FILE...
# Exit:  0 ok, 1 runtime error, 2 bad usage
set -euo pipefail

usage() {
    cat >&2 <<EOF
Usage: ${0##*/} [-n LINES] [-v] [-h] FILE...
  -n LINES   how many lines to show (default 3)
  -v         print a header before each file
  -h         show this help
EOF
}

main() {
    local lines=3 verbose=0 opt

    # The leading ":" gives us silent mode, so we print our own messages.
    # "n:" means -n takes a value, which getopts puts in $OPTARG.
    while getopts ":n:vh" opt; do
        case "$opt" in
            n) lines="$OPTARG" ;;
            v) verbose=1 ;;
            h) usage; return 0 ;;
            :) echo "error: -$OPTARG needs a value" >&2; usage; return 2 ;;
            \?) echo "error: unknown option -$OPTARG" >&2; usage; return 2 ;;
        esac
    done
    shift $(( OPTIND - 1 ))              # drop the parsed options; $@ is now the files

    case "$lines" in
        ''|*[!0-9]*) echo "error: -n needs a number, got '$lines'" >&2; return 2 ;;
    esac
    if (( $# == 0 )); then
        echo "error: no files given" >&2
        usage
        return 2
    fi

    local f
    for f in "$@"; do
        if [[ ! -r $f ]]; then
            echo "error: cannot read '$f'" >&2
            return 1
        fi
        if (( verbose )); then
            echo "==> $f <=="
        fi
        head -n "$lines" -- "$f"
    done
}

main "$@"
```

```bash
printf 'one\ntwo\nthree\nfour\n' > a.txt
printf 'alpha\nbeta\n' > "b file.txt"

echo "--- defaults"
bash lines.sh a.txt

echo "--- option with a value, a flag, and a file name with a space"
bash lines.sh -n 2 -v a.txt "b file.txt"

echo "--- problems"
bash lines.sh -x a.txt; echo "exit status: $?"
bash lines.sh -n; echo "exit status: $?"
bash lines.sh -n many a.txt; echo "exit status: $?"
bash lines.sh; echo "exit status: $?"
```

**Expected output**

```text
--- defaults
one
two
three
--- option with a value, a flag, and a file name with a space
==> a.txt <==
one
two
==> b file.txt <==
alpha
beta
--- problems
error: unknown option -x
Usage: lines.sh [-n LINES] [-v] [-h] FILE...
  -n LINES   how many lines to show (default 3)
  -v         print a header before each file
  -h         show this help
exit status: 2
error: -n needs a value
Usage: lines.sh [-n LINES] [-v] [-h] FILE...
  -n LINES   how many lines to show (default 3)
  -v         print a header before each file
  -h         show this help
exit status: 2
error: -n needs a number, got 'many'
exit status: 2
error: no files given
Usage: lines.sh [-n LINES] [-v] [-h] FILE...
  -n LINES   how many lines to show (default 3)
  -v         print a header before each file
  -h         show this help
exit status: 2
```

Every failure path ends with exit status 2 (usage error), while the happy paths exit 0. The file name
with a space survived because the loop uses `"$@"`.

And the raw positional parameters, so you can see `"$@"` against `"$*"` and `shift`. Save as
`positional.sh`:

```bash
#!/usr/bin/env bash
# positional.sh - the raw material: $0 $1 $# "$@" shift
set -euo pipefail

show() {
    echo "count: $#"
    echo "first: ${1:-<none>}"
    for arg in "$@"; do
        echo "  [$arg]"
    done
}

echo "--- quoted args keep their spaces"
show one "two words" three

echo "--- \"\$*\" glues everything into ONE word; \"\$@\" keeps them apart"
set -- a "b c" d
printf '<%s>' "$*"; echo
printf '<%s>' "$@"; echo

echo "--- shift removes the first argument"
echo "before: $# args, first is $1"
shift
echo "after:  $# args, first is $1"

echo "--- default for a missing argument"
set --
name="${1:-world}"
echo "Hello, ${name}"
```

**Expected output**

```text
--- quoted args keep their spaces
count: 3
first: one
  [one]
  [two words]
  [three]
--- "$*" glues everything into ONE word; "$@" keeps them apart
<a b c d>
<a><b c><d>
--- shift removes the first argument
before: 3 args, first is a
after:  2 args, first is b c
--- default for a missing argument
Hello, world
```

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `for f in $@` | Splits `my notes.txt` into two words | `for f in "$@"` |
| `getopts "vn"` for an option that takes a value | `-n 3` leaves `3` as a file and `OPTARG` empty | `getopts "vn:"` |
| Forgetting `shift $((OPTIND-1))` | The options are still in `"$@"` | Shift after the loop |
| `$1` under `set -u` with no arguments | `unbound variable` | `${1:-}` or check `$#` first |
| `if [ $# -eq 0 ]` then using `$1` | Fine, but `[ ]` pitfalls return | `(( $# == 0 ))` |
| Calling a `getopts` function twice | `OPTIND` was not reset | `local OPTIND=1` |
| `echo "$@"` to print arguments | Prints them space-joined, losing boundaries | `printf '<%s>' "$@"` |
| Options after file names (`tool a.txt -v`) | `getopts` stops at the first non-option | Document that options come first |

## Exercises

### Easy: greet everyone

Write a script that greets every argument (`Hello, Ada!`), falling back to `world` when there are
none, and finishes with the number of greetings. Names may contain spaces.

**Acceptance criteria**

- `bash easy.sh Ada "Grace Hopper"` prints two greetings with `(2 greeting(s))`.
- `bash easy.sh` prints `Hello, world!`.
- Arguments are always quoted.

### Medium: `du-report` with `-d`

Write a function that parses `[-d DEPTH] [-h] DIR`, validates that `DEPTH` is a number and `DIR` is a
directory, and prints sizes with `du -b --max-depth=DEPTH`. Create a demo tree with two files of
2048 and 1024 bytes in a temp directory and call the function with good and bad arguments.

**Acceptance criteria**

- With `-d 1` the report lists `3072 .`, `1024 ./cache` and `2048 ./logs` (sorted by name).
- A non-numeric depth prints an error and returns 2; an unknown option prints an error and returns 2.
- The function declares `local OPTIND=1` and can be called repeatedly.

### Hard: long options

Write `parse` that supports `-n N`, `--lines N`, `--lines=N`, `-v`/`--verbose`, `-h`/`--help` and
`--`. Collect file names into an array. Test it with six argument lists, including a missing value, an
unknown option and a file named `-weird-name.txt` after `--`.

**Acceptance criteria**

- `--lines=5 -v a.txt "b c.txt"` yields `lines=5 verbose=1` and two files, one containing a space.
- `-n 2 -- -weird-name.txt` yields the file `-weird-name.txt`.
- `--lines` with no value and `--bogus` return 2 with a message on stderr.

### Break it

This script has **three bugs**: it does not read the `-n` value, the files are not separated from the
options, and file names with spaces break. Save as `break-it.sh`, run it, and fix it so it prints
`verbose=1 lines=3` followed by two files.

```bash
#!/usr/bin/env bash
set -- -v -n 3 report.txt "my notes.txt"      # pretend these came from the command line

verbose=0
lines=10
while getopts "vn" opt; do
    case $opt in
        v) verbose=1 ;;
        n) lines=$OPTARG ;;
    esac
done

echo "verbose=$verbose lines=$lines"
for f in $@; do
    echo "file: $f"
done
```

**Expected output**

```text
verbose=1 lines=
file: -v
file: -n
file: 3
file: report.txt
file: my
file: notes.txt
```

<details>
<summary>Hint</summary>

Look at the option string passed to `getopts`. Then look at what is left in `$@` after the loop, and
at the quotes on the last loop.

</details>

## Solutions

<details>
<summary>Easy</summary>

`set -- "world"` is a neat way to supply a default argument list so the loop needs no special case.

```bash
#!/usr/bin/env bash
# Day 16 easy: greet every name given as an argument, or "world" if there are none.
# Run it as:  bash easy.sh Ada "Grace Hopper"
set -euo pipefail

if (( $# == 0 )); then
    set -- "world"                    # give ourselves a default argument list
fi

for name in "$@"; do
    echo "Hello, ${name}!"
done
echo "(${#} greeting(s))"
```

**Expected output**

```text
Hello, world!
(1 greeting(s))
```

</details>

<details>
<summary>Medium</summary>

`OPTIND` is a Bash variable that `getopts` advances. Because it keeps its value between calls, a
function that parses options must reset it (`local OPTIND=1`).

```bash
#!/usr/bin/env bash
# Day 16 medium: a mini disk-usage reporter with getopts: du-report.sh [-d DEPTH] [-h] DIR
# Demo data is created in a temporary directory; the parser is exercised with fixed arguments.
set -euo pipefail

parse_and_report() {
    local depth=1 opt OPTIND=1       # reset OPTIND so the function can be called repeatedly
    while getopts ":d:h" opt; do
        case "$opt" in
            d) depth="$OPTARG" ;;
            h) echo "usage: du-report [-d DEPTH] DIR"; return 0 ;;
            :) echo "error: -$OPTARG needs a value" >&2; return 2 ;;
            \?) echo "error: unknown option -$OPTARG" >&2; return 2 ;;
        esac
    done
    shift $(( OPTIND - 1 ))
    [[ $# -eq 1 ]] || { echo "error: exactly one directory required" >&2; return 2; }
    [[ -d $1 ]] || { echo "error: '$1' is not a directory" >&2; return 1; }
    case "$depth" in ''|*[!0-9]*) echo "error: depth must be a number" >&2; return 2 ;; esac

    echo "usage of $(basename -- "$1") to depth ${depth}:"
    du -b --max-depth="$depth" -- "$1" | sort -k2 | sed "s#${1}#.#"
}

work="$(mktemp -d)"
mkdir -p "${work}/app/logs" "${work}/app/cache"
head -c 2048 /dev/zero > "${work}/app/logs/a.log"
head -c 1024 /dev/zero > "${work}/app/cache/c.bin"

parse_and_report -d 1 "${work}/app"
status=0
parse_and_report -d two "${work}/app" || status=$?
echo "bad depth -> exit ${status}"
status=0
parse_and_report -q "${work}/app" || status=$?
echo "bad option -> exit ${status}"

rm -rf -- "$work"
```

**Expected output**

```text
usage of app to depth 1:
3072 .
1024 ./cache
2048 ./logs
error: depth must be a number
bad depth -> exit 2
error: unknown option -q
bad option -> exit 2
```

</details>

<details>
<summary>Hard</summary>

`shift 2` consumes an option and its value; `--lines=*` uses `${1#*=}` to cut off everything up to
the `=`. After `--`, `files+=("$@")` takes all remaining arguments literally.

```bash
#!/usr/bin/env bash
# Day 16 hard: long options (--lines=5, --lines 5, --verbose, --help, --) with a while/case/shift loop.
# The parser is exercised with fixed argument lists, so the script is self-contained.
set -euo pipefail

parse() {
    lines=10; verbose=0; files=()
    while (( $# > 0 )); do
        case "$1" in
            -n|--lines)
                [[ $# -ge 2 ]] || { echo "error: $1 needs a value" >&2; return 2; }
                lines="$2"; shift 2 ;;
            --lines=*)   lines="${1#*=}"; shift ;;
            -v|--verbose) verbose=1; shift ;;
            -h|--help)   echo "usage: tool [-n|--lines N] [-v|--verbose] FILE..."; return 10 ;;
            --)          shift; files+=("$@"); break ;;       # everything after -- is a file
            -*)          echo "error: unknown option $1" >&2; return 2 ;;
            *)           files+=("$1"); shift ;;
        esac
    done
    case "$lines" in ''|*[!0-9]*) echo "error: lines must be a number, got '$lines'" >&2; return 2 ;; esac
    (( ${#files[@]} > 0 )) || { echo "error: no files" >&2; return 2; }
}

try() {
    local status=0
    echo "\$ tool $*"
    parse "$@" || status=$?
    if (( status == 0 )); then
        echo "  lines=${lines} verbose=${verbose} files=(${files[*]})"
    else
        echo "  parse returned ${status}"
    fi
}

try --lines=5 -v a.txt "b c.txt"
try --lines 7 a.txt
try -n 2 -- -weird-name.txt
try --lines
try --bogus a.txt
try --help
```

**Expected output**

```text
$ tool --lines=5 -v a.txt b c.txt
  lines=5 verbose=1 files=(a.txt b c.txt)
$ tool --lines 7 a.txt
  lines=7 verbose=0 files=(a.txt)
$ tool -n 2 -- -weird-name.txt
  lines=2 verbose=0 files=(-weird-name.txt)
$ tool --lines
error: --lines needs a value
  parse returned 2
$ tool --bogus a.txt
error: unknown option --bogus
  parse returned 2
$ tool --help
usage: tool [-n|--lines N] [-v|--verbose] FILE...
  parse returned 10
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `"vn"` should be `"vn:"`, otherwise `-n` takes no value and `OPTARG` is empty. Bug 2: no
`shift $((OPTIND-1))`, so the option words appear as file names. Bug 3: unquoted `$@` splits
`my notes.txt`.

```bash
#!/usr/bin/env bash
# Fixed: "n:" so -n takes a value, shift away the options, and quote "$@".
set -euo pipefail

set -- -v -n 3 report.txt "my notes.txt"      # pretend these came from the command line

verbose=0
lines=10
while getopts "vn:" opt; do
    case $opt in
        v) verbose=1 ;;
        n) lines=$OPTARG ;;
        *) exit 2 ;;
    esac
done
shift $(( OPTIND - 1 ))

echo "verbose=$verbose lines=$lines"
for f in "$@"; do
    echo "file: $f"
done
```

**Expected output**

```text
verbose=1 lines=3
file: report.txt
file: my notes.txt
```

</details>

Solution files live in [`solutions/day-16/`](solutions/day-16/).

## Self-check

1. What is the difference between `"$@"` and `"$*"`?
2. What does the colon after `n` mean in `getopts "n:v"`?
3. What does `shift $((OPTIND - 1))` do?
4. What does `--` mean to a command-line tool?
5. Why validate arguments before doing any work?

<details>
<summary>Answers</summary>

1. `"$@"` yields each argument as a separate word; `"$*"` joins them into a single word.
2. `-n` requires a value, which is stored in `OPTARG`.
3. It removes the parsed options so `"$@"` holds only the remaining arguments.
4. End of options: the rest are operands even if they begin with `-`.
5. So a typo fails fast and cleanly instead of after half the work is done.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `$0 $1 $2 ... $#` | Name, arguments, count |
| `"$@"` | All arguments, safely |
| `shift [n]` | Drop the first n |
| `set -- a b` | Replace the arguments |
| `getopts ":n:vh" opt` | Parse short options (silent mode) |
| `$OPTARG`, `$OPTIND` | Value of the option, next index |
| `shift $((OPTIND-1))` | Keep the operands |
| `${1:-default}` | Default for a missing argument |
| `case "$1" in --x=*) v="${1#*=}" ;; esac` | Long option with value |
| `exit 2` | Conventional "usage error" |

## Further reading

- [Greg's Wiki: BashFAQ/035](https://mywiki.wooledge.org/BashFAQ/035): how to parse options in a script,
  including long options.
- [Greg's Wiki: BashGuide/Parameters](https://mywiki.wooledge.org/BashGuide/Parameters): a gentle
  introduction to positional and special parameters.

**Next:** [Day 17](day-17.md)
