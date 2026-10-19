# Day 11: Users, Groups and sudo

> **Time:** ~60 min · **Level:** Intermediate
> **Prerequisites:** [Day 10](day-10.md)

## Goal

By the end of this lesson you can:

- Read `/etc/passwd`, `/etc/group` and `id` output, and explain UID, GID, primary and supplementary groups.
- Describe how to create, modify and delete accounts and groups on Debian-family and RHEL-family systems, including the `-aG` rule.
- Grant limited `sudo` rights with a validated drop-in file instead of editing `/etc/sudoers` directly.

## Concepts

### Where accounts live

| File | Holds | Readable by |
|------|-------|-------------|
| `/etc/passwd` | `name:x:UID:GID:comment:home:shell` | everyone |
| `/etc/shadow` | password hashes and ageing | root (and the `shadow` group on Debian) |
| `/etc/group` | `name:x:GID:member,member` | everyone |
| `/etc/sudoers`, `/etc/sudoers.d/*` | who may run what as whom | root |

Conventions: UID 0 is root. System accounts (daemons) are typically below 1000 and use `/usr/sbin/nologin`. People start at 1000 (some older systems at 500). Every file belongs to a UID and a GID; names are only labels looked up in these files.

Use `getent passwd NAME` rather than grepping `/etc/passwd`: it also finds accounts from LDAP or SSSD.

### The commands

| Task | Debian / Ubuntu | RHEL family |
|------|-----------------|-------------|
| Create user (friendly) | `sudo adduser alice` | (not available; use `useradd`) |
| Create user (low level) | `sudo useradd -m -s /bin/bash alice` | `sudo useradd -m alice` (home created by default) |
| Set password | `sudo passwd alice` | `sudo passwd alice` |
| Add to a group | `sudo usermod -aG devs alice` | `sudo usermod -aG devs alice` |
| Create group | `sudo groupadd devs` | `sudo groupadd devs` |
| Lock / unlock | `sudo usermod -L alice` / `-U` | `sudo usermod -L alice` / `-U` |
| Delete user | `sudo deluser --remove-home alice` | `sudo userdel -r alice` |
| Sudo group name | `sudo` | `wheel` |
| Password ageing | `sudo chage -l alice` | `sudo chage -l alice` |

> [!WARNING]
> `usermod -G devs alice` (without `-a`) **replaces** all of alice's supplementary groups. She silently
> loses `sudo`/`wheel`, `docker` and anything else. Always write `-aG`. Group changes take effect at the
> next login (`newgrp` or logging out and in).
> `userdel -r` / `deluser --remove-home` deletes the home directory for good. Take a backup (Day 14) first.

**Undo:** to reverse an `usermod -aG`, use `sudo gpasswd -d alice devs`. To reverse a user deletion you need the backup; the account itself can be recreated but the files cannot.

### sudo: least privilege

`sudo` runs one command as another user (usually root) after checking `sudoers`. Do not add people to the all-powerful group when they need one thing. Put narrow rules in `/etc/sudoers.d/NAME`:

```text
%devs ALL=(root) NOPASSWD: /usr/bin/systemctl restart myapp
```

Read: members of group `devs`, on any host, may run as root exactly that command, without a password. Files in `sudoers.d` must be mode `0440`, and you must validate before relying on them, because a syntax error can disable `sudo` for everyone:

```bash
sudo visudo -cf /etc/sudoers.d/devs     # check only: syntax OK or not
sudo visudo -f /etc/sudoers.d/devs      # edit with validation on save
```

Keep a root shell open (`sudo -s`) in a second terminal while you edit sudoers, so a mistake is recoverable.

## Worked example

Scenario: a new colleague, Alice, needs to restart one service. Before touching a real system, read the account data and check the sudo rule syntax. Everything below is read-only or uses scratch files.

Inspect real data:

```bash
getent passwd root
getent group sudo | cut -d: -f1,3
stat -c '%A %U:%G %n' /etc/passwd /etc/shadow
```

**Expected output** (Debian/Ubuntu; on RHEL `/etc/shadow` is `----------` root:root and the group is `wheel`):

```text
root:x:0:0:root:/root:/bin/bash
sudo:27
-rw-r--r-- root:root /etc/passwd
-rw-r----- root:shadow /etc/shadow
```

Analyse a sample passwd file so the result is predictable:

