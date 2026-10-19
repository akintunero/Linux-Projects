# Day 03: The Filesystem Hierarchy, Paths and Links

> **Time:** ~45 min · **Level:** Beginner
> **Prerequisites:** [Day 02](day-02.md)

## Goal

By the end of this lesson you can:

- Say where configuration (`/etc`), logs (`/var/log`), programs (`/usr/bin`) and temporary files (`/tmp`) live.
- Move around with absolute and relative paths, and explain `.`, `..`, `~` and `-`.
- Create hard links and symbolic links, and predict what happens to each when the original is deleted.

## Concepts

### One tree, starting at `/`

Linux has a single directory tree. Disks and USB sticks are *mounted* into it (Day 08) instead of getting drive letters.

| Path | Holds | Typical task |
|------|-------|--------------|
| `/etc` | system configuration (text files) | edit `/etc/ssh/sshd_config` |
| `/var/log` | logs | read `/var/log/syslog` or use `journalctl` |
| `/var/lib`, `/var/cache` | program state and caches | package databases |
| `/usr/bin`, `/usr/sbin` | programs (`/bin`, `/sbin` are links to them on modern systems) | find where `grep` lives |
| `/home/NAME`, `/root` | user files; root's home | your work |
| `/tmp` | scratch space, cleared on reboot or by a timer | throwaway files |
| `/proc`, `/sys` | live kernel information, not real files | `cat /proc/loadavg` |
| `/dev` | device files | `/dev/null` |
| `/opt`, `/srv`, `/mnt`, `/media` | add-on software, served data, mount points | third-party apps |

The standard behind this layout is the Filesystem Hierarchy Standard (see Further reading). Details differ slightly between distributions.

```bash
ls -d /etc /var/log /usr/bin /tmp /home /proc
```

**Expected output** (sorted alphabetically by `ls`):

```text
/etc
/home
/proc
/tmp
/usr/bin
/var/log
```

### Absolute and relative paths

- An **absolute** path starts with `/` and means the same thing everywhere: `/etc/hosts`.
- A **relative** path starts from your current directory: `docs/a.txt`.
- `.` is the current directory, `..` its parent, `~` your home, `cd -` the previous directory.

### Links: two ways to have one file under two names

| | Hard link (`ln a b`) | Symbolic link (`ln -s a b`) |
|---|---|---|
| What it is | another name for the same data (same inode) | a small file containing a path |
| Survives deleting the original | yes | no, it dangles |
| Can cross filesystems | no | yes |
| Can point to a directory | no (normally) | yes |
| Shows in `ls -l` as | normal file, link count 2 | `l...` with `->` target |

A relative symlink target is resolved relative to **the directory that holds the link**, not your current directory. This is the most common link bug.

## Worked example

Scenario: you keep reports under `data/reports` and want two convenient names for one of them. Then someone deletes the original.

```bash
cd "$(mktemp -d)"
mkdir -p data/reports
echo "v1" > data/reports/q1.txt
ln -s data/reports/q1.txt soft.txt
ln data/reports/q1.txt hard.txt
stat -c '%A %N' soft.txt
stat -c '%h %n' data/reports/q1.txt hard.txt
[[ data/reports/q1.txt -ef hard.txt ]] && echo "same file"
readlink soft.txt
```

**Expected output:**

```text
lrwxrwxrwx 'soft.txt' -> 'data/reports/q1.txt'
2 data/reports/q1.txt
2 hard.txt
same file
data/reports/q1.txt
```

`%h` is the hard-link count: the data now has two names. `-ef` asks "are these the same file (same device and inode)?".

Now delete the original name and see who survives:

```bash
rm data/reports/q1.txt
cat hard.txt
cat soft.txt
stat -c '%A %N' soft.txt
[[ -e soft.txt ]] || echo broken
```

**Expected output** (the error message wording varies by coreutils version):

```text
v1
cat: soft.txt: No such file or directory
lrwxrwxrwx 'soft.txt' -> 'data/reports/q1.txt'
broken
```

The hard link still reaches the data because the data is only freed when the *last* name goes. The symlink only stored a path, and that path no longer exists, so it dangles.

Finally, practise path movement. `cd -` returns to where you were:

```bash
cd data/reports
cd ..
cd -
```

**Expected output** (the temporary directory name will differ):

```text
/tmp/tmp.3D1jkuGEog/data/reports
```

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `ln -s releases/v1 links/current` and the link is broken | Relative targets resolve from the link's own directory (`links/`) | `ln -s ../releases/v1 links/current` or use an absolute path |
| Re-running `ln -s new current` fails with "File exists" | A link already has that name | `ln -sfn new current` |
| `ln -sf new current` creates `old/new` instead of replacing | When `current` is a link to a directory, `ln` follows it | add `-n` |
| Expecting a symlink to keep data after deleting the original | It only stores a path | use a hard link, or copy |
| Hard-linking across disks: "Invalid cross-device link" | Hard links must stay inside one filesystem | use `ln -s` or copy |
| `cd` to a path with spaces fails | Spaces split arguments | `cd "My Documents"` |

