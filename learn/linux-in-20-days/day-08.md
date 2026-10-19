# Day 08: Disks, Filesystems, Mounting and LVM

> **Time:** ~75 min · **Level:** Intermediate
> **Prerequisites:** [Day 07](day-07.md)

## Goal

By the end of this lesson you can:

- Explain how disks, partitions, filesystems and mount points relate, and read `lsblk`, `df`, `du` and `findmnt`.
- Find what is eating disk space, including hidden directories and used-up inodes.
- Create and check an ext4 filesystem in an image file without root, and describe the root-only steps (partition, mount, `/etc/fstab`, LVM) with their undo steps.

## Concepts

### Layers

```text
disk (/dev/sdb)  ->  partition (/dev/sdb1)  ->  filesystem (ext4, xfs)  ->  mount point (/data)
                     or LVM: disk -> PV -> VG -> LV (/dev/vg0/data) -> filesystem -> mount point
```

- A **block device** is raw storage. A **filesystem** gives it files and directories.
- **Mounting** attaches a filesystem to a directory. What was in that directory before is hidden while something is mounted on it.
- **ext4** is the common default on Debian/Ubuntu; **XFS** is the default on RHEL-family systems. Both are fine; the repair and resize tools differ.

### Read-only inspection (safe, no root)

| Command | Answers |
|---------|---------|
| `lsblk` | what disks and partitions exist, and where they are mounted |
| `df -hT` | how full is each mounted filesystem, and of which type |
| `df -i` | how many **inodes** are used (a disk can be "full" with free space if inodes run out) |
| `findmnt` | the mount tree, including options |
| `du -h --max-depth=1 DIR \| sort -rh` | which subdirectories are biggest |

`df` asks the filesystem; `du` adds up files. They disagree when a deleted file is still held open by a process (Day 10).

### Sparse files and image files

A *sparse* file claims a big size but only stores the blocks you write. That makes it perfect for a safe practice disk: `truncate -s 16M disk.img` creates a "16 MiB disk" that uses almost no space, and `mkfs.ext4 -F` can format a plain file without root.

## Worked example (no root needed)

Scenario: you want to understand a filesystem before trusting it with data. Build one in a file and inspect it.

```bash
cd "$(mktemp -d)"
truncate -s 16M disk.img
mkfs.ext4 -q -F disk.img
file disk.img | grep -o 'ext4 filesystem'
```

On Debian/Ubuntu the e2fsprogs tools live in `/usr/sbin`, which may not be on a normal user's `PATH`; if you see "command not found", run `export PATH=$PATH:/usr/sbin:/sbin`. RHEL-family systems need `sudo dnf install e2fsprogs` first if it is missing.

**Expected output:**

```text
ext4 filesystem
```

Inspect and check it. `e2fsck -fn` forces a check but answers "no" to every repair question, so it cannot change anything:

```bash
dumpe2fs -h disk.img 2>/dev/null | grep -E '^(Block count|Block size)'
e2fsck -fn disk.img | tail -n 2
```

**Expected output** (the fsck line shows real values; yours may differ slightly with e2fsprogs version):

```text
Block count:              4096
Block size:               4096
Pass 5: Checking group summary information
disk.img: 12/4096 files (8.3% non-contiguous), 1323/4096 blocks
```

Now see sparseness. Allocated size and apparent size differ:

```bash
du -h disk.img
du -h --apparent-size disk.img
```

**Expected output** (allocated size depends on filesystem and options):

```text
180K disk.img
16M disk.img
```

Find space hogs. Create a tree with a hidden directory, because `du -sh *` would miss it:

```bash
mkdir -p tree/a tree/b tree/.cache
dd if=/dev/zero of=tree/a/big bs=1M count=3 status=none
dd if=/dev/zero of=tree/b/small bs=1k count=10 status=none
dd if=/dev/zero of=tree/.cache/hidden bs=1M count=5 status=none
du -h --max-depth=1 tree | sort -rh
```

**Expected output:**

```text
8.1M tree
5.0M tree/.cache
3.0M tree/a
12K tree/b
```

`sort -h` understands `K`, `M`, `G`. `sort -n` would put `12K` after `8.1M`.

Look at your real system (output is specific to your machine, so none is shown here):

