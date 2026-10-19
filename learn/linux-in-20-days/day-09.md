# Day 09: Package Management (APT and DNF)

> **Time:** ~60 min · **Level:** Beginner
> **Prerequisites:** [Day 08](day-08.md)

## Goal

By the end of this lesson you can:

- Search, inspect, install, remove and upgrade software with `apt` (Debian/Ubuntu) or `dnf` (RHEL family), and say what each command changes.
- Find which package owns a file and which files a package installed.
- Preview an install without root (`apt-get -s`) and download a package without installing it.

## Concepts

A **package** is an archive (`.deb` or `.rpm`) with files plus metadata: name, version, dependencies and install/remove scripts. A **repository** is a signed catalogue of packages. The package manager resolves dependencies, verifies signatures, unpacks files and records what it did in a database.

| Task | Debian / Ubuntu | RHEL / Fedora / Rocky / Alma |
|------|-----------------|------------------------------|
| Refresh the catalogue | `sudo apt update` | automatic with most commands; `sudo dnf makecache` |
| Upgrade everything | `sudo apt upgrade` | `sudo dnf upgrade` |
| Search | `apt search WORD` | `dnf search WORD` |
| Show details | `apt show PKG` | `dnf info PKG` |
| Install | `sudo apt install PKG` | `sudo dnf install PKG` |
| Remove | `sudo apt remove PKG` | `sudo dnf remove PKG` |
| Remove + config | `sudo apt purge PKG` | (config files are handled by the RPM itself) |
| Remove unused dependencies | `sudo apt autoremove` | `sudo dnf autoremove` |
| List installed | `apt list --installed` / `dpkg -l` | `dnf list installed` / `rpm -qa` |
| Which package owns a file | `dpkg -S /path` | `rpm -qf /path` |
| Files in a package | `dpkg -L PKG` | `rpm -ql PKG` |
| Installed version | `dpkg-query -W PKG` | `rpm -q PKG` |
| Install a local file | `sudo apt install ./file.deb` | `sudo dnf install ./file.rpm` |
| Download only | `apt download PKG` | `dnf download PKG` |
| Past transactions | `/var/log/apt/history.log` | `dnf history` (and `dnf history undo N`) |

`yum` still works on RHEL-family systems as an alias for `dnf`. Use `apt`, not `apt-get`, interactively; scripts often use `apt-get` because its output format is stable.

Installing, removing and upgrading need root and write to the system. Querying does not, and neither does simulating.

> [!WARNING]
> Package commands change the whole system. Run `sudo apt remove` or `sudo dnf remove` only after reading
> the list of **additional** packages it wants to remove: removing one library can remove a desktop or
> `sudo` itself. Do not add third-party repositories or pipe a download into `sudo bash` unless you trust
> the source, and never answer "yes" to a removal list you have not read.

**Undo:** `sudo apt install PKG` re-installs what you removed; on RHEL, `sudo dnf history undo last` reverses the last transaction. On Debian/Ubuntu `purge` deletes configuration, so copy `/etc/PKG*` first.

## Worked example

Scenario: you are asked to install `tree` on a server. First find out what it is, what it would pull in and what it contains, without changing anything. Commands below are for Debian/Ubuntu; the RHEL equivalents are in the table above (they were not run for this lesson).

Which package owns the `grep` program, and what is the installed version of `bash`?

```bash
dpkg -S "$(command -v grep)"
dpkg-query -W -f='${Package} ${Version}\n' bash
```

**Expected output** (versions differ on your system):

```text
grep: /usr/bin/grep
bash 5.3-2ubuntu1
```

What does the catalogue say about `tree`?

```bash
apt-cache policy tree | sed -n '1,3p'
```

**Expected output:**

```text
tree:
  Installed: (none)
  Candidate: 2.3.1-1
```

`Candidate` is the version `apt install tree` would install. A catalogue that has never been refreshed (`apt update` as root) may show an older candidate or none.

Simulate the installation. `-s` means "simulate": it needs no root and changes nothing:

```bash
apt-get -s install tree | grep -E '^(Inst|[0-9]+ upgraded)'
```

**Expected output:**

```text
0 upgraded, 1 newly installed, 0 to remove and 17 not upgraded.
Inst tree (2.3.1-1 Ubuntu:26.04/resolute [amd64])
```

`0 to remove` is the line to read before any real install or removal. Finally, download the package without installing it and look inside:

```bash
cd "$(mktemp -d)"
apt download tree
dpkg-deb -I tree_*.deb | grep -E '^ (Package|Version|Depends)'
```

**Expected output** (the `Get:` line shows your mirror):

```text
Get:1 http://archive.ubuntu.com/ubuntu resolute/universe amd64 tree amd64 2.3.1-1 [53.5 kB]
Fetched 53.5 kB in 1s (64.7 kB/s)
 Package: tree
 Version: 2.3.1-1
 Depends: libc6 (>= 2.38)
```

To really install it you would now run `sudo apt update && sudo apt install tree` (or `sudo dnf install tree`), then verify with `tree --version` and remove with `sudo apt remove tree`.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `E: Unable to locate package` | Stale or missing catalogue, or a typo | `sudo apt update`; `apt search WORD` |
| `E: Could not get lock /var/lib/dpkg/lock` | Another apt (or an unattended upgrade) is running | Wait; check `ps aux \| grep apt`. Do **not** delete lock files |
| `apt install` in a script hangs on a prompt | Interactive confirmation | `sudo apt-get install -y PKG` (and `DEBIAN_FRONTEND=noninteractive`) |
| `dpkg -S /bin/ls` finds nothing | `/bin` is a symlink to `/usr/bin` on modern systems | `dpkg -S "$(readlink -f "$(command -v ls)")"` |
| `dpkg -l \| grep bash` shows many unrelated packages | `grep` matches substrings | `dpkg-query -W bash` or `apt list --installed bash` |
| `apt upgrade` leaves "kept back" packages | New dependencies are needed | read why; `sudo apt full-upgrade` after reviewing |
| Mixing `apt` with a downloaded `.deb` via `dpkg -i` | Dependencies are not resolved | `sudo apt install ./file.deb` |

