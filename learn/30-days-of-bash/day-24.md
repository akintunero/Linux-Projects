# Day 24: Interactive Scripts: `read`, `select` and Menus

> **Time:** ~55 min · **Level:** Intermediate
> **Prerequisites:** [Day 23](day-23.md)

## Goal

By the end of this lesson you can:

- Prompt for input with `read` (defaults, silent input, timeouts) and validate the answer.
- Build a numbered menu with `select`.
- Make a script work both interactively and unattended.

## Concepts

### `read` in practice

```bash
read -r -p "Name: " name              # -r: keep backslashes, -p: prompt
read -r -s -p "Password: " pw; echo   # -s: do not echo (the echo prints the newline you hid)
read -r -n 1 -p "Press a key " key    # -n 1: return after one character
read -r -t 10 -p "Continue? " reply   # -t 10: give up after 10 seconds (status > 128)
read -r -a words <<< "a b c"          # -a: split into an array
read -r -e -i "default" -p "Edit: " v # -e -i: offer an editable default (terminal only)
```

- `read` returns non-zero at end of input. Always handle it (`|| return 1`) or an unattended
  script will loop forever on EOF.
- `-p` shows its prompt **only when input comes from a terminal**. When you test with a
  here-string or a pipe, no prompt is printed.
- A default is just `${reply:-default}`.

### Validate, then use

Never trust typed input. Check shape first, then use it:

```bash
case "$age" in
    ''|*[!0-9]*) echo "age must be a number" >&2; exit 2 ;;
esac
(( age > 17 ))
```

### `select`: a quick numbered menu

```bash
PS3="Choose: "
select choice in start stop quit; do
    case "$choice" in
        start|stop) echo "you chose $choice" ;;
        quit)       break ;;
        *)          echo "invalid: $REPLY" ;;
    esac
done
```

`select` prints the menu to stderr, shows `PS3`, stores the typed number in `$REPLY` and the
chosen text in the variable (empty if the number is invalid). It loops until `break` or end of input.

### Interactive or not?

Scripts run from cron, CI or a pipe have no human. Detect it with `[[ -t 0 ]]` (stdin is a
terminal) and offer a non-interactive path: options, environment variables (`ACTION=list`) or a
`--yes` flag.

> [!TIP]
> Test interactive scripts by feeding the answers: `./script.sh <<< $'yes\n3'`, or
> `printf '%s\n' a b | ./script.sh`. `$'...\n...'` is Bash syntax for a string with real newlines.

### Confirmation before danger

For anything destructive, ask for confirmation and default to **no**. A `--force`/`--yes` flag can
skip the question for automation.

## Worked example

Each section is one technique, and the "typing" comes from here-strings so the output is
repeatable. Save as `interactive.sh`.

```bash
#!/usr/bin/env bash
# interactive.sh - read, defaults, confirmation, select menus, timeouts
# In a terminal the -p prompts are shown. Here the "typing" comes from here-strings,
# so only the results appear.
set -euo pipefail

echo "--- 1. read splits on whitespace into as many variables as you name"
read -r first rest <<< "Ada Lovelace King"
echo "first=[${first}] rest=[${rest}]"

echo "--- 2. a prompt with a default (empty answer -> default)"
ask() {                                   # ask "Prompt" "default"
    local reply
    read -r -p "$1 [$2]: " reply || true
    echo "${reply:-$2}"
}
echo "typed nothing -> $(ask 'Your name' 'friend' <<< '')"
echo "typed Grace   -> $(ask 'Your name' 'friend' <<< 'Grace')"

echo "--- 3. yes/no that keeps asking until the answer is valid (and stops at end of input)"
confirm() {
    local reply
    while true; do
        read -r -p "$1 [y/n] " reply || return 1
        case "${reply,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *)     echo "please answer y or n" >&2 ;;
        esac
    done
}
if confirm "Delete the cache?" <<< $'maybe\nY'; then echo "-> confirmed"; fi
if confirm "Continue?" <<< 'n'; then echo "-> yes"; else echo "-> no"; fi

echo "--- 4. timeouts, single keys, and silent input (for passwords)"
if read -r -t 1 reply < <(sleep 3); then echo "got input"; else echo "-> timed out (status $?)"; fi
read -r -n 1 key <<< "xyz"
echo "-> first key only: ${key}"
echo "(use read -r -s -p 'Password: ' pw  in a terminal: the typing is not echoed)"

echo "--- 5. select builds a numbered menu; the answer is a number or 'reply'"
PS3="Choose an action: "
select action in start stop quit; do
    case "$action" in
        start|stop) echo "you chose to ${action}" ;;
        quit)       echo "bye"; break ;;
        *)          echo "invalid choice: ${REPLY}" ;;
    esac
done <<< $'7\n1\n3'

echo "--- 6. is a human attached? (-t 0 tests whether stdin is a terminal)"
if [[ -t 0 ]]; then echo "interactive"; else echo "not interactive: stdin is a pipe or file"; fi
```

