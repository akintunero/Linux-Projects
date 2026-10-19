# Day 19: Aliases, Functions and Shell Customisation

> **Time:** ~45 min · **Level:** Intermediate
> **Prerequisites:** [Day 18](day-18.md)

## Goal

By the end of this lesson you can:

- Create and remove aliases, and explain why they do not work in scripts or with arguments.
- Replace aliases with shell functions when you need arguments or logic.
- Organise your personal customisations in `~/.bashrc` and build a safer replacement for `rm`.

## Concepts

### Aliases

An alias is text substitution for the **first word** of a command, in interactive shells:

```bash
alias ll='ls -lA'
alias gs='git status --short'
alias                 # list all aliases
unalias ll            # remove one
type ll               # "ll is aliased to ..."
```

Bypass an alias once with `\ll` or `command ll`.

Limits of aliases:

- They do **not** expand in scripts unless you run `shopt -s expand_aliases` (do not; use functions).
- They cannot use arguments in the middle (`alias mkcd='mkdir -p $1 && cd $1'` never receives `$1`).
- They cannot contain logic beyond a single command line.

### Functions: the better alias

```bash
mkcd() { mkdir -p -- "$1" && cd -- "$1"; }
ll()   { ls -lA "$@"; }
```

Functions take arguments (`"$@"`), can use `if`, `case` and loops, work in scripts, and appear in
`declare -f`. A function that must change your directory (`cd`) **has** to be a function or alias
sourced into your shell. A script runs in a child and cannot move your shell.

### Shell options and prompt

```bash
shopt -s histappend            # append to history instead of overwriting
shopt -s checkwinsize          # update LINES/COLUMNS after resizing
HISTCONTROL=ignoreboth         # skip duplicates and commands starting with a space
HISTSIZE=10000
PS1='\u@\h:\w\$ '              # user@host:dir$
```

### Organising `~/.bashrc`

Keep `~/.bashrc` short and load pieces from a directory:

```bash
for f in ~/.bashrc.d/*.sh; do
    [[ -r $f ]] && source "$f"
done
```

Put aliases in `~/.bashrc.d/aliases.sh`, functions in `functions.sh`, and so on. After editing, run
`source ~/.bashrc` (or open a new terminal).

> [!WARNING]
> Do not alias `rm` to `rm -rf` or `cp` to `cp -f`: scripts you run later may rely on the safe
> defaults, and you will forget it is there. Do alias safer variants under **new** names
> (`trash`, `rmi`).

### Tab completion

`complete -W "start stop status" myservice` makes `myservice <TAB>` offer those three words. Real
completions live in `/usr/share/bash-completion/`.

## Worked example

Six short demos. Because a script is not interactive, it begins with `shopt -s expand_aliases` so the
alias lines behave as they do in your terminal. Save as `alias.sh` and run it in an empty directory.

```bash
#!/usr/bin/env bash
# alias.sh - aliases and their better replacement, functions
# Scripts do not expand aliases unless you ask; interactive shells always do.
shopt -s expand_aliases
set -euo pipefail

echo "--- 1. an alias is plain text substitution at the start of a command"
alias ll='ls -lA --color=never'
alias ..='cd ..'
alias | sort

touch visible .hidden
ll | awk 'NR > 1 { print $NF }'

echo "--- 2. type tells you what a name is"
type ll
type cd
type grep | sed 's#/.*/#/.../#'

echo "--- 3. bypass an alias: backslash or command"
alias ls='ls -l'
echo "alias:    $(ls visible | wc -w) word(s) of output"
echo "bypassed: $(\ls visible | wc -w) word(s) of output"
unalias ls

echo "--- 4. aliases cannot take arguments in the middle; functions can"
mkcd() {
    mkdir -p -- "$1" && cd -- "$1"
}
mkcd projects/demo
echo "now in: ${PWD##*/}"
cd ../..

echo "--- 5. functions can use all of Bash"
extract() {
    case "$1" in
        *.tar.gz|*.tgz) tar -xzf "$1" ;;
        *.zip)          unzip -q "$1" ;;
        *)              echo "don't know how to extract '$1'" >&2; return 1 ;;
    esac
}
mkdir -p src && echo data > src/f.txt && tar -czf src.tgz src && rm -r src
extract src.tgz && echo "extracted: $(cat src/f.txt)"
extract notes.rar || echo "extract returned $?"

echo "--- 6. persist them: put definitions in ~/.bashrc (or ~/.bashrc.d/*.sh)"
declare -f mkcd | head -n 1
```

