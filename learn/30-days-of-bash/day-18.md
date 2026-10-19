# Day 18: Environment Variables, `PATH` and Configuration

> **Time:** ~55 min · **Level:** Intermediate
> **Prerequisites:** [Day 17](day-17.md)

## Goal

By the end of this lesson you can:

- Explain the difference between shell variables and environment variables, and use `export`.
- Add a directory to `PATH` without breaking the existing one, and find which program will run.
- Load configuration from a `KEY=VALUE` file without using `eval`.

## Concepts

### Shell variables and the environment

A variable you assign (`name=value`) exists only in the current shell. **Exporting** it copies it
into the environment, which every child process inherits.

```bash
export APP_MODE=prod           # create/export in one step
declare -x APP_MODE            # same thing
printenv APP_MODE              # is it in the environment?
env                            # list the whole environment
unset APP_MODE                 # remove it
```

A child can never change its parent's variables. That is why `bash setup.sh` cannot set variables
for you, but `source setup.sh` (or `. setup.sh`) can: it runs the file *inside* your shell.

### One-shot variables

`LOG_LEVEL=debug cmd` puts the variable into `cmd`'s environment only, and nothing is left behind.

### `PATH`

`PATH` is a colon-separated list of directories searched, left to right, for a command name.

```bash
echo "$PATH"
type -a python3                # every match, in the order they would be used
command -v python3             # the one that will run
PATH="$HOME/bin:$PATH"         # prepend: keeps the old entries
```

> [!WARNING]
> `PATH="$HOME/bin"` (without `:$PATH`) throws away `/usr/bin` and `/bin`, so even `ls` is "not
> found" for the rest of the session. Always extend it. Never put `.` (the current directory) on
> your `PATH`; a hostile file called `ls` would run instead of the real one.

### Where settings live

| File | Read when |
|------|-----------|
| `~/.bash_profile` or `~/.profile` | Login shells (SSH, console) |
| `~/.bashrc` | Interactive non-login shells (new terminal windows) |
| `/etc/environment`, `/etc/profile.d/*.sh` | System-wide |

A common pattern: `~/.bash_profile` sources `~/.bashrc`. Changes to these files apply to **new**
shells; apply them to the current one with `source ~/.bashrc`.

### Configuration for scripts

Prefer, in this order: command-line options, environment variables, a config file, built-in
defaults. For a config file, **do not `source` it or `eval` it** if you do not control its content,
because it can run arbitrary commands. Read it as data instead: split each line on the first `=` and
validate the name. Never print secrets, and never put them on a command line (visible in `ps`).

### Useful special variables

| Variable | Meaning |
|----------|---------|
| `$HOME`, `$USER`, `$PWD`, `$OLDPWD` | Your home, user name, current and previous directory |
| `$SHELL` | Your login shell (not necessarily the running one) |
| `$$`, `$!`, `$?` | This shell's PID, last background PID, last exit status |
| `$RANDOM`, `$SECONDS`, `$LINENO` | Random number, seconds since start, current line |
| `$BASH_SOURCE`, `$FUNCNAME` | Script file and function call stack |

## Worked example

Six experiments in one script. Save as `env.sh` and run it in an empty directory.

```bash
#!/usr/bin/env bash
# env.sh - shell variables vs environment variables, PATH, sourcing
set -euo pipefail

echo "--- 1. a plain variable is private; an exported one is inherited by child processes"
secret_name="plain"
export GREETING="hello"
bash -c 'echo "child sees GREETING=${GREETING:-<unset>} secret_name=${secret_name:-<unset>}"'

echo "--- 2. VAR=value cmd sets it for that one command only"
MODE=debug bash -c 'echo "inside: MODE=${MODE:-<unset>}"'
echo "outside: MODE=${MODE:-<unset>}"

echo "--- 3. a subshell cannot change its parent"
( export TEMP_VAR=inside; echo "in subshell: ${TEMP_VAR}" )
echo "after: ${TEMP_VAR:-<unset>}"

echo "--- 4. PATH decides which program runs"
mkdir -p bin
printf '#!/usr/bin/env bash\necho "mytool v1"\n' > bin/mytool
chmod +x bin/mytool
if command -v mytool >/dev/null; then
    echo "mytool is on PATH"
else
    echo "mytool is NOT on PATH yet"
fi
PATH="$PWD/bin:$PATH"                 # prepend, never replace
mytool
type -a mytool | sed "s#$PWD#.#"

echo "--- 5. source runs a file in the CURRENT shell; running it as a script does not"
printf 'export APP_MODE=prod\n' > setup.sh
bash setup.sh
echo "after 'bash setup.sh': APP_MODE=${APP_MODE:-<unset>}"
source ./setup.sh
echo "after 'source setup.sh': APP_MODE=${APP_MODE:-<unset>}"

echo "--- 6. list exported variables that start with APP or GREETING"
env | grep -E '^(APP|GREETING)' | sort
```

