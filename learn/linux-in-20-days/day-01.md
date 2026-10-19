# Day 01: What Linux Is, Your Lab, and Your First Commands

> **Time:** ~45 min · **Level:** Beginner
> **Prerequisites:** none

## Goal

By the end of this lesson you can:

- Explain the difference between the kernel, a distribution and the shell, and say which one a given command belongs to.
- Set up a safe place to practise (WSL, a virtual machine or the devcontainer) and open a terminal in it.
- Identify your distribution and package-manager family, and tell a shell builtin from a program on disk.

## Concepts

### Kernel, distribution, shell

- The **kernel** (Linux) talks to hardware and runs processes. You never type to it directly.
- A **distribution** (Ubuntu, Debian, Fedora, Rocky Linux...) bundles the kernel with tools, a package manager and defaults.
- The **shell** (usually `bash`) reads what you type and starts programs. A **terminal** is just the window that shows it.

Distributions come in families, and the family decides which commands you use for packages:

| Family | Examples | Package tool | Package file |
|--------|----------|--------------|--------------|
| Debian | Debian, Ubuntu, Linux Mint | `apt` | `.deb` |
| RHEL | RHEL, Rocky, AlmaLinux, Fedora, CentOS Stream | `dnf` (older: `yum`) | `.rpm` |

This course shows both families wherever commands differ. Everything else (files, permissions, processes) is the same everywhere.

### Where to practise

> [!WARNING]
> From Day 04 onward you will change permissions, users, disks and services. Practise in a
> throwaway environment, never on a machine holding data you cannot lose.