**Expected output**

```text
--- 1. read splits on whitespace into as many variables as you name
first=[Ada] rest=[Lovelace King]
--- 2. a prompt with a default (empty answer -> default)
typed nothing -> friend
typed Grace   -> Grace
--- 3. yes/no that keeps asking until the answer is valid (and stops at end of input)
please answer y or n
-> confirmed
-> no
--- 4. timeouts, single keys, and silent input (for passwords)
-> timed out (status 142)
-> first key only: x
(use read -r -s -p 'Password: ' pw  in a terminal: the typing is not echoed)
--- 5. select builds a numbered menu; the answer is a number or 'reply'
1) start
2) stop
3) quit
Choose an action: invalid choice: 7
Choose an action: you chose to start
Choose an action: bye
--- 6. is a human attached? (-t 0 tests whether stdin is a terminal)
not interactive: stdin is a pipe or file
```

In section 3 the first answer `maybe` is rejected, then `Y` is accepted. In section 5 the typed `7`
gives an empty choice, so `*)` reports `invalid choice: 7`.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `read name` | Backslashes are interpreted: `Ada\Lovelace` becomes `AdaLovelace` | `read -r name` |
| `if [ $age -gt 17 ]` with typed input | Empty or non-numeric text breaks the test | Validate first, then `(( age > 17 ))` |
| `while true; do read -p ... ans; ...` | At end of input `read` fails and the loop spins forever | `read ... \|\| return 1` |
| No default for empty input | The variable stays empty | `${city:-Paris}` |
| `echo` after `read -s` forgotten | The next output continues on the same line | Print a newline after the password |
| Testing with a terminal each time | Slow, not repeatable | Feed answers with `<<<` or a pipe |
| Password passed as an argument | Visible in `ps` | `read -s`, or read from a file with mode `600` |
| Interactive-only script | Cannot be automated | Offer flags/env vars for every question |

## Exercises

### Easy: questions with defaults

Write `ask PROMPT DEFAULT` that prints the typed answer, or the default if the answer is empty.
Collect a name, a city and a retry count with defaults `friend`, `Paris` and `3`, feeding the
"typing" from a here-string (empty name, `Berlin`, empty retries).

**Acceptance criteria**

- Output: `name=friend city=Berlin retries=3`.
- `read -r` is used.
- The function works the same on a terminal (where the prompts are visible).

### Medium: a trustworthy `confirm`

Write `confirm PROMPT` that returns 0 for `y`/`yes`, 1 for `n`/`no` (any case), re-asks on anything
else, and returns 1 with a message when input ends. Test six inputs, including garbage followed by a
valid answer, and empty input.

**Acceptance criteria**

- `YES` is accepted; `what?` then `yes` yields yes; empty input yields no.
- The function never loops forever.
- The "please answer y or n" message goes to stderr.

### Hard: menu or unattended

Write a helper with a `select` menu (`create backup`, `list backups`, `quit`) that creates real
`.tar.gz` archives in a temporary directory. If `ACTION` is set, skip the menu and run that action
(`create`, `list`; anything else exits with status 2). Drive the menu with
`<<< $'9\n1\n1\n2\n3'`.

**Acceptance criteria**

- Choice `9` is reported invalid and the menu continues.
- Two archives are created and listed, then the menu ends with `bye`.
- `ACTION=create` and `ACTION=list` work with no input; `ACTION=bogus` exits 2.
- The temp directory is removed on exit (trap).