```bash
cd "$(mktemp -d)"
cat > passwd <<'EOF'
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
alice:x:1000:1000:Alice:/home/alice:/bin/bash
bob:x:1001:1001:Bob:/home/bob:/bin/zsh
mallory:x:0:0:evil:/home/mallory:/bin/bash
twin:x:1001:1002::/home/twin:/bin/sh
EOF
awk -F: '$3 >= 1000 && $3 < 60000 {print $1, $3, $7}' passwd
awk -F: '$3 == 0 {print $1}' passwd
```

**Expected output:**

```text
alice 1000 /bin/bash
bob 1001 /bin/zsh
twin 1001 /bin/sh
root
mallory
```

Two accounts with UID 0 means two superusers. Anything other than `root` there is a red flag. The reference script [`solutions/day-11/hard.sh`](solutions/day-11/hard.sh) automates this audit:

```bash
bash ../path/to/hard.sh passwd /etc/shells
```

**Expected output** (from the sample file above; `/etc/shells` on a typical system lists `/bin/bash` and `/bin/sh` but not `/bin/zsh` unless installed):

```text
UID0: mallory
DUPLICATE-UID: 0 root mallory
DUPLICATE-UID: 1001 bob twin
BAD-SHELL: bob /bin/zsh
```

Validate a sudoers rule without installing it. A good rule and one with a missing colon:

```bash
printf '%%devs ALL=(root) NOPASSWD: /usr/bin/systemctl restart myapp\n' > good
printf '%%devs ALL=(root) NOPASSWD /usr/bin/systemctl restart myapp\n' > bad
visudo -cf good; echo "rc=$?"
visudo -cf bad >/dev/null 2>&1; echo "rc=$?"
```

On Debian/Ubuntu `visudo` is in `/usr/sbin`; use `export PATH=$PATH:/usr/sbin:/sbin` if it is not found.

**Expected output** (the wording of the first line differs between classic `sudo` and `sudo-rs`, which Ubuntu 26.04 uses; the exit codes are what matter):

```text
good: parsed OK
rc=0
rc=1
```

### The real procedure (root; not run while writing this lesson)

Do it in a VM. The commands below are Debian/Ubuntu first, with RHEL differences in comments.

```bash
sudo groupadd devs
sudo useradd -m -s /bin/bash alice            # RHEL: sudo useradd -m alice
sudo passwd alice
sudo usermod -aG devs alice
echo '%devs ALL=(root) NOPASSWD: /usr/bin/systemctl restart myapp' | sudo tee /etc/sudoers.d/devs
sudo chmod 0440 /etc/sudoers.d/devs
sudo visudo -cf /etc/sudoers.d/devs
id alice                                      # verify: groups include devs
sudo -l -U alice                              # verify: lists the allowed command
```

**Undo:**

```bash
sudo rm /etc/sudoers.d/devs
sudo gpasswd -d alice devs
sudo deluser --remove-home alice              # RHEL: sudo userdel -r alice
sudo groupdel devs
```

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `usermod -G devs alice` | Replaces all supplementary groups | `usermod -aG devs alice` |
| New group membership "does not work" | Groups are read at login | Log out and in, or `newgrp devs` |
| Editing `/etc/sudoers` with a plain editor | A syntax error disables sudo | `sudo visudo`, or a validated file in `/etc/sudoers.d` |
| `NOPASSWD: ALL` for convenience | Unrestricted passwordless root | Allow named commands only |
| `sudoers.d` file ignored | Wrong mode, or the name contains a `.` or ends with `~` | `chmod 0440`; name it without dots |
| Grepping `/etc/passwd` for a user | Misses LDAP/SSSD users, matches substrings | `getent passwd NAME` |
| Deleting a user but leaving their files | Files keep the old numeric UID, and a new user may reuse it | `find / -xdev -nouser`, or archive first |

## Exercises

Reference solutions: [`solutions/day-11/`](solutions/day-11/). All are read-only or print commands without running them; the real account changes belong in a VM.

### Easy

Print your own user name, UID, primary group and all groups on one line: `user=... uid=... group=... groups=...`.

**Acceptance criteria:**

- Values come from `id`, not from typing them.
- The primary group appears in the `groups=` list.

### Medium

Write a function or script that lists "human" accounts (UID 1000 to 59999) from a passwd-format file as `NAME UID SHELL`.

**Acceptance criteria:**

- For the sample file it prints `alice 1000 /bin/bash`, `bob 1001 /bin/zsh`, `twin 1001 /bin/sh` (and not root, daemon or `nobody`).
- The file name is a parameter and defaults to `/etc/passwd`.