```bash
lsblk
df -hT
findmnt -n -o TARGET,FSTYPE /
```

## Root-only: partition, mount, persist (read, do not run on a machine you care about)

These commands were **not run** while writing this lesson, because they need root and a spare disk. Practise them in a VM with an extra virtual disk, never on your system disk.

> [!WARNING]
> `fdisk`, `mkfs`, `mkfs.xfs` and `wipefs` destroy whatever is on the target. A wrong device name
> (`/dev/sda` instead of `/dev/sdb`) erases your operating system. Run `lsblk` first, confirm the size
> and that it has no mount points, and take a VM snapshot. A typo in `/etc/fstab` can stop the machine
> booting; always test with `sudo mount -a` before rebooting.

Loop devices let you rehearse with a file instead of a disk:

```bash
truncate -s 256M /tmp/lab.img
sudo losetup --find --show /tmp/lab.img     # prints e.g. /dev/loop5
sudo mkfs.ext4 /dev/loop5
sudo mkdir -p /mnt/lab
sudo mount /dev/loop5 /mnt/lab
df -h /mnt/lab
```

**Undo (always, in this order):**

```bash
sudo umount /mnt/lab
sudo losetup -d /dev/loop5
rm /tmp/lab.img
sudo rmdir /mnt/lab
```

Making a mount permanent uses `/etc/fstab`. Prefer UUIDs, which do not change when device names do:

```bash
sudo blkid /dev/loop5                       # shows UUID="..."
```

```text
# /etc/fstab line:  <device>        <mount point>  <type>  <options>        <dump> <fsck>
UUID=PUT-THE-UUID-HERE              /data          ext4    defaults,nofail  0      2
```

`nofail` lets the system boot even if the disk is missing. Test before rebooting with `sudo mount -a`; if it prints nothing and `findmnt /data` shows the mount, the line is valid.

### LVM in one page

LVM sits between disks and filesystems so volumes can grow without repartitioning. Install on Debian/Ubuntu with `sudo apt install lvm2`, on RHEL-family with `sudo dnf install lvm2`.

```bash
sudo pvcreate /dev/sdb                      # disk -> physical volume
sudo vgcreate vg0 /dev/sdb                  # pool of space
sudo lvcreate -n data -L 5G vg0             # carve a logical volume
sudo mkfs.ext4 /dev/vg0/data                # RHEL default is XFS: sudo mkfs.xfs /dev/vg0/data
sudo mount /dev/vg0/data /data
sudo lvextend -r -L +2G /dev/vg0/data       # grow volume AND filesystem (-r); works for ext4 and XFS
```

XFS can be grown but never shrunk. ext4 can be shrunk only while unmounted. **Undo:** `sudo umount /data; sudo lvremove vg0/data; sudo vgremove vg0; sudo pvremove /dev/sdb`.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `du -sh *` misses `.cache` | `*` does not match dotfiles | `du -h --max-depth=1 . \| sort -rh` |
| `sort -n` on `du -h` output | Ordering `K`/`M`/`G` text numerically is wrong | `sort -h`, or `du -k` with `sort -n` |
| "No space left on device" but `df -h` shows free space | Out of inodes | `df -i`; delete the millions of tiny files |
| `df` says 100% but `du` finds far less | A deleted file is still open in a process | `lsof +L1`, then restart that process |
| `mkfs.ext4 disk.img` asks "not a block special device" | Plain files need confirmation | `-F` (only for image files you mean to format) |
| Mount added to fstab with `/dev/sdb1` | Device names can change between boots | Use `UUID=`; add `nofail` for removable/secondary disks |
| Forgetting to `umount` before detaching | Cached writes are lost | `sync`, then `umount` |

## Exercises

Reference solutions: [`solutions/day-08/`](solutions/day-08/). All run without root.

### Easy

Create an 8 MiB ext4 filesystem in an image file and print its block size.

**Acceptance criteria:**

- `file disk.img` reports an `ext4 filesystem`.
- The block size printed is the number from `dumpe2fs -h`, not typed by hand.
- No `sudo` was used.

### Medium

Build a directory tree with a hidden 5 MiB directory (`.cache`), a 3 MiB `a` and a 10 KiB `b`. List the entries under it largest first.