### Break it

This script has **three bugs**: it loses a backslash, crashes on non-numeric input and accepts
an empty city. Save as `break-it.sh`, run it, and fix it so the name keeps its backslash, `abc` is
rejected politely and the city defaults to `Paris`.

```bash
#!/usr/bin/env bash
# The "typing" is supplied here so the script runs unattended.
exec < <(printf '%s\n' 'Ada\Lovelace' 'abc' '')

read -p "Name: " name
echo "name=[$name]"

read -p "Age: " age
if [ $age -gt 17 ]; then
    echo "adult"
fi

read -p "City (default Paris): " city
echo "city=[$city]"
```

**Expected output**

```text
name=[AdaLovelace]
break-it.sh: line 9: [: abc: integer expected
city=[]
```

<details>
<summary>Hint</summary>

Name the `read` option that stops backslash processing. For the age, test with `case` before any
numeric comparison. For the city, use a default expansion.

</details>

## Solutions

<details>
<summary>Easy</summary>

`{ read ...; read ...; } <<< $'...'` reads three lines from one here-string. Each `ask` then gets its
own piece of "typing".

```bash
#!/usr/bin/env bash
# Day 24 easy: collect a name, a city and a number of retries, each with a default.
# The "typing" comes from a here-string; in a terminal you would type the answers.
set -euo pipefail

ask() {                                   # ask PROMPT DEFAULT  -> prints the answer
    local reply
    read -r -p "$1 [$2]: " reply || true
    echo "${reply:-$2}"
}

{
    read -r name_in
    read -r city_in
    read -r retries_in
} <<< $'\nBerlin\n'                       # name: empty, city: Berlin, retries: empty

name="$(ask 'Name' 'friend' <<< "$name_in")"
city="$(ask 'City' 'Paris' <<< "$city_in")"
retries="$(ask 'Retries' '3' <<< "$retries_in")"

echo "name=${name} city=${city} retries=${retries}"
```

**Expected output**

```text
name=friend city=Berlin retries=3
```

</details>

<details>
<summary>Medium</summary>

`read ... || { ...; return 1; }` makes the end of input a clean "no". The `${reply,,}` lower-cases the
answer so `YES`, `Yes` and `yes` all work.

```bash
#!/usr/bin/env bash
# Day 24 medium: confirm() that re-asks on bad input, accepts yes/no in any case,
# and returns failure (instead of looping forever) when input ends.
set -euo pipefail

confirm() {
    local reply
    while true; do
        read -r -p "$1 [y/n] " reply || { echo "(no answer: assuming no)" >&2; return 1; }
        case "${reply,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *)     echo "please answer y or n" >&2 ;;
        esac
    done
}

run_case() {                              # run_case DESCRIPTION INPUT
    local result
    if confirm "Overwrite the file?" <<< "$2" 2>/dev/null; then result=yes; else result=no; fi
    printf '%-22s -> %s\n' "$1" "$result"
}

run_case "y"                     "y"
run_case "YES (capitals)"        "YES"
run_case "n"                     "n"
run_case "garbage then yes"      $'what?\nyes'
run_case "garbage then no"       $'what?\nno'
run_case "empty input (EOF)"     ""
```

**Expected output**

```text
y                      -> yes
YES (capitals)         -> yes
n                      -> no
garbage then yes       -> yes
garbage then no        -> no
empty input (EOF)      -> no
```

</details>

<details>
<summary>Hard</summary>

`select` works on any list and reads from stdin, which is why a here-string can drive it. In the
unattended path nothing reads stdin at all. The counter lives in `menu` so names do not collide.

