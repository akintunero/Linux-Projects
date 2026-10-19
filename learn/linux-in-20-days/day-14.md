# Day 14: Backups, Archives and Safe Automation

> **Time:** ~75 min · **Level:** Intermediate
> **Prerequisites:** [Day 13](day-13.md), [Day 03](day-03.md) (hard links)

## Goal

By the end of this lesson you can:

- Create, list, verify and restore `tar.gz` archives with checksums.
- Mirror and snapshot directories with `rsync`, and preview changes with a dry run before using `--delete`.
- Write a backup script that fails loudly instead of printing "ok" after an error, and explain why an untested backup is not a backup.

## Concepts

### The rule: a backup you have not restored is a hope

A backup job has three parts: **copy**, **verify** (checksum, listing, or better, a test restore) and **retain/prune** (do not fill the disk). Follow the 3-2-1 idea where it matters: three copies, two kinds of media, one off-site.

### tar and checksums

```bash
tar -czf site.tar.gz site            # create, gzip-compressed; paths stored as given
tar -tzf site.tar.gz                 # list contents without extracting
tar -xzf site.tar.gz -C restore      # extract into another directory
sha256sum site.tar.gz > site.tar.gz.sha256
sha256sum -c site.tar.gz.sha256      # prints "OK" or "FAILED"
```

Store **relative** paths (`tar -C parent name`). An archive of `/home/me/site` restores to an absolute location, which is rarely what you want. GNU tar strips the leading `/` with a warning; do not rely on it.

### rsync

`rsync -a SRC/ DEST/` copies only what changed. Two details trip everyone:

| Command | Result |
|---------|--------|
| `rsync -a site dest` | creates `dest/site/...` (copies the directory itself) |
| `rsync -a site/ dest` | copies the **contents** into `dest/` |

Add `--delete` to make `DEST` an exact mirror: files missing in the source are **removed** from the destination. Always preview with `-n` (dry run) and `-i` (itemise changes):

```bash
rsync -a --delete -n -i site/ dest/
```

`--link-dest=PREVIOUS` makes unchanged files in a new snapshot **hard links** to the previous snapshot (you met hard links on [Day 03](day-03.md)). Each snapshot looks like a full copy, but only changed files use new space. Deleting an old snapshot does not hurt newer ones, because data is freed only when the last link goes.

rsync decides "changed" by comparing size and modification time. A file edited to the same size within the same second can be skipped; add `-c` (checksums) when you must be sure.

> [!WARNING]
> `rsync --delete` and `rm -rf` with a variable are the two classic ways to destroy a backup (or the
> original). An empty variable can turn `rsync -a --delete src/ "$DEST"/` into `rsync -a --delete src/ /`.
> Guard variables with `${DEST:?}`, always dry-run with `-n` first, and never point `--delete` at a
> directory that holds anything you did not put there.

**Undo:** for `--delete` there is none unless you have a snapshot or `--backup --backup-dir=DIR`, which moves deleted/overwritten files into `DIR` instead of destroying them.

### A script skeleton that fails loudly

```bash
#!/usr/bin/env bash
set -euo pipefail                  # stop on errors, unset variables, failed pipes
src=${1:?usage: backup.sh SRC DEST}
dest=${2:?usage: backup.sh SRC DEST}
# ... work ...
echo "backup ok"                   # reached only if every step above succeeded
```

The scripting course explains each line: [Bash Day 03](../30-days-of-bash/day-03.md) (variables and strict mode) and [Day 04](../30-days-of-bash/day-04.md) (tests and exit codes). Day 16 shows how to schedule this.

## Worked example

Scenario: a small website directory must be backed up, checked, restored on a different machine layout, and snapshotted daily. All in a scratch directory.

```bash
cd "$(mktemp -d)"
mkdir -p site/css
echo "<h1>home</h1>" > site/index.html
echo "body{}" > site/css/main.css
tar -czf site.tar.gz site
tar -tzf site.tar.gz
sha256sum site.tar.gz > site.tar.gz.sha256
sha256sum -c site.tar.gz.sha256
```