**Acceptance criteria:**

- The order is the tree itself, `.cache`, `a`, `b`.
- Hidden directories are included.

### Hard

Write `imgcheck.sh IMAGE` that checks an ext4 image read-only and prints `OK` (exit 0) or `DAMAGED` (exit 1); a path that is not a regular file prints an error and exits 2.

**Acceptance criteria:**

- A freshly made image prints `OK`.
- After overwriting 4 KiB at offset 4096 with random bytes, it prints `DAMAGED`.
- `e2fsck -n` is used so the checker never modifies the image.

### Break it

[`solutions/day-08/break-it.sh`](solutions/day-08/break-it.sh) should list the biggest directories first, including hidden ones, and warn when the filesystem is more than 1% full. It has three bugs.

**Acceptance criteria:** the `.cache` directory appears second in the list (after the total), and the numeric comparison runs with no error message.

## Solutions

<details>
<summary>Easy</summary>

```bash
truncate -s 8M disk.img
mkfs.ext4 -q -F disk.img
dumpe2fs -h disk.img 2>/dev/null | awk -F: '/^Block size/ {gsub(/ /, "", $2); print $2}'
```

Script: [`easy.sh`](solutions/day-08/easy.sh).

</details>

<details>
<summary>Medium</summary>

```bash
du -k --max-depth=1 tree | sort -rn | awk '{print $2}'
```

`--max-depth=1` lists hidden subdirectories, and `-k` gives plain numbers that `sort -n` handles correctly. Script: [`medium.sh`](solutions/day-08/medium.sh).

</details>

<details>
<summary>Hard</summary>

```bash
if e2fsck -fn "$img" >/dev/null 2>&1; then echo OK; return 0; fi
echo DAMAGED; return 1
```

`e2fsck` exits 0 when clean and non-zero when it finds problems. Script with `--self-test`: [`hard.sh`](solutions/day-08/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. `du -sh *` skips hidden entries; use `du -h --max-depth=1 .`.
2. `sort -n` cannot order `10K`/`3.0M`; use `sort -rh`.
3. `df` prints `42%`; `[ $usage -gt 1 ]` needs an integer. Strip the percent sign with `tr -dc '0-9'`.

Fixed script: [`break-it.fixed.sh`](solutions/day-08/break-it.fixed.sh).

</details>

## Self-check

1. What is the difference between a partition and a filesystem?
2. Why prefer `UUID=` over `/dev/sdb1` in `/etc/fstab`?
3. `df -h` shows 30% free but you get "No space left on device". What do you check?
4. Which command grows an LVM volume and its filesystem together?
5. Why is `e2fsck -n` safe to run on an image you care about?

<details>
<summary>Answers</summary>

1. A partition is a slice of a disk; a filesystem is the structure (ext4, XFS) that stores files inside it.
2. Device names can change between boots; a UUID identifies the filesystem itself.
3. Inodes: `df -i`. Also check for deleted-but-open files with `lsof +L1`.
4. `lvextend -r -L +SIZE /dev/VG/LV`.
5. `-n` opens it read-only and answers "no" to every repair question.

</details>

## Cheat sheet

```bash
lsblk; df -hT; df -i; findmnt           # inspect
du -h --max-depth=1 . | sort -rh        # space hogs
truncate -s 16M disk.img                # sparse practice disk
mkfs.ext4 -F disk.img                   # format an image file
e2fsck -fn disk.img                     # read-only check
sudo mount /dev/X /mnt; sudo umount /mnt
sudo blkid                              # UUIDs
sudo mount -a                           # test fstab before reboot
sudo lvextend -r -L +2G /dev/vg0/data   # grow LV + filesystem
```

## Further reading

- [lsblk(8)](https://man7.org/linux/man-pages/man8/lsblk.8.html): every column you can ask `lsblk` for.
- [mount(8)](https://man7.org/linux/man-pages/man8/mount.8.html): mount options and the exact `fstab` format.
- [Ubuntu Server documentation](https://ubuntu.com/server/docs): Ubuntu's official server docs hub, including storage and LVM guides.
- [RHEL documentation: LVM administration](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_and_managing_logical_volumes/index): Red Hat's step-by-step guide, using XFS.

**Next:** [Day 09](day-09.md)