| Option | Best for | Notes |
|--------|----------|-------|
| WSL 2 (Windows) | Windows users, fastest start | `wsl --install -d Ubuntu`; see [Microsoft's guide](https://learn.microsoft.com/en-us/windows/wsl/install) |
| Virtual machine | Days 8, 11, 15-18 (disks, users, services, SSH) | VirtualBox or similar, Ubuntu Server or Rocky Linux ISO, 2 GB RAM, 20 GB disk. Take a snapshot before each risky day |
| Devcontainer | Anyone with Docker and VS Code | Open the repository root; the configuration lives in [`.devcontainer/`](../../.devcontainer/) |
| Cloud VM | Day 17 (real SSH) | Any small instance; delete it afterwards |

Days that need root, a real disk or a real service say so at the top. A VM with a snapshot is the safest choice for those.

### Commands are builtins, aliases or programs

`type` tells you what a name means. This matters because `man cd` and `man ls` look different: one is built into the shell, the other is a file on disk.

```bash
type -t cd
type -t ls
type -t grep
```

`type -t` prints one word: `alias`, `keyword`, `function`, `builtin` or `file`.

### Getting help offline

```bash
help cd | head -n 1       # builtins: help NAME
ls --help | head -n 2     # programs: NAME --help
man ls                    # the manual (q to quit, / to search)
```

## Worked example

Scenario: a colleague asks "what box is this, and which package tool do I use?" You answer without installing anything.

Open a terminal and run each command.

```bash
uname -s
. /etc/os-release && echo "$ID|$ID_LIKE"
echo "$SHELL"
type -t cd
type -t ls
type -t grep
command -v apt dnf
```

**Expected output** (sample from Ubuntu on WSL 2; your distribution line will differ):

```text
Linux
ubuntu|debian
/bin/bash
builtin
file
file
/usr/bin/apt
```

Reading it:

1. `uname -s` names the kernel: `Linux`.
2. `. /etc/os-release` loads the variables in that file into your shell (`.` is `source`). `ID` is this distribution, `ID_LIKE` is its parent family. On Fedora you would see `fedora|` (empty `ID_LIKE`); on Rocky Linux, `rocky|rhel centos fedora`.
3. `command -v` prints the path of each tool that exists. Only `apt` was found, so this is a Debian-family system. On RHEL-family systems you would see `/usr/bin/dnf`.

> [!NOTE]
> In an interactive shell `type -t ls` often prints `alias` because distributions define `alias ls='ls --color=auto'`. A script does not load aliases, so it prints `file`.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| Typing the `$` or `#` prompt shown in tutorials | The prompt is not part of the command | Copy only the command text |
| `Ls` or `LS` instead of `ls` | Linux is case-sensitive | Use lowercase; use Tab to complete |
| Running `man cd` and getting "No manual entry" | `cd` is a shell builtin | Use `help cd` |
| Assuming every box uses `apt` | RHEL-family systems use `dnf` | Check `ID_LIKE` first, or `command -v apt dnf` |
| Practising on your daily machine | Later days change users, disks and services | Use WSL, a VM or the devcontainer |

## Exercises

All exercises are read-only. Reference solutions: [`solutions/day-01/`](solutions/day-01/).

### Easy

Print one line of the form `Distro: <pretty name>` using `/etc/os-release`.

**Acceptance criteria:**

- Output is a single line that starts with `Distro:` followed by a non-empty name.
- You did not hard-code the distribution name.

### Medium

Using `type -t`, write a file `tools.txt` with one `name: kind` line for each of `cd`, `ls`, `if` and `grep`.

**Acceptance criteria:**

- `tools.txt` has exactly 4 lines.
- It contains `cd: builtin` and `if: keyword`.
- If you do it in a script, `ls: file`.

### Hard

Write `sysinfo.sh` that prints `kernel=`, `distro=` and `package_manager=` lines, decides `apt` or `dnf` from `ID` **and** `ID_LIKE`, and exits with status 1 and a message on stderr for any other family. It must accept an `OS_RELEASE=file` override so it can be tested.

**Acceptance criteria:**

- With files containing `ID=debian`, `ID=ubuntu` + `ID_LIKE=debian`, `ID=fedora`, and `ID=rocky` + `ID_LIKE="rhel centos fedora"` it answers apt, apt, dnf, dnf.
- With `ID=arch` it exits non-zero and prints nothing on stdout.
- Variables are quoted; `shellcheck` is clean (see [Bash Day 03](../30-days-of-bash/day-03.md) for quoting and [Day 04](../30-days-of-bash/day-04.md) for tests).

### Break it

Run [`solutions/day-01/break-it.sh`](solutions/day-01/break-it.sh) with `OS_RELEASE` pointing at a file that contains `ID=debian`. It has three bugs. Find and fix them.

**Acceptance criteria:** it prints `apt` for `ID=debian`, `apt` for `ID=ubuntu` + `ID_LIKE=debian`, and `dnf` for `ID=fedora`, with no error messages.

## Solutions

<details>
<summary>Easy</summary>

```bash
. /etc/os-release
echo "Distro: ${PRETTY_NAME}"
```

Full script with a self-check: [`easy.sh`](solutions/day-01/easy.sh).

</details>

<details>
<summary>Medium</summary>

```bash
for name in cd ls if grep; do
  printf '%s: %s\n' "$name" "$(type -t "$name")"
done > tools.txt
```

Full script: [`medium.sh`](solutions/day-01/medium.sh).

</details>

<details>
<summary>Hard</summary>

The key idea is to pad `ID` and `ID_LIKE` with spaces and match whole words in a `case`, so `rhel` does not match `rhelish`:

```bash
case " ${ID} ${ID_LIKE} " in
  *" debian "*|*" ubuntu "*)     pm=apt ;;
  *" rhel "*|*" fedora "*)       pm=dnf ;;
  *) echo "unknown family" >&2; exit 1 ;;
esac
```

Full script with `--self-test`: [`hard.sh`](solutions/day-01/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. `source /etc/os-releas` is a typo, and it ignores `$OS_RELEASE`. Use `. "$OS_RELEASE"`.
2. `[ $ID_LIKE = "debian" ]` is unquoted. When `ID_LIKE` is empty the test becomes `[ = debian ]`, giving `unary operator expected`. Quote it or use `[[ ]]`.
3. Debian itself has no `ID_LIKE=debian`, so the original logic answered `dnf` on Debian. Test `ID` and `ID_LIKE` together.

Fixed script: [`break-it.fixed.sh`](solutions/day-01/break-it.fixed.sh).

</details>

## Self-check

1. Which component starts programs when you press Enter: the kernel, the shell or the terminal?
2. Which file tells you the distribution name, and which variable names its parent family?
3. Why does `man cd` fail but `help cd` work?
4. Which package tool would you expect on Rocky Linux?
5. Why should risky exercises not be done on your daily machine?

<details>
<summary>Answers</summary>

1. The shell. The terminal only displays it; the kernel runs what the shell starts.
2. `/etc/os-release`; `ID_LIKE`.
3. `cd` is a shell builtin, so it has no manual page of its own; `help` documents builtins.
4. `dnf` (with `yum` as a compatibility alias).
5. A mistake with permissions, users, disks or SSH can lock you out or destroy data; a VM snapshot makes it reversible.

</details>

## Cheat sheet

```bash
uname -sr                       # kernel name and release
. /etc/os-release; echo "$ID"   # distribution id
echo "$SHELL"                   # your login shell
type -t NAME                    # alias | keyword | function | builtin | file
command -v NAME                 # path of a program (empty if absent)
help NAME                       # docs for shell builtins
NAME --help                     # quick help for programs
man NAME                        # full manual (q quits, / searches)
```

## Further reading

- [Ubuntu: command line for beginners](https://ubuntu.com/tutorials/command-line-for-beginners): a gentle tour of the terminal with screenshots.
- [os-release(5)](https://www.freedesktop.org/software/systemd/man/latest/os-release.html): every field in `/etc/os-release`, including `ID_LIKE`.
- [Install WSL](https://learn.microsoft.com/en-us/windows/wsl/install): Microsoft's steps for a Linux shell on Windows.

**Next:** [Day 02](day-02.md)