**Expected output**

```text
--- 1. an alias is plain text substitution at the start of a command
alias ..='cd ..'
alias ll='ls -lA --color=never'
.hidden
alias.sh
visible
--- 2. type tells you what a name is
ll is aliased to `ls -lA --color=never'
cd is a shell builtin
grep is /.../grep
--- 3. bypass an alias: backslash or command
alias:    9 word(s) of output
bypassed: 1 word(s) of output
--- 4. aliases cannot take arguments in the middle; functions can
now in: demo
--- 5. functions can use all of Bash
extracted: data
don't know how to extract 'notes.rar'
extract returned 1
--- 6. persist them: put definitions in ~/.bashrc (or ~/.bashrc.d/*.sh)
mkcd ()
```

Section 3 shows the effect of the alias on `ls`: with `-l` there are nine words, without it just the
file name. Section 4 and 5 are the same ideas as aliases, but with arguments and a `case`.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| Using an alias in a script | Aliases are off in non-interactive shells: `command not found` | Use a function |
| `alias mkcd='mkdir -p $1 && cd $1'` | `$1` is empty; arguments are appended after the alias text | `mkcd() { ...; }` |
| Editing `~/.bashrc` and nothing changes | The open shell has already read it | `source ~/.bashrc` |
| `alias rm='rm -rf'` | Removes safety nets everywhere and trains bad habits | Add a `trash` function instead |
| A script that should change directory | It runs in a child | `source` a file, or define a function |
| `alias` with a name that already exists | You shadow the real command | `type name` first |
| Customisations that print output in `~/.bashrc` | Breaks `scp`, `rsync` and other tools that start a shell | Only print when `[[ $- == *i* ]]` |

## Exercises

### Easy: an alias snippet

Write four aliases (`ll`, `la`, `grep` with line numbers, `gs`) to a file `aliases.sh`, `source` it, list
them, and prove that `ll` shows hidden files. In real life the snippet goes in `~/.bashrc.d/`; here
use a temp directory.

**Acceptance criteria**

- `alias | sort` lists all four.
- The `ll` output includes `.secret`.
- Nothing is changed outside the temp directory.

### Medium: `mkcd` and `extract`

Write `mkcd DIR` (create and enter, handling names with spaces, usage error with no argument) and
`extract FILE` that unpacks `.tar.gz`/`.tgz`, `.tar` or `.zip` and refuses unknown extensions or
missing files with a clear message and non-zero status.

**Acceptance criteria**

- `mkcd "projects/my demo"` enters `my demo`.
- `extract src.tgz` and `extract src.tar` restore `src/f.txt`.
- `extract notes.rar` (existing) and `extract missing.tgz` both fail with exit status 1 and a message.

### Hard: `trash`

Write a `trash` function that moves files into `TRASH_DIR` instead of deleting them. A second file with
the same name must not overwrite the first (`report.txt`, `report.txt.1`). Add `trash_list` and a
`trash_empty` that refuses to run unless `CONFIRM=yes`. Test it entirely inside a temp directory.

**Acceptance criteria**

- Trashing `a/report.txt` and `b/report.txt` yields `report.txt` and `report.txt.1` in the trash.
- A nonexistent file prints an error and the function returns 1, but the other files are still trashed.
- `trash_empty` without `CONFIRM=yes` deletes nothing; with it, the trash is empty.

### Break it

This script has **two bugs**, the first of which hides the second. Save as `break-it.sh`, run it, and
fix it so it lists `a.txt` and ends with `now in: newdir`.

```bash
#!/usr/bin/env bash
alias ll='ls -l'
alias mkcd='mkdir -p $1 && cd $1'

touch a.txt
ll
mkcd newdir
echo "now in: ${PWD##*/}"
```

**Expected output**

```text
break-it.sh: line 6: ll: command not found
break-it.sh: line 7: mkcd: command not found
now in: bash-lab
```

<details>
<summary>Hint</summary>

Neither command is "found". Why? Then ask what `$1` would be inside an alias, and look at the last
line of output: did `mkcd` change directory?

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 19 easy: write your aliases to a snippet file, load it, and use them.
# Temporary files only. In your real setup the snippet lives in ~/.bashrc or ~/.bashrc.d/.
shopt -s expand_aliases
set -euo pipefail

work="$(mktemp -d)"
cd "$work"

cat > aliases.sh <<'EOF'
alias ll='ls -lA --color=never'
alias la='ls -A'
alias grep='grep --color=never -n'
alias gs='git status --short'
EOF

source ./aliases.sh                      # load them into this shell
touch notes.txt .secret

echo "--- defined aliases"
alias | sort

echo "--- ll shows hidden files too: $(ll | awk 'NR > 1 { print $NF }' | tr '\n' ' ')"
echo "--- la: $(la | tr '\n' ' ')"
echo "--- grep alias adds line numbers:"
printf 'one\ntwo\n' | grep tw

cd / && rm -rf -- "$work"
```