## Exercises

Use a scratch directory. Reference solutions: [`solutions/day-03/`](solutions/day-03/).

### Easy

Create `a/b/c`, `cd` into `c`, then reach `a` using only `..` (no absolute paths).

**Acceptance criteria:**

- `basename "$PWD"` prints `a`.
- You typed no path beginning with `/`.

### Medium

Build `releases/v1` and `releases/v2`, each with a `version.txt` (`one` and `two`). Create a symlink `current` that points to `releases/v1`, then switch it to `releases/v2` in one command.

**Acceptance criteria:**

- `readlink current` prints `releases/v2`.
- `cat current/version.txt` prints `two`.
- `releases/v1/v2` does not exist.

### Hard

Write `linkcheck.sh DIR` that prints `dangling: PATH` for every symlink whose target is missing and `hardlinked: PATH` for every regular file with more than one link.

**Acceptance criteria:**

- Given one real file with one extra hard link, one good symlink and one dangling symlink, it reports 1 dangling and 2 hardlinked entries and does not report the good symlink.
- A non-directory argument gives a message and a non-zero exit status.
- File names with spaces are handled (use `-print0`).

### Break it

Run [`solutions/day-03/break-it.sh`](solutions/day-03/break-it.sh) in an empty directory. A "deploy" is supposed to leave `links/current` pointing at release `v2`, but it fails in three ways. Fix it.

**Acceptance criteria:** the script prints `two` and can be run twice in a row without errors.

## Solutions

<details>
<summary>Easy</summary>

```bash
mkdir -p a/b/c
cd a/b/c
cd ../..
basename "$PWD"
```

Script: [`easy.sh`](solutions/day-03/easy.sh).

</details>

<details>
<summary>Medium</summary>

```bash
mkdir -p releases/v1 releases/v2
echo one > releases/v1/version.txt
echo two > releases/v2/version.txt
ln -sfn releases/v1 current
ln -sfn releases/v2 current
```

`-f` replaces the link; `-n` stops `ln` from descending into the directory the old link points to. Script: [`medium.sh`](solutions/day-03/medium.sh).

</details>

<details>
<summary>Hard</summary>

```bash
find "$dir" -xtype l -print0          # dangling symlinks (GNU find)
find "$dir" -type f -links +1 -print0 # files with more than one hard link
```

`-xtype` is like `-type` but looks at what a link points to; for a broken link there is nothing to follow, so it still reports `l`. Script with `--self-test`: [`hard.sh`](solutions/day-03/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. `ln -s releases/v1 links/current` resolves `releases/v1` from inside `links/`, so the target is wrong. Use `../releases/v1`.
2. The second `ln -s` fails with "File exists". Add `-f`.
3. With `-f` but without `-n`, `ln` would put a new link *inside* the directory the old one points at. Use `-sfn`.

Fixed script: [`break-it.fixed.sh`](solutions/day-03/break-it.fixed.sh).

</details>

## Self-check

1. Which directory holds system configuration files?
2. After `ln a b` and `rm a`, can you still read `b`?
3. Where is a relative symlink target resolved from?
4. What does `cd -` do?
5. Why can't a hard link cross filesystems?

<details>
<summary>Answers</summary>

1. `/etc`.
2. Yes. Both names point at the same data; it is freed only when the last name is removed.
3. From the directory containing the link, not your current directory.
4. It returns to the previous directory and prints its path.
5. A hard link is a second directory entry for an inode number, and inode numbers only mean something inside one filesystem.

</details>

## Cheat sheet

```bash
pwd -P                  # current directory with symlinks resolved
cd -                    # back to the previous directory
cd ~                    # home
ln -s TARGET LINK       # symlink
ln FILE NAME            # hard link
ln -sfn NEW LINK        # atomically repoint a directory symlink
readlink -f LINK        # fully resolved absolute path
stat -c '%h %i %n' F    # link count, inode, name
find . -xtype l         # dangling symlinks
```

## Further reading

- [Filesystem Hierarchy Standard 3.0](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html): the specification behind `/etc`, `/var`, `/usr` and friends.
- [hier(7)](https://man7.org/linux/man-pages/man7/hier.7.html): a manual page describing the layout, with notes on what is Linux-specific.
- [symlink(7)](https://man7.org/linux/man-pages/man7/symlink.7.html): precisely how the kernel follows symbolic links.

**Next:** [Day 04](day-04.md)
