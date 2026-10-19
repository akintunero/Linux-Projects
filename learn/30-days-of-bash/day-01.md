# Day 01: Introduction to Bash and Setting Up

> **Time:** ~45 min Â· **Level:** Beginner
> **Prerequisites:** none

## Goal

By the end of this lesson you can:

- Open a Bash terminal on Linux, macOS or Windows (WSL) and check which Bash version you have.
- Write a script with a shebang, make it executable and run it two different ways.
- Explain the difference between a shell, a terminal and a script.

## Concepts

### Terminal, shell, Bash

A **terminal** is the window you type into. A **shell** is the program inside it that reads your
commands and runs them. **Bash** (Bourne Again SHell) is the most common shell on Linux. A
**script** is a text file of commands that Bash runs top to bottom.

### Set up your environment

- **Linux:** open any terminal. Bash is almost certainly installed.
- **macOS:** the built-in Bash is 3.2 (too old for later lessons). Install a current one with
  `brew install bash`.
- **Windows:** install WSL (Windows Subsystem for Linux) by running `wsl --install -d Ubuntu` in
  PowerShell, then open "Ubuntu" from the Start menu.

Check that Bash works and which version you have:

```bash
echo "$BASH_VERSION"
```

Every lesson assumes **Bash 4.4 or newer**. You should see something like `5.2.21(1)-release`.

Create a practice directory. Every lesson works inside it so nothing touches your real files:

```bash
mkdir -p ~/bash-lab
cd ~/bash-lab
```

### Your first command

```bash
echo "Hello from the shell"
```

`echo` prints its arguments. The quotes keep the text together as one argument.

### Your first script

Create a file named `hello.sh` with any editor (`nano hello.sh` is the friendliest). The first line,
`#!/usr/bin/env bash`, is the **shebang**. It tells the system which program should run the file.
Lines starting with `#` are comments. A variable is set with `name=value`, with **no spaces
around `=`**, and read with `$name`.

### Two ways to run a script

```bash
bash hello.sh        # 1. hand the file to bash directly
chmod +x hello.sh    # 2. mark it executable (only needed once)...
./hello.sh           #    ...then run it by path; the shebang picks the interpreter
```

`./` is needed because the current directory is not on your `PATH` (Day 18 explains why that is a
good thing).

## Worked example

Save this as `hello.sh` in `~/bash-lab`, then run it with `bash hello.sh`:

```bash
#!/usr/bin/env bash
# hello.sh - my first script
name="World"
echo "Hello, $name!"
echo "You are running Bash major version ${BASH_VERSINFO[0]}"
echo "This script was started as: $0"
```

**Expected output**

```text
Hello, World!
You are running Bash major version 5
This script was started as: hello.sh
```

`$0` is the name the script was started with. `${BASH_VERSINFO[0]}` is the major version number,
taken from an array that Bash fills in for you (arrays arrive on Day 9). Your version number will
likely differ from the output above.

Now make it executable and run it by path:

```bash
chmod +x hello.sh
./hello.sh
```

The output is the same except that `$0` now shows `./hello.sh`.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `name = "Ada"` | With spaces, Bash runs a command called `name` with arguments `=` and `Ada` | `name="Ada"` |
| `./hello.sh` gives "Permission denied" | The file is not executable | `chmod +x hello.sh` |
| `hello.sh` gives "command not found" | The current directory is not in `PATH` | Run `./hello.sh` |
| `bad interpreter: No such file or directory` | The file has Windows (CRLF) line endings | Convert with `sed -i 's/\r$//' hello.sh` |
| Smart quotes `â€œ â€` copied from a web page | Bash only understands plain `"` and `'` | Retype the quotes |

## Exercises

All exercises: write the script in `~/bash-lab`, use the shebang above, and run it with
`bash script.sh`.

### Easy: who am I

Write `whoami-report.sh` that prints three lines: `User:`, `Shell:` and `Bash:` followed by the
current user name, your login shell (`$SHELL`) and the Bash version as `major.minor`.

**Acceptance criteria**

- Prints exactly three lines starting with `User:`, `Shell:` and `Bash:`.
- Uses variables, not hard-coded values.
- Exits with status 0 (check with `echo $?`).

### Medium: version gate

Write `require-bash.sh` that exits with status 1 and prints a message to standard error if Bash is
older than 4.4. Otherwise it prints that the version is new enough. Hint: `BASH_VERSINFO[0]` and
`BASH_VERSINFO[1]` hold major and minor, and `(( ... ))` does arithmetic.

**Acceptance criteria**

- On your machine it prints a "new enough" message and `echo $?` shows `0`.
- The error message goes to stderr (`>&2`), not stdout.
- To test the failing path, temporarily change `4.4` to `99.0` and confirm the exit status is `1`.

### Hard: environment check

Write `setup-check.sh` that checks whether `bash`, `git`, `awk`, `sed` and `grep` are installed
and prints a two-column table of `TOOL` and `STATUS` (`OK` or `MISSING`). Use `command -v` to test
for each tool and a `for` loop over a list (an array) of names. Exit with status 1 if anything is
missing and print how many were missing.

**Acceptance criteria**