**Expected output**

```text
--- defined aliases
alias grep='grep --color=never -n'
alias gs='git status --short'
alias la='ls -A'
alias ll='ls -lA --color=never'
--- ll shows hidden files too: .secret aliases.sh notes.txt
--- la: .secret aliases.sh notes.txt
--- grep alias adds line numbers:
2:two
```

</details>

<details>
<summary>Medium</summary>

`mkdir -p -- "$1" && cd -- "$1"`: the `&&` means we only `cd` if `mkdir` worked; `--` protects names
that start with a dash.

```bash
#!/usr/bin/env bash
# Day 19 medium: two helpers that need arguments, so they are functions, not aliases.
# Temporary files only.
set -euo pipefail

mkcd() {
    [[ $# -eq 1 ]] || { echo "usage: mkcd DIR" >&2; return 2; }
    mkdir -p -- "$1" && cd -- "$1"
}

extract() {
    [[ -f ${1:-} ]] || { echo "extract: '${1:-}' is not a file" >&2; return 1; }
    case "$1" in
        *.tar.gz|*.tgz) tar -xzf "$1" ;;
        *.tar)          tar -xf "$1" ;;
        *.zip)          unzip -q "$1" ;;
        *)              echo "extract: don't know how to extract '$1'" >&2; return 1 ;;
    esac
}

work="$(mktemp -d)"
cd "$work"

mkcd "projects/my demo"
echo "mkcd: now in '${PWD##*/}'"
cd "$work"

mkdir -p src && echo "payload" > src/f.txt
tar -czf src.tgz src && tar -cf src.tar src
rm -r src

extract src.tgz && echo "tgz  -> $(cat src/f.txt)"
rm -r src
extract src.tar && echo "tar  -> $(cat src/f.txt)"

touch notes.rar
status=0
extract notes.rar || status=$?
echo "unknown type -> exit ${status}"
status=0
extract missing.tgz || status=$?
echo "missing file -> exit ${status}"

cd / && rm -rf -- "$work"
```

**Expected output**

```text
mkcd: now in 'my demo'
tgz  -> payload
tar  -> payload
extract: don't know how to extract 'notes.rar'
unknown type -> exit 1
extract: 'missing.tgz' is not a file
missing file -> exit 1
```

</details>

<details>
<summary>Hard</summary>

The `while [[ -e $dest ]]` loop finds the first free name. `"${TRASH_DIR:?}"/*` aborts if the variable
is empty, so a bug cannot turn the command into `rm -rf /*`.