**Expected output:**

```text
site/
site/index.html
site/css/
site/css/main.css
site.tar.gz: OK
```

Prove the backup works by restoring it somewhere else and comparing:

```bash
mkdir restore
tar -xzf site.tar.gz -C restore
diff -r site restore/site && echo "restore identical"
```

**Expected output:**

```text
restore identical
```

Now damage the archive and see the checksum catch it:

```bash
echo "tampered" >> site.tar.gz
sha256sum -c site.tar.gz.sha256; echo "rc=$?"
```

**Expected output** (the first line goes to stdout, a warning to stderr):

```text
site.tar.gz: FAILED
rc=1
```

The trailing slash difference in rsync:

```bash
rsync -a site dest1; ls dest1
rsync -a site/ dest2; ls dest2
```

**Expected output:**

```text
site
css
index.html
```

Preview a mirror update before doing it. After editing the source, the dry run shows what *would* change:

```bash
echo v2 >> site/index.html
rsync -a --delete -n -i site/ dest2/
rsync -a --delete site/ dest2/
cmp site/index.html dest2/index.html && echo synced
```

**Expected output:**

```text
>f.st...... index.html
synced
```

`>f.st......` means a file is being sent because its size (`s`) and time (`t`) differ. Finally, snapshots with hard links:

```bash
mkdir snaps
rsync -a site/ snaps/day1/
echo change >> site/index.html
rsync -a --link-dest="$PWD/snaps/day1" site/ snaps/day2/
stat -c '%h %n' snaps/day1/css/main.css snaps/day2/css/main.css snaps/day1/index.html snaps/day2/index.html
```

**Expected output:**

```text
2 snaps/day1/css/main.css
2 snaps/day2/css/main.css
1 snaps/day1/index.html
1 snaps/day2/index.html
```

`main.css` did not change, so both snapshots share one copy (link count 2). `index.html` changed, so each snapshot has its own (count 1). Restoring day 1 or day 2 is just a copy; pruning day 1 leaves day 2 intact.

**Undo:** everything here lives in a temporary directory: `rm -r` the directory printed by `pwd`, after checking it with `ls`.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `rsync -a site backup` yields `backup/site/...` | No trailing slash copies the directory itself | `rsync -a site/ backup/` |
| `rsync --delete` with an empty variable | Destination may become `/` | `${DEST:?}`, dry-run first |
| Script prints "backup ok" after errors | No `set -e` or status checks | `set -euo pipefail`, test each critical step |
| Archive made from `$PWD/site` restores to the old path | Absolute paths stored | `tar -C "$parent" "$name"` |
| Backup on the same disk as the data | Disk failure loses both | Second device or off-site copy |
| Never testing restore | You find the problem during the disaster | Scheduled restore test plus `diff -r` |
| `rsync` skips a file you edited | Same size and same second | `rsync -c`, or touch the file |
| Backing up a running database by copying files | Inconsistent copy | Use the database's dump tool |

## Exercises

Reference solutions: [`solutions/day-14/`](solutions/day-14/). All run in temporary directories. `hard.sh` needs `rsync` (`sudo apt install rsync` or `sudo dnf install rsync`).

### Easy

Make a timestamped `site-YYYYmmdd-HHMMSS.tar.gz` of a directory with relative paths, list it and write a SHA-256 checksum file.

**Acceptance criteria:**

- `tar -tzf` shows `site/css/main.css` and no member starts with `/`.
- `sha256sum -c` prints `OK`.

### Medium

Restore the archive into a new directory, prove with `diff -r` that it is identical, then damage the archive and show that the checksum check fails.

**Acceptance criteria:**

- `diff -r` exits 0 for the restore.
- After appending garbage, `sha256sum -c` exits non-zero.

### Hard

Write `snapshot.sh SRC DEST [KEEP]`: each run creates `DEST/<timestamp>` using `rsync --link-dest` against the newest earlier snapshot, builds into `DEST/.partial` and renames only when rsync succeeded, and keeps only the newest KEEP snapshots (default 7).