**Expected output**

```text
--- 1. a plain variable is private; an exported one is inherited by child processes
child sees GREETING=hello secret_name=<unset>
--- 2. VAR=value cmd sets it for that one command only
inside: MODE=debug
outside: MODE=<unset>
--- 3. a subshell cannot change its parent
in subshell: inside
after: <unset>
--- 4. PATH decides which program runs
mytool is NOT on PATH yet
mytool v1
mytool is ./bin/mytool
--- 5. source runs a file in the CURRENT shell; running it as a script does not
after 'bash setup.sh': APP_MODE=<unset>
after 'source setup.sh': APP_MODE=prod
--- 6. list exported variables that start with APP or GREETING
APP_MODE=prod
GREETING=hello
```

Section 5 is the important one: `bash setup.sh` left `APP_MODE` unset, `source ./setup.sh` set it.
Section 4 shows that `type -a` reports the path you just added.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `DB_HOST=db` then running a program that needs it | Not exported: the child never sees it | `export DB_HOST=db` |
| `PATH="$HOME/bin"` | Replaces the whole `PATH`: `ls: command not found` | `PATH="$HOME/bin:$PATH"` |
| `./setup.sh` to set variables for your shell | A child process cannot modify its parent | `source ./setup.sh` |
| `eval "$(cat config)"` or `source` on untrusted files | Executes whatever the file contains | Parse `KEY=VALUE` lines as data |
| `export PASSWORD=...` in a script that runs `ps`-visible commands | Secrets leak via the environment or arguments | Read from a file with mode `600`; pass via stdin |
| Editing `~/.bashrc` and expecting the open terminal to change | Only new shells read it | `source ~/.bashrc` |
| `export PATH=$PATH:~/bin` in a loop or twice | PATH grows with duplicates | Guard: `case ":$PATH:" in *":$dir:"*) ;; *) PATH="$dir:$PATH";; esac` |

## Exercises

### Easy: who inherits what?

Create one exported and one unexported variable, then show that a child `bash -c` sees only the
exported one. Show the one-shot form `LOG_LEVEL=debug cmd` and that the parent is unchanged. Check
membership of the environment with `printenv NAME`.

**Acceptance criteria**

- The child prints an empty value for the unexported variable.
- After the one-shot command, `LOG_LEVEL` is still empty in the parent.
- `printenv` is used for the final yes/no checks.

### Medium: a private `bin`

In a temp directory create `bin/hello-tool` (executable, prints one line). Show that it is not found,
prepend `bin` to `PATH`, run it, report where `command -v` finds it, then remove the entry from `PATH`
again and confirm it is gone.

**Acceptance criteria**

- Messages in order: not on `PATH`, tool output, found as `.../bin/hello-tool`, removed again.
- The original `PATH` entries are all preserved while the tool is available.
- Nothing outside the temp directory is changed.

### Hard: safe `.env` loader

Write `load_env FILE` that reads `KEY=VALUE` lines without `source` or `eval`. It must ignore blank
lines and `#` comments, strip one pair of surrounding quotes, export the variable, skip lines that
lack an `=` or have an invalid name (spaces, leading digit), and print `KEY=****` instead of the
value for names containing `PASSWORD`, `SECRET`, `TOKEN` or `KEY`. Finish by printing how many were
loaded and prove a child process sees the values.

**Acceptance criteria**

- For the sample file: `APP_NAME`, `APP_PORT`, `DB_PASSWORD` load (the last masked); `BAD NAME`, `1ST`
  and `JUST_TEXT` are skipped with a message on stderr.
- The final line shows `3 variable(s) loaded`.
- The child prints `APP_NAME=[Shop Front] APP_PORT=[8080]`.