## Exercises

Reference solutions: [`solutions/day-09/`](solutions/day-09/). Everything is read-only, so no root is needed. Scripts try `dpkg` first and fall back to `rpm`/`dnf`; the RHEL branches were not run by the author.

### Easy

Print the installed version of `bash` from the package database (not from `bash --version`).

**Acceptance criteria:**

- The line has the form `bash VERSION`.
- It works on a Debian-family system via `dpkg-query`, and on RHEL via `rpm -q --qf`.

### Medium

Print which package owns the `grep` program, resolving symlinks first.

**Acceptance criteria:**

- The output contains `owned by package: grep`.
- It uses `readlink -f` so `/bin` versus `/usr/bin` does not matter.

### Hard

Write `pkginfo.sh NAME` that reports whether a package is installed, the available (candidate) version, and, if not installed, what installing it would do, without installing anything.

**Acceptance criteria:**

- Exit status 0 if installed, 1 if not installed, 2 if the package does not exist.
- For an uninstalled package it prints the simulated `Inst` lines.
- It never uses `sudo`.

### Break it

[`solutions/day-09/break-it.sh`](solutions/day-09/break-it.sh) should report whether a package is installed and its version, but it prints noise and the wrong version text. It has three bugs.

**Acceptance criteria:** `bash break-it.fixed.sh bash` prints `bash is installed, version 5...`; `no-such-package-xyz` prints `... is not installed` with no other output; a partial name such as `bash-complet` is reported as not installed.

## Solutions

<details>
<summary>Easy</summary>

```bash
dpkg-query -W -f='${Version}' bash        # Debian family
rpm -q --qf '%{VERSION}-%{RELEASE}' bash  # RHEL family
```

Script: [`easy.sh`](solutions/day-09/easy.sh).

</details>

<details>
<summary>Medium</summary>

```bash
path=$(readlink -f -- "$(command -v grep)")
dpkg -S "$path" | cut -d: -f1          # or: rpm -qf --qf '%{NAME}' "$path"
```

Script: [`medium.sh`](solutions/day-09/medium.sh).

</details>

<details>
<summary>Hard</summary>

```bash
candidate=$(apt-cache policy "$name" | awk '/Candidate:/ {print $2}')
dpkg-query -W -f='${Status}' "$name" | grep -q '^install ok installed'
apt-get -s install "$name" | grep '^Inst '
```

An unknown package has no candidate (or `(none)`), which maps to exit 2. Script with `--self-test`: [`hard.sh`](solutions/day-09/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. `dpkg -l | grep $pkg` matches every package containing the text and prints it. Query the exact name with `dpkg-query -W -f='${Status}'`.
2. `cut -d' ' -f1` returns `Version:`; the number is field 2. `dpkg-query -W -f='${Version}'` avoids parsing entirely.
3. `$pkg` is unquoted, and `dpkg -s` writes errors for missing packages; redirect stderr and test the status string.

Fixed script: [`break-it.fixed.sh`](solutions/day-09/break-it.fixed.sh).

</details>

## Self-check

1. What is the difference between `apt remove` and `apt purge`?
2. How do you find which package provided `/usr/bin/grep`?
3. What does `apt-get -s install PKG` do, and does it need root?
4. Why does `apt install` fail with "Unable to locate package" on a fresh VM?
5. What reverses the last `dnf` transaction?

<details>
<summary>Answers</summary>

1. `remove` keeps configuration files; `purge` deletes them too.
2. `dpkg -S /usr/bin/grep` (Debian) or `rpm -qf /usr/bin/grep` (RHEL).
3. It simulates the install and prints what would happen; it needs no root because it changes nothing.
4. The package lists have not been downloaded yet; run `sudo apt update`.
5. `sudo dnf history undo last`.

</details>

## Cheat sheet

```bash
sudo apt update && sudo apt upgrade          # Debian/Ubuntu: refresh + upgrade
sudo apt install PKG;  sudo apt remove PKG
apt search WORD;  apt show PKG;  apt-cache policy PKG
dpkg -S /path;  dpkg -L PKG;  dpkg-query -W PKG
apt-get -s install PKG                       # simulate, no root
sudo dnf upgrade;  sudo dnf install PKG;  sudo dnf remove PKG
dnf search WORD;  dnf info PKG;  rpm -qf /path;  rpm -ql PKG
sudo dnf history undo last
```

## Further reading

- [Ubuntu Server: package management](https://ubuntu.com/server/docs/package-management): how `apt`, `dpkg`, repositories and unattended upgrades fit together.
- [Debian reference: package management](https://www.debian.org/doc/manuals/debian-reference/ch02.en.html): the long-form guide to `apt` and `dpkg`, including pinning.
- [DNF command reference](https://dnf.readthedocs.io/en/latest/command_ref.html): every `dnf` subcommand and option.
- [RHEL: managing software with DNF](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/managing_software_with_the_dnf_tool/index): Red Hat's official walkthrough.

**Next:** [Day 10](day-10.md)