**Acceptance criteria:**

- An unchanged file has link count 2 across consecutive snapshots; a changed file has its own inode and the older snapshot keeps the old content.
- After three runs with `KEEP=2`, the oldest snapshot is gone.
- A missing source gives an error, a non-zero status, and no `.partial` directory.

### Break it

[`solutions/day-14/break-it.sh`](solutions/day-14/break-it.sh) should copy a directory's contents into `DEST`, make a tar.gz that restores anywhere, and print `backup ok` only on success. It has three bugs.

**Acceptance criteria:** `DEST/index.html` exists directly (no `DEST/site/`), the archive contains `site/index.html` with no leading `/`, and a missing source gives an error without `backup ok`.

## Solutions

<details>
<summary>Easy</summary>

```bash
archive="site-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$archive" site
tar -tzf "$archive"
sha256sum "$archive" > "$archive.sha256" && sha256sum -c "$archive.sha256"
```

Script: [`easy.sh`](solutions/day-14/easy.sh).

</details>

<details>
<summary>Medium</summary>

```bash
mkdir restore && tar -xzf site.tar.gz -C restore
diff -r site restore/site
printf 'garbage' >> site.tar.gz
sha256sum -c site.tar.gz.sha256        # exits 1
```

Script: [`medium.sh`](solutions/day-14/medium.sh).

</details>

<details>
<summary>Hard</summary>

```bash
rsync -a --link-dest="$prev" -- "$src"/ "$dest/.partial/" && mv "$dest/.partial" "$dest/$name"
```

Snapshot names are timestamps, so `sort` orders them and `tail -n 1` is the newest. To prune, delete the oldest `count - keep` entries. In the self-test the changed file has a different length because rsync's quick check compares size and time; `v1` to `v2` within one second would be treated as unchanged. Script with `--self-test`: [`hard.sh`](solutions/day-14/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. `rsync -a $src $dest` has no trailing slash on the source, so it creates `dest/site`. Use `"$src"/`.
2. `tar -czf x $PWD/$src` stores an absolute path. Use `tar -C "$(dirname "$src")" "$(basename "$src")"`.
3. Nothing checks failures, so `echo "backup ok"` always runs. Use `set -euo pipefail` and return an error when the source is missing.

Fixed script: [`break-it.fixed.sh`](solutions/day-14/break-it.fixed.sh).

</details>

## Self-check

1. What does the trailing slash on `rsync -a site/ dest/` change?
2. Why should you run `rsync --delete` with `-n` first?
3. How does `--link-dest` save space?
4. Why store relative paths in a tar archive?
5. What is the only proof that a backup works?

<details>
<summary>Answers</summary>

1. It copies the directory's contents instead of the directory itself.
2. `--delete` removes files from the destination; the dry run shows what would be removed.
3. Unchanged files in the new snapshot are hard links to the previous snapshot's files instead of new copies.
4. So it can be restored anywhere without touching the original location.
5. A successful restore test (for example `diff -r` against the source).

</details>

## Cheat sheet

```bash
tar -czf a.tgz -C /parent name       # create with relative paths
tar -tzf a.tgz; tar -xzf a.tgz -C /dest
sha256sum a.tgz > a.tgz.sha256; sha256sum -c a.tgz.sha256
rsync -a SRC/ DEST/                  # contents of SRC into DEST
rsync -a --delete -n -i SRC/ DEST/   # dry run of a mirror
rsync -a --link-dest=/prev SRC/ /new # hard-linked snapshot
rsync -a --backup --backup-dir=/old --delete SRC/ DEST/   # keep what --delete would destroy
diff -r original restored            # prove a restore
```

## Further reading

- [rsync manual page](https://man7.org/linux/man-pages/man1/rsync.1.html): authoritative description of every flag, including `--link-dest` and `--backup-dir`.
- [Bash Day 04: tests and exit codes](../30-days-of-bash/day-04.md): how to make a script fail loudly.

**Next:** [Day 15](day-15.md)