### Break it

This script has **three bugs**: the child does not see the variable, the setup script has no effect,
and the script breaks `ls`. Save as `break-it.sh`, run it, and fix it.

```bash
#!/usr/bin/env bash
mkdir -p mybin
printf '#!/bin/sh\necho tool ran\n' > mybin/tool
chmod +x mybin/tool

DB_HOST=db.local
bash -c 'echo "child sees DB_HOST=[${DB_HOST:-}]"'

printf 'export APP_MODE=prod\n' > setup.sh
bash setup.sh
echo "APP_MODE is [${APP_MODE:-}]"

PATH="$PWD/mybin"
tool
ls mybin
```

**Expected output**

```text
child sees DB_HOST=[]
APP_MODE is []
tool ran
break-it.sh: line 15: ls: command not found
```

<details>
<summary>Hint</summary>

Each bug matches one row of the "Common mistakes" table. The last error message names the command
that disappeared.

</details>

## Solutions

<details>
<summary>Easy</summary>

```bash
#!/usr/bin/env bash
# Day 18 easy: which variables does a child process inherit?
set -euo pipefail

not_exported="visible only here"
export exported="visible to children"

bash -c 'echo "child: not_exported=[${not_exported:-}]"'
bash -c 'echo "child: exported=[${exported:-}]"'

echo "--- one-shot assignment"
LOG_LEVEL=debug bash -c 'echo "child: LOG_LEVEL=${LOG_LEVEL}"'
echo "parent: LOG_LEVEL=[${LOG_LEVEL:-}]"

echo "--- is it in the environment?"
if printenv exported >/dev/null; then echo "exported: yes"; else echo "exported: no"; fi
if printenv not_exported >/dev/null; then echo "not_exported: yes"; else echo "not_exported: no"; fi
```

**Expected output**

```text
child: not_exported=[]
child: exported=[visible to children]
--- one-shot assignment
child: LOG_LEVEL=debug
parent: LOG_LEVEL=[]
--- is it in the environment?
exported: yes
not_exported: no
```

</details>

<details>
<summary>Medium</summary>

`${PATH#"${work}/bin:"}` removes the exact prefix we added. The quotes inside make it a literal
string, not a pattern.

```bash
#!/usr/bin/env bash
# Day 18 medium: install a personal tool into a private bin directory and put it on PATH.
# Temporary files only; nothing in your real home or PATH is changed.
set -euo pipefail

work="$(mktemp -d)"
mkdir -p "${work}/bin"
cat > "${work}/bin/hello-tool" <<'EOF'
#!/usr/bin/env bash
echo "hello from my own tool"
EOF
chmod 755 "${work}/bin/hello-tool"

if command -v hello-tool >/dev/null; then
    echo "found already?"
else
    echo "before: hello-tool is not on PATH"
fi

export PATH="${work}/bin:${PATH}"           # prepend, keep the old PATH
hello-tool
echo "after: found as $(command -v hello-tool | sed "s#${work}#WORK#")"

# Remove it again: rebuild PATH without our entry.
PATH="${PATH#"${work}/bin:"}"
if command -v hello-tool >/dev/null; then
    echo "still found"
else
    echo "removed from PATH again"
fi

rm -rf -- "$work"
```

**Expected output**

```text
before: hello-tool is not on PATH
hello from my own tool
after: found as WORK/bin/hello-tool
removed from PATH again
```

</details>

<details>
<summary>Hard</summary>

The `|| [[ -n $line ]]` handles a last line with no newline (Day 14). `export "${key}=${value}"`
assigns without any further expansion of `value`, so a value like `$(rm -rf x)` is just text.

