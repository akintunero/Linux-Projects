# Day 04: Permissions, Ownership and umask

> **Time:** ~60 min · **Level:** Beginner
> **Prerequisites:** [Day 03](day-03.md)

## Goal

By the end of this lesson you can:

- Read `-rwxr-x---` and translate it to octal (`750`) and back.
- Change modes with `chmod` in symbolic and numeric form, and explain why directories need the `x` bit.
- Use `umask`, the setgid bit on a shared directory, and `chown`/`chgrp`, knowing which need root.

## Concepts

### Three classes, three bits

Every file has an owner, a group and "others". Each class has read (`r`=4), write (`w`=2) and execute (`x`=1).

```text
-rwxr-x---     type=-  owner=rwx(7)  group=r-x(5)  others=---(0)   => 750
```

| Bit | On a file | On a directory |
|-----|-----------|----------------|
| `r` | read contents | list names (`ls`) |
| `w` | change contents | create, delete, rename entries inside (needs `x` too) |
| `x` | run as a program | enter it (`cd`) and reach files by name |

Deleting a file is a permission on the **directory**, not the file.

### chmod

```bash
chmod u+x script.sh       # symbolic: user, group, other, all (u g o a) + - =
chmod go-rwx secret.txt   # remove everything from group and others
chmod 640 report.txt      # numeric: owner rw-, group r--, others ---
```

### chown and chgrp need root to give things away

```bash
sudo chown alice:devs file    # change owner and group (root only)
chgrp devs file               # you may change to a group you belong to
```

A normal user can only change the group of their own files, and only to a group they are a member of.

### umask: the default you subtract

New files start from 666 and new directories from 777; the `umask` bits are removed. `umask 022` gives files `644` and directories `755`. `umask 077` gives `600` and `700`.

### Special bits

| Bit | Octal | On a directory | Seen as |
|-----|-------|----------------|---------|
| setuid | 4000 | (ignored) on a program: run as the file's owner (like `passwd`) | `s` in owner `x` |
| setgid | 2000 | new files inherit the directory's group | `s` in group `x` |
| sticky | 1000 | only the owner can delete their files, as in `/tmp` | `t` at the end |

## Worked example

Scenario: you have a script that will not run, then a directory that behaves strangely.

```bash
cd "$(mktemp -d)"
printf '#!/bin/sh\necho hi\n' > run.sh
stat -c '%A %a %n' run.sh
./run.sh; echo "rc=$?"
```

**Expected output** (the error line goes to stderr and its wording depends on your shell):

```text
-rw-r--r-- 644 run.sh
rc=126
```

and an error such as `Permission denied`. Exit status 126 means "found but not executable". Fix it:

```bash
chmod +x run.sh
./run.sh
stat -c '%A %a %n' run.sh
```

**Expected output:**

```text
hi
-rwxr-xr-x 755 run.sh
```

Now the directory bits. Without `x`, a directory lets you see names but not touch what is inside:

```bash
mkdir d; echo x > d/f
chmod 600 d
ls d
cat d/f; echo "rc=$?"
```

**Expected output** (the error wording varies):

```text
f
rc=1
```

`ls` works (it has `r`) but `cat d/f` fails with `Permission denied` (no `x`). Flip it: with only `x`, you can reach a file if you know its name, but you cannot list.

```bash
chmod 100 d
ls d; echo "rc=$?"
cat d/f
chmod 755 d
```

**Expected output:**

```text
rc=2
x
```

(`ls` prints an error to stderr, then `cat` succeeds.) The last `chmod 755 d` restores normal access; always undo experiments like this.

Next, see `umask` in action. Parentheses run the commands in a subshell so your own umask is unchanged:

```bash
(umask 022; touch a; mkdir ad; stat -c '%a %n' a ad)
(umask 077; touch b; mkdir bd; stat -c '%a %n' b bd)
```

**Expected output:**

```text
644 a
755 ad
600 b
700 bd
```

Finally, a team directory. Setgid makes everything created inside inherit the directory's group, so collaborators can share files:

```bash
mkdir shared
chmod 2770 shared
stat -c '%A %a' shared
stat -c '%A' /tmp
```

**Expected output:**

```text
drwxrws--- 2770
drwxrwxrwt
```

The `s` is setgid; the `t` on `/tmp` is the sticky bit.

> [!WARNING]
> Never "fix" a permission error with `chmod 777` or `chmod -R 777`. It makes every file writable by every
> user and every compromised service. Find which class needs which bit and grant exactly that.
> `chmod -R` also hits directories; see the table below.

**Undo:** `chmod` has no undo. Before a recursive change, record the old modes: `find . -printf '%m %p\n' > /tmp/modes.txt` and restore from that list.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `chmod -R 644 dir` | Removes `x` from directories, so nothing inside is reachable | `find dir -type d -exec chmod 755 {} +` and `find dir -type f -exec chmod 644 {} +` |
| `chmod 777` to "make it work" | World-writable; a security hole | Work out the owner/group and grant minimum bits |
| `./script.sh` says "Permission denied" | No `x` bit | `chmod u+x script.sh` (or run `bash script.sh`) |
| `chown alice file` as a normal user | Only root can give files away | `sudo chown ...` |
| Can't delete a file you can write to | Deleting needs `w` and `x` on the *directory* | Fix the directory mode |
| Setting `umask 000` in a script | New files become world-writable | Use `022` (or `077` for private data) |