### Hard

Write `userreport.sh [PASSWD [SHELLS]]` that prints `UID0: NAME` for extra UID-0 accounts, `DUPLICATE-UID: UID NAMES` for shared UIDs, and `BAD-SHELL: NAME SHELL` for login shells not listed in the shells file (ignore `nologin` and `false`).

**Acceptance criteria:**

- The sample file above gives exactly the four lines shown in the worked example.
- An unreadable input file gives an error and a non-zero status.
- It never writes any file.

### Break it

[`solutions/day-11/break-it.sh`](solutions/day-11/break-it.sh) prints the commands to create a user, add them to an existing group and let them restart one service. It executes nothing, but the plan has three dangerous mistakes.

**Acceptance criteria:** the corrected plan uses `usermod -aG`, grants one specific command (not `ALL`), sets mode `0440` and validates with `visudo -cf`, and contains no `777`.

## Solutions

<details>
<summary>Easy</summary>

```bash
echo "user=$(id -un) uid=$(id -u) group=$(id -gn) groups=$(id -Gn)"
```

Script: [`easy.sh`](solutions/day-11/easy.sh).

</details>

<details>
<summary>Medium</summary>

```bash
awk -F: '$3 >= 1000 && $3 < 60000 {print $1, $3, $7}' "${1:-/etc/passwd}"
```

Script: [`medium.sh`](solutions/day-11/medium.sh).

</details>

<details>
<summary>Hard</summary>

Three awk passes: UID 0 other than root; an array that collects names per UID and prints those with a count above 1; and a two-file pass (`NR == FNR`) that loads valid shells from the first file and checks field 7 of the second.

```bash
awk -F: 'NR == FNR { if ($0 !~ /^#/ && $0 != "") ok[$0] = 1; next }
         $7 != "" && !($7 in ok) && $7 !~ /(nologin|false)$/ {print "BAD-SHELL: " $1 " " $7}' \
    "$shells" "$passwd"
```

Script with `--self-test`: [`hard.sh`](solutions/day-11/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. `usermod -G` replaces groups; use `-aG`.
2. `NOPASSWD: ALL` is unrestricted root. Allow `/usr/bin/systemctl restart myapp` only, `chmod 0440` the file and run `visudo -cf` on it.
3. `chmod 777 /home/alice` exposes the home directory to everyone. Use `750` (or `700`).

Fixed script: [`break-it.fixed.sh`](solutions/day-11/break-it.fixed.sh).

</details>

## Self-check

1. What is the difference between a primary and a supplementary group?
2. Why must you use `-a` with `usermod -G`?
3. Which command checks a sudoers file without installing it?
4. Why is `getent passwd` better than `grep NAME /etc/passwd`?
5. What name does the administrators' group have on Ubuntu, and on Rocky Linux?

<details>
<summary>Answers</summary>

1. The primary group (GID in `/etc/passwd`) owns files the user creates; supplementary groups grant additional access.
2. Without `-a`, the listed groups replace all existing ones.
3. `visudo -cf FILE`.
4. It queries every configured source (including LDAP/SSSD) and matches exact names.
5. `sudo` on Ubuntu; `wheel` on Rocky.

</details>

## Cheat sheet

```bash
id; id alice; groups alice            # who is who
getent passwd NAME; getent group NAME
sudo useradd -m -s /bin/bash NAME     # create (Debian: adduser NAME)
sudo usermod -aG GROUP NAME           # add to group  (never -G alone)
sudo passwd NAME; sudo chage -l NAME
sudo usermod -L NAME                  # lock
sudo deluser --remove-home NAME       # Debian;  RHEL: sudo userdel -r NAME
sudo visudo -cf /etc/sudoers.d/NAME   # validate
sudo -l                               # what may I run?
```

## Further reading

- [passwd(5)](https://man7.org/linux/man-pages/man5/passwd.5.html): the exact format of every `/etc/passwd` field.
- [Ubuntu Server: user management](https://ubuntu.com/server/docs/user-management): Debian-family account tasks with examples.
- [RHEL: managing users and groups](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_basic_system_settings/managing-users-and-groups_configuring-basic-system-settings): Red Hat's official procedures.
- [sudoers manual](https://www.sudo.ws/docs/man/sudoers.man/): the complete rule syntax, including `Cmnd_Alias` and `NOPASSWD`.

**Next:** [Day 12](day-12.md)