```bash
#!/usr/bin/env bash
# Day 18 hard: load a .env file safely (no eval, no source), and never print secret values.
# Temporary files only.
set -euo pipefail

load_env() {
    local file="$1" line key value loaded=0
    while IFS= read -r line || [[ -n $line ]]; do
        line="${line#"${line%%[![:space:]]*}"}"          # trim leading whitespace
        case "$line" in ''|'#'*) continue ;; esac        # skip blanks and comments
        if [[ $line != *=* ]]; then
            echo "skip (no '='): ${line}" >&2
            continue
        fi
        key="${line%%=*}"
        value="${line#*=}"
        case "$key" in
            ''|[0-9]*|*[!A-Za-z0-9_]*)
                echo "skip (bad name): ${key}" >&2
                continue
                ;;
        esac
        if [[ $value == \"*\" || $value == \'*\' ]]; then
            value="${value:1:${#value}-2}"               # strip one pair of quotes
        fi
        export "${key}=${value}"
        loaded=$(( loaded + 1 ))
        case "$key" in
            *PASSWORD*|*SECRET*|*TOKEN*|*KEY*) echo "loaded ${key}=****" ;;
            *)                                 echo "loaded ${key}=${value}" ;;
        esac
    done < "$file"
    echo "${loaded} variable(s) loaded"
}

work="$(mktemp -d)"
cat > "${work}/app.env" <<'EOF'
# application settings
APP_NAME="Shop Front"
APP_PORT=8080
DB_PASSWORD='s3cr3t value'

BAD NAME=oops
1ST=nope
JUST_TEXT
EOF

load_env "${work}/app.env"
echo "--- the values are really in the environment"
bash -c 'echo "child: APP_NAME=[${APP_NAME}] APP_PORT=[${APP_PORT}]"'
rm -rf -- "$work"
```

**Expected output**

```text
loaded APP_NAME=Shop Front
loaded APP_PORT=8080
loaded DB_PASSWORD=****
skip (bad name): BAD NAME
skip (bad name): 1ST
skip (no '='): JUST_TEXT
3 variable(s) loaded
--- the values are really in the environment
child: APP_NAME=[Shop Front] APP_PORT=[8080]
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `DB_HOST` was never exported. Bug 2: `bash setup.sh` ran in a child, so `APP_MODE` was lost;
`source` runs it in the current shell. Bug 3: `PATH="$PWD/mybin"` replaced the whole path, so `ls`
vanished. The fix is `export`, `source`, and `PATH="$PWD/mybin:$PATH"`.

```bash
#!/usr/bin/env bash
# Fixed: export for children, source for the current shell, and extend PATH instead of replacing it.
set -euo pipefail

mkdir -p mybin
printf '#!/bin/sh\necho tool ran\n' > mybin/tool
chmod +x mybin/tool

export DB_HOST=db.local
bash -c 'echo "child sees DB_HOST=[${DB_HOST:-}]"'

printf 'export APP_MODE=prod\n' > setup.sh
source ./setup.sh
echo "APP_MODE is [${APP_MODE:-}]"

PATH="$PWD/mybin:$PATH"
tool
ls mybin
```

**Expected output**

```text
child sees DB_HOST=[db.local]
APP_MODE is [prod]
tool ran
tool
```

</details>

Solution files live in [`solutions/day-18/`](solutions/day-18/).

## Self-check

1. What does `export` do?
2. Why can't `./setup.sh` change your current directory or variables?
3. How do you add a directory to `PATH` safely?
4. Which command shows every program that matches a name, in `PATH` order?
5. Why avoid `source`-ing a config file you did not write?

<details>
<summary>Answers</summary>

1. It marks the variable to be copied into the environment of child processes.
2. It runs in a child process; children cannot modify their parent.
3. Prepend or append while keeping the old value: `PATH="$dir:$PATH"`.
4. `type -a name`.
5. It would execute arbitrary commands contained in the file.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `export NAME=value` | Create and export |
| `printenv NAME`, `env` | Inspect the environment |
| `NAME=value cmd` | Set for one command |
| `unset NAME` | Remove |
| `source file` / `. file` | Run in the current shell |
| `PATH="$dir:$PATH"` | Prepend to PATH |
| `command -v tool`, `type -a tool` | Which tool will run |
| `${NAME:-default}`, `${NAME:?msg}` | Default / required |
| `~/.bashrc`, `~/.bash_profile` | Per-user shell startup files |

## Further reading

- [Greg's Wiki: DotFiles](https://mywiki.wooledge.org/DotFiles): how to organise `.bashrc` and
  `.bash_profile` sensibly.
- [Greg's Wiki: BashFAQ/033](https://mywiki.wooledge.org/BashFAQ/033): why you cannot set a parent's
  variable from a child, and the usual workarounds.
- [environ(7)](https://man7.org/linux/man-pages/man7/environ.7.html): the manual page describing the
  process environment and the conventional variables.

**Next:** [Day 19](day-19.md)