## Exercises

Reference solutions: [`solutions/day-04/`](solutions/day-04/). The exercises use a scratch directory, so no root is needed.

### Easy

Create `report.txt` and set its mode to exactly `640`.

**Acceptance criteria:**

- `stat -c %a report.txt` prints `640`.
- `stat -c %A report.txt` prints `-rw-r-----`.

### Medium

Create a directory `shared` for a team: setgid, owner and group full access, others none (`2770`). With `umask 007`, create a file and a subdirectory inside it.

**Acceptance criteria:**

- `stat -c %A shared` prints `drwxrws---`.
- The new file has mode `660` and the same group as `shared`.
- The new subdirectory also has the setgid bit.

### Hard

Write `permaudit.sh DIR` that reports world-writable files, world-writable directories **without** the sticky bit, and setuid/setgid files. Each finding is one line starting with its category.

**Acceptance criteria:**

- A tree containing a `666` file, a `777` directory, a `1777` directory, a `4755` file and a normal `644` file reports exactly the first, second and fourth, and not the sticky directory or the normal file.
- It never modifies anything, and a non-directory argument gives an error and non-zero exit status.

### Break it

Run [`solutions/day-04/break-it.sh`](solutions/day-04/break-it.sh) in an empty directory. It publishes a `site/` folder but ends with permission errors. There are three bugs.

**Acceptance criteria:** `site/bin/deploy.sh` runs and prints `deploy`; `ls site/css` works; directories are `755`, regular files `644` (the script `755`), and nothing is world-writable.

## Solutions

<details>
<summary>Easy</summary>

```bash
echo "Q3 numbers" > report.txt
chmod 640 report.txt
```

`6`=rw- for the owner, `4`=r-- for the group, `0` for others. Script: [`easy.sh`](solutions/day-04/easy.sh).

</details>

<details>
<summary>Medium</summary>

```bash
mkdir shared
chmod 2770 shared
( umask 007; touch shared/notes.txt; mkdir shared/sub )
```

Files start at 666 minus 007 = 660; directories start at 777 minus 007 = 770, plus setgid inherited from `shared`. Script: [`medium.sh`](solutions/day-04/medium.sh).

</details>

<details>
<summary>Hard</summary>

```bash
find "$dir" -type f -perm -0002 -printf 'world-writable file: %p\n'
find "$dir" -type d -perm -0002 ! -perm -1000 -printf 'world-writable dir without sticky bit: %p\n'
find "$dir" -type f \( -perm -4000 -o -perm -2000 \) -printf 'setuid/setgid file: %p\n'
```

`-perm -MODE` means "all of these bits are set". Script with `--self-test`: [`hard.sh`](solutions/day-04/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. `umask 000` makes new files `666` and directories `777`. Use `umask 022`.
2. `chmod -R 644 site` strips `x` from directories, so `site/css` cannot be entered.
3. The same command removes `x` from `deploy.sh`. Set directories and files separately with `find -type d` / `-type f`, then `chmod 755` the script.

Fixed script: [`break-it.fixed.sh`](solutions/day-04/break-it.fixed.sh).

</details>

## Self-check

1. What octal mode is `rwxr-x---`?
2. Why does a directory need `x` as well as `r` to be useful?
3. A new file is created under `umask 027`. What mode does it get?
4. What does the `t` in `drwxrwxrwt` mean?
5. Who can run `chown` to give a file to another user?

<details>
<summary>Answers</summary>

1. `750`.
2. `r` lists names; `x` is needed to enter the directory and open anything inside by name.
3. `640` (666 minus 027).
4. The sticky bit: only a file's owner (or root) can delete or rename it in that directory.
5. Only root.

</details>

## Cheat sheet

```bash
ls -l; stat -c '%A %a %U:%G %n' F   # view mode and owner
chmod u+x F; chmod go-rwx F         # symbolic
chmod 640 F; chmod 755 D            # numeric
chmod 2770 D                        # setgid directory
chown USER:GROUP F                  # root only
chgrp GROUP F                       # to a group you belong to
umask; umask 027                    # show / set default mask
find . -type f -perm -0002          # world-writable files
find . -type d -exec chmod 755 {} + # change only directories
```

## Further reading

- [credentials(7)](https://man7.org/linux/man-pages/man7/credentials.7.html): how the kernel decides who a process is, including setuid and groups.
- [inode(7)](https://man7.org/linux/man-pages/man7/inode.7.html): the exact meaning of each mode bit.
- [Bash Day 04](../30-days-of-bash/day-04.md): file tests such as `-x` and `-w` inside scripts.

**Next:** [Day 05](day-05.md)