```bash
#!/usr/bin/env bash
# Day 19 hard: a safer replacement for rm - move files to a trash folder instead of deleting.
# Everything happens inside a temporary directory, including the trash itself.
set -euo pipefail

work="$(mktemp -d)"
TRASH_DIR="${work}/trash"

trash() {
    local f base dest n rc=0
    mkdir -p -- "$TRASH_DIR"
    for f in "$@"; do
        if [[ ! -e $f ]]; then
            echo "trash: ${f}: no such file" >&2
            rc=1
            continue
        fi
        base="${f##*/}"
        dest="${TRASH_DIR}/${base}"
        n=1
        while [[ -e $dest ]]; do              # never overwrite an earlier trashed file
            dest="${TRASH_DIR}/${base}.${n}"
            n=$(( n + 1 ))
        done
        mv -- "$f" "$dest"
        echo "trashed: ${f} -> ${dest##*/}"
    done
    return "$rc"
}

trash_list() {
    echo "in trash:"
    ls -1 "$TRASH_DIR" | sed 's/^/  /'
}

trash_empty() {
    if [[ ${CONFIRM:-no} != yes ]]; then
        echo "trash_empty: set CONFIRM=yes to really delete $(ls -1 "$TRASH_DIR" | wc -l) item(s)" >&2
        return 1
    fi
    rm -rf -- "${TRASH_DIR:?}"/*
    echo "trash emptied"
}

cd "$work"
mkdir -p a b
echo one > a/report.txt
echo two > b/report.txt
echo three > "my notes.txt"

trash a/report.txt b/report.txt "my notes.txt"
status=0
trash does-not-exist.txt || status=$?
echo "exit status for a missing file: ${status}"

trash_list
status=0
trash_empty || status=$?
echo "without confirmation: exit ${status}, still $(ls -1 "$TRASH_DIR" | wc -l) item(s)"
CONFIRM=yes trash_empty
echo "left in trash: $(ls -1 "$TRASH_DIR" | wc -l)"

cd / && rm -rf -- "$work"
```

**Expected output**

```text
trashed: a/report.txt -> report.txt
trashed: b/report.txt -> report.txt.1
trashed: my notes.txt -> my notes.txt
trash: does-not-exist.txt: no such file
exit status for a missing file: 1
in trash:
  my notes.txt
  report.txt
  report.txt.1
trash_empty: set CONFIRM=yes to really delete 3 item(s)
without confirmation: exit 1, still 3 item(s)
trash emptied
left in trash: 0
```

</details>

<details>
<summary>Break it</summary>

Bug 1: aliases are not expanded in a script, so `ll` and `mkcd` were "not found". Bug 2 (hidden by
the first): even with aliases enabled, `$1` inside `alias mkcd='...$1...'` is empty. Functions solve
both.

```bash
#!/usr/bin/env bash
# Fixed: use functions (they work in scripts and take arguments) instead of aliases.
ll() { ls -l "$@"; }
mkcd() { mkdir -p -- "$1" && cd -- "$1"; }

touch a.txt
ll a.txt | awk '{ print $NF }'
mkcd newdir
echo "now in: ${PWD##*/}"
```

**Expected output**

```text
a.txt
now in: newdir
```

</details>

Solution files live in [`solutions/day-19/`](solutions/day-19/).

## Self-check

1. Why does an alias not work inside a script by default?
2. How do you run the real `ls` when `ls` is aliased?
3. Why must a "change directory" helper be a function and not a script?
4. What is wrong with `alias rm='rm -rf'`?
5. How do you load `~/.bashrc` changes into the current shell?

<details>
<summary>Answers</summary>

1. Alias expansion is only enabled for interactive shells (or after `shopt -s expand_aliases`).
2. `\ls` or `command ls`.
3. A script runs in a child process, which cannot change the parent's directory.
4. It removes the safety prompts for every use of `rm`, including by habit on other machines.
5. `source ~/.bashrc`.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `alias x='cmd'`, `unalias x` | Define / remove |
| `alias` | List all |
| `type x` | What is `x`? |
| `\x`, `command x` | Skip the alias |
| `f() { ...; }` | Function (preferred) |
| `declare -f f` | Show a function |
| `shopt -s histappend` | Shell option |
| `source ~/.bashrc` | Reload |
| `complete -W "a b" cmd` | Simple tab completion |

## Further reading

- [Greg's Wiki: BashFAQ/080](https://mywiki.wooledge.org/BashFAQ/080): why aliases are limited and what
  to use instead.
- [Greg's Wiki: DotFiles](https://mywiki.wooledge.org/DotFiles): which startup file to put what in.

**Next:** [Day 20](day-20.md)