- One row per tool, columns aligned (use `printf '%-8s %s\n'`).
- Exit status 0 when all are present, 1 otherwise.
- Add a sixth tool called `definitely-not-installed` to the list: the script must report it as
  `MISSING` and exit with status 1.

### Break it

This script has **two bugs**. Save it as `break-it.sh`, run it and find them.

```bash
#!/usr/bin/env bash
greeting = "Hello"
name="Ada"
echo "$greeting, $nam!"
```

**Expected output**

```text
break-it.sh: line 2: greeting: command not found
, !
```

<details>
<summary>Hint</summary>

Read the error message first: which line does Bash complain about, and what did it try to run? Then
look at what was printed after the comma.

</details>

## Solutions

<details>
<summary>Easy</summary>

`${USER:-$(id -un)}` means "use `$USER`, or the output of `id -un` if it is empty". We meet this
form properly on Day 10.

```bash
#!/usr/bin/env bash
# Day 01 easy: print a short "who am I" report.
user="${USER:-$(id -un)}"
echo "User:  $user"
echo "Shell: ${SHELL:-unknown}"
echo "Bash:  ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
```

**Expected output**

```text
User:  student
Shell: /bin/bash
Bash:  5.3
```

</details>

<details>
<summary>Medium</summary>

`(( ... ))` is arithmetic evaluation, so `<` compares numbers rather than strings. The `>&2` sends
the message to standard error.

```bash
#!/usr/bin/env bash
# Day 01 medium: refuse to continue on a Bash older than 4.4.
major="${BASH_VERSINFO[0]}"
minor="${BASH_VERSINFO[1]}"

if (( major < 4 || (major == 4 && minor < 4) )); then
    echo "Need Bash 4.4 or newer, found ${major}.${minor}" >&2
    exit 1
fi
echo "Bash ${major}.${minor} is new enough."
```

**Expected output**

```text
Bash 5.3 is new enough.
```

</details>

<details>
<summary>Hard</summary>

`command -v` prints the path of a command and returns non-zero if it does not exist. We hide its
output with `>/dev/null 2>&1` because we only care about the exit status.

```bash
#!/usr/bin/env bash
# Day 01 hard: environment check. Exit 0 if every tool is present, 1 otherwise.
tools=(bash git awk sed grep)
missing=0

printf '%-8s %s\n' "TOOL" "STATUS"
for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf '%-8s %s\n' "$tool" "OK"
    else
        printf '%-8s %s\n' "$tool" "MISSING"
        missing=$((missing + 1))
    fi
done

if (( missing > 0 )); then
    echo "$missing tool(s) missing" >&2
    exit 1
fi
echo "All tools present."
```

**Expected output**

```text
TOOL     STATUS
bash     OK
git      OK
awk      OK
sed      OK
grep     OK
All tools present.
```

</details>

<details>
<summary>Break it</summary>

Bug 1: `greeting = "Hello"` has spaces around `=`, so Bash tried to run a command named `greeting`.
Bug 2: `$nam` is a typo for `$name`. Bash silently treats an unset variable as empty, which is why
nothing warned you. Day 3 shows how to make that an error.

```bash
#!/usr/bin/env bash
# Fixed: no spaces around "=", and the variable name is spelled correctly.
greeting="Hello"
name="Ada"
echo "$greeting, $name!"
```

**Expected output**

```text
Hello, Ada!
```

</details>

Solution files live in [`solutions/day-01/`](solutions/day-01/).

## Self-check

1. What is the difference between a terminal and a shell?
2. What does the first line `#!/usr/bin/env bash` do?
3. Why does `./hello.sh` need the `./`?
4. Why is `x = 5` wrong in Bash?
5. Which two commands let you run a script that is not yet executable and then make it executable?

<details>
<summary>Answers</summary>

1. The terminal is the window; the shell is the program inside it that interprets commands.
2. It tells the operating system to run the file with whatever `bash` is first on your `PATH`.
3. The current directory is not on `PATH`, so you must give a path to the file.
4. Bash would run a command named `x` with arguments `=` and `5`. Assignments allow no spaces.
5. `bash script.sh` runs it without the executable bit; `chmod +x script.sh` sets the bit.

</details>

## Cheat sheet

| Syntax | Meaning |
|--------|---------|
| `#!/usr/bin/env bash` | Shebang: choose the interpreter |
| `# text` | Comment |
| `name="value"` | Assign a variable (no spaces around `=`) |
| `"$name"` | Read a variable (always quote it) |
| `echo "text"` | Print text |
| `bash file.sh` | Run a script with Bash |
| `chmod +x file.sh` | Make a script executable |
| `./file.sh` | Run an executable script by path |
| `command -v tool` | Test whether a tool exists |
| `$BASH_VERSION` | Your Bash version |

## Further reading

- [Greg's Wiki: BashGuide](https://mywiki.wooledge.org/BashGuide): a careful beginner guide you can
  keep using for the whole course.
- [Install WSL (Microsoft)](https://learn.microsoft.com/en-us/windows/wsl/install): step-by-step
  WSL setup on Windows.

**Next:** [Day 02](day-02.md)