```bash
#!/usr/bin/env bash
# Day 24 hard: a menu-driven backup helper that also works unattended.
#   interactive:      choices come from a select menu
#   non-interactive:  ACTION=create|list|quit  (no questions asked)
# Everything happens in a temporary directory; the "typing" comes from here-strings.
set -euo pipefail

work="$(mktemp -d)"
mkdir -p "${work}/data" "${work}/backups"
echo "important" > "${work}/data/file.txt"
trap 'rm -rf -- "$work"' EXIT

do_create() {
    local name="backup-$1.tar.gz"
    tar -czf "${work}/backups/${name}" -C "$work" data
    echo "created ${name}"
}
do_list() {
    echo "backups:"
    local f
    for f in "${work}"/backups/*.tar.gz; do
        [[ -e $f ]] && echo "  ${f##*/}"
    done
    return 0
}

menu() {
    local counter=0
    PS3="Action: "
    select choice in "create backup" "list backups" "quit"; do
        case "$choice" in
            "create backup") counter=$(( counter + 1 )); do_create "$counter" ;;
            "list backups")  do_list ;;
            "quit")          echo "bye"; return 0 ;;
            *)               echo "invalid choice '${REPLY}'" ;;
        esac
    done
}

main() {
    if [[ -n ${ACTION:-} ]]; then                 # unattended mode
        case "$ACTION" in
            create) do_create "auto" ;;
            list)   do_list ;;
            *)      echo "unknown ACTION '${ACTION}'" >&2; return 2 ;;
        esac
    else
        menu
    fi
}

echo "=== interactive session (typed: 9, 1, 1, 2, 3) ==="
main <<< $'9\n1\n1\n2\n3' 2>&1
echo "=== unattended: ACTION=create then ACTION=list ==="
ACTION=create main
ACTION=list main
status=0
ACTION=bogus main 2>/dev/null || status=$?
echo "unknown action -> exit ${status}"
```

**Expected output**

```text
=== interactive session (typed: 9, 1, 1, 2, 3) ===
1) create backup
2) list backups
3) quit
Action: invalid choice '9'
Action: created backup-1.tar.gz
Action: created backup-2.tar.gz
Action: backups:
  backup-1.tar.gz
  backup-2.tar.gz
Action: bye
=== unattended: ACTION=create then ACTION=list ===
created backup-auto.tar.gz
backups:
  backup-1.tar.gz
  backup-2.tar.gz
  backup-auto.tar.gz
unknown action -> exit 2
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `read` without `-r` ate the backslash. Bug 2: `[ $age -gt 17 ]` with `abc` is an error;
validate first. Bug 3: the empty answer was used as-is; apply `${city:-Paris}`.

```bash
#!/usr/bin/env bash
# Fixed: read -r, validate numbers before comparing, and apply defaults.
set -euo pipefail
exec < <(printf '%s\n' 'Ada\Lovelace' 'abc' '')

read -r -p "Name: " name
echo "name=[$name]"

read -r -p "Age: " age
case "$age" in
    ''|*[!0-9]*) echo "age must be a number (got '${age}')" ;;
    *)           if (( age > 17 )); then echo "adult"; fi ;;
esac

read -r -p "City (default Paris): " city
city="${city:-Paris}"
echo "city=[$city]"
```

**Expected output**

```text
name=[Ada\Lovelace]
age must be a number (got 'abc')
city=[Paris]
```

</details>

Solution files live in [`solutions/day-24/`](solutions/day-24/).

## Self-check

1. What does `read -r` prevent?
2. How do you read a password without echoing it?
3. Why can an unattended script hang or loop on `read`?
4. What are `PS3` and `REPLY` in `select`?
5. How can a script tell whether a human is attached?

<details>
<summary>Answers</summary>

1. Backslash escape processing in the input.
2. `read -r -s -p "Password: " pw`, then print a newline.
3. At end of input `read` fails; without handling that, a `while true` loop never ends.
4. `PS3` is the prompt string; `REPLY` holds exactly what the user typed.
5. `[[ -t 0 ]]` tests whether stdin is a terminal.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `read -r var` | Read a line |
| `read -r -p "Q: " var` | With prompt (terminal only) |
| `read -r -s var` | Silent |
| `read -r -t 5 var` | Timeout (status > 128) |
| `read -r -n 1 var` | One character |
| `read -r -a arr` | Into an array |
| `select x in a b c; do ...; done` | Numbered menu |
| `PS3`, `REPLY` | Menu prompt, raw answer |
| `[[ -t 0 ]]` | Interactive? |
| `<<< $'a\nb'` | Feed test answers |

## Further reading

- [Greg's Wiki: BashFAQ/001](https://mywiki.wooledge.org/BashFAQ/001): reading input line by line and
  the details of `IFS` and `-r`.

**Next:** [Day 25](day-25.md)
