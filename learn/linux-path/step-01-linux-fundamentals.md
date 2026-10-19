# Step 1: Linux Fundamentals (File Systems, Permissions, Bash)

> **Time:** ~6-8 hours · **Level:** Beginner → Advanced
> **Prerequisites:** none · **Next:** [Step 2: Users and Groups](step-02-user-and-group-mgmnt.md)

<!-- -->

> [!WARNING]
> Tasks 1.4, 1.5, 1.8 and 1.9 create users, change ownership, mount filesystems and use `chroot`.
> Do this in a throwaway VM or the devcontainer, never on a machine you cannot afford to lose.
> Keep a second SSH session open while changing SSH or firewall settings (not needed in this step,
> but a good habit from now on).

## How to read each task

Every task has the same parts: **what you will learn**, **target distro**, **risk level**,
**commands**, **verify it worked**, **acceptance criteria**, **undo it** and **troubleshooting**.
Risk levels: `safe` (cannot hurt the system), `can lock you out`, `destructive` (can lose data).
Prompts (`$`/`#`) are left out of the code blocks so you can copy and paste them.
Output marked **Expected output** was captured from a real run on Ubuntu 24.04 unless the task
says *typical output*. Paths such as `/root/...` will show your own home directory instead.

## Where to practise

Pick one lab and stay with it for the whole path:

- A VM (VirtualBox, VMware, KVM) with Ubuntu 24.04 LTS or AlmaLinux/Rocky 9. Take a snapshot first.
- The repo devcontainer in `.devcontainer/` (root inside a container, nothing else is affected).
- WSL 2 with Ubuntu works for most of this step but not for disk or boot tasks later on.

---

## Beginner

### Task 1.1: Build a project directory tree

- **What you will learn:** the filesystem hierarchy, `mkdir -p`, brace expansion and `tree`.
- **Target distro:** both. Install `tree` first (`apt` on Debian/Ubuntu, `dnf` on RHEL family).
- **Risk level:** `safe`. You only create files in your home directory.

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install -y tree
# RHEL family (AlmaLinux, Rocky, Fedora)
# sudo dnf install -y tree

mkdir -p ~/projects/webapp/{src,docs,tests}
tree ~/projects/webapp
```

**Verify it worked**

```bash
ls ~/projects/webapp
```

**Expected output** (the `tree` command prints this):

```text
/root/projects/webapp
|-- docs
|-- src
`-- tests

4 directories, 0 files
```

On a normal desktop `tree` draws the branches with line characters instead of `|--`; both are fine.

**Acceptance criteria**

- [ ] `~/projects/webapp` contains at least 3 subdirectories.
- [ ] `tree` shows all of them.

**Undo it**

```bash
rm -r ~/projects/webapp
```

**Troubleshooting**

- `tree: command not found`: install it as shown above.
- `mkdir: cannot create directory ... File exists`: a file with that name exists. Pick another name or use `ls -ld` to see what it is.
- Only one directory is created and it is literally named `{src,docs,tests}`: you ran the command in `sh`, not Bash. Run `bash` first.

### Task 1.2: Change permissions with symbolic and octal modes

- **What you will learn:** the read/write/execute bits for user, group and others, and the two ways to write them.
- **Target distro:** both.
- **Risk level:** `safe` inside your own home directory. Never run `chmod -R` on `/` or `/etc`.

```bash
cd ~/projects/webapp
touch src/app.sh docs/notes.txt

chmod u+x src/app.sh        # symbolic: add execute for the owner
chmod 755 src               # octal: rwx for owner, r-x for group and others
chmod 644 docs/notes.txt    # octal: rw- r-- r--
chmod go-rwx docs           # symbolic: remove all access for group and others

ls -l src docs
stat -c '%a %A %n' src/app.sh docs
```

**Verify it worked.** Octal digits are a sum: read = 4, write = 2, execute = 1.

**Expected output:**

```text
744 -rwxr--r-- src/app.sh
700 drwx------ docs
```

**Acceptance criteria**

- [ ] `src/app.sh` is `744`, `docs` is `700`.
- [ ] You can explain why `docs` needs the `x` bit (to enter a directory you need execute on it).

**Undo it**

```bash
chmod 644 ~/projects/webapp/src/app.sh
chmod 755 ~/projects/webapp/docs
```

**Troubleshooting**

- `Operation not permitted`: you do not own the file. Check with `ls -l`.
- `Permission denied` when running a script: the `x` bit is missing, or the filesystem is mounted `noexec`.
- Changes seem to have no effect on a Windows drive in WSL (`/mnt/c`): those mounts ignore Unix modes. Work in `~`.

### Task 1.3: Your first useful Bash script

- **What you will learn:** the shebang, script arguments with a default, input checks, exit codes, and `shellcheck`.
- **Target distro:** both.
- **Risk level:** `safe`.
- **Go deeper:** the full scripting course is [30 Days of Bash](../30-days-of-bash/). Do not skip it, this task is a taster.

```bash
cat > ~/projects/webapp/src/list-files.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
dir="${1:-.}"
[[ -d "$dir" ]] || { echo "error: '$dir' is not a directory" >&2; exit 1; }
ls -lA -- "$dir"
EOF
chmod +x ~/projects/webapp/src/list-files.sh

~/projects/webapp/src/list-files.sh ~/projects/webapp/docs
~/projects/webapp/src/list-files.sh /nope; echo "exit=$?"
```

**Verify it worked**

**Expected output:**

```text
total 0
-rw-r--r-- 1 root root 0 Oct 17 12:26 notes.txt
error: '/nope' is not a directory
exit=1
```

Optionally lint the script (`sudo apt install -y shellcheck`, then `shellcheck ~/projects/webapp/src/list-files.sh`).
No output from `shellcheck` means no warnings.

**Acceptance criteria**

- [ ] The script lists a directory you pass in, and the current directory if you pass none.
- [ ] It prints an error to stderr and exits non-zero for a bad path.

**Undo it**

```bash
rm ~/projects/webapp/src/list-files.sh
```

**Troubleshooting**

- `bash: ./list-files.sh: Permission denied`: run `chmod +x` on it.
- `bad interpreter: No such file or directory` with `^M`: the file has Windows line endings. Run `sed -i 's/\r$//' file`.
- `unbound variable`: you used `set -u` and referenced an unset variable; give it a default like `${1:-.}`.

---

## Intermediate

### Task 1.4: Department directories with group permissions

- **What you will learn:** groups as the unit of access, `chown`, directory modes, and why ACLs beat group tricks when rules are one-way.
- **Target distro:** both (`useradd`, `groupadd`, `setfacl` are identical).
- **Risk level:** `destructive` for the accounts you create (they are real users). Use a lab machine.
- **Goal:** HR can read Finance, Finance cannot touch HR, IT can access everything.

Plain Unix permissions give one group per directory, so "HR may read Finance" needs an ACL
(Task 1.5 explains them in detail). Install `acl` first (`sudo apt install -y acl`, or `sudo dnf install -y acl`).

```bash
sudo groupadd hr; sudo groupadd finance; sudo groupadd it
sudo useradd -m -G hr alice
sudo useradd -m -G it bob
sudo useradd -m -G finance carol

sudo mkdir -p /srv/company/{hr,finance,it}
sudo chown root:hr      /srv/company/hr
sudo chown root:finance /srv/company/finance
sudo chown root:it      /srv/company/it
sudo chmod 770 /srv/company/hr /srv/company/finance /srv/company/it
sudo chmod 755 /srv/company

# HR may read (not write) Finance; IT gets full access to HR and Finance, now and for new files.
sudo setfacl    -m g:hr:rx  /srv/company/finance
sudo setfacl    -m g:it:rwx /srv/company/hr /srv/company/finance
sudo setfacl -d -m g:it:rwx /srv/company/hr /srv/company/finance
```

**Verify it worked**

```bash
getfacl -p /srv/company/finance
sudo -u alice ls /srv/company/finance && echo "alice can read finance"
sudo -u carol ls /srv/company/hr; echo "carol->hr exit=$?"
sudo -u bob touch /srv/company/finance/x && echo "bob can write finance"
```

**Expected output:**

```text
# file: /srv/company/finance
# owner: root
# group: finance
user::rwx
group::rwx
group:hr:r-x
group:it:rwx
mask::rwx
other::---
default:user::rwx
default:group::rwx
default:group:it:rwx
default:mask::rwx
default:other::---

alice can read finance
ls: cannot open directory '/srv/company/hr': Permission denied
carol->hr exit=2
bob can write finance
```

(`alice can read finance` is preceded by the directory listing, which is empty at first.)

**Acceptance criteria**

- [ ] Alice (HR) lists Finance but cannot create files there.
- [ ] Carol (Finance) gets `Permission denied` on HR.
- [ ] Bob (IT) can write to both.

**Undo it**

```bash
sudo rm -rf /srv/company
for u in alice bob carol; do sudo userdel -r "$u"; done
for g in hr finance it; do sudo groupdel "$g"; done
```

**Troubleshooting**

- `setfacl: command not found`: install the `acl` package.
- `setfacl: Operation not supported`: the filesystem is mounted without ACL support (rare on ext4/xfs, common on some network or FAT mounts).
- A new group membership "does not work": group changes apply at the next login. Check with `id alice`, and use `sudo -u` (a fresh login) to test.

### Task 1.5: ACLs for one-off access

- **What you will learn:** granting a single user access without changing owner, group or mode, and what the `+` in `ls -l` and the ACL *mask* mean.
- **Target distro:** both.
- **Risk level:** `safe` (use files under `/tmp`).

```bash
echo hello > /tmp/report.txt
chmod 600 /tmp/report.txt
sudo useradd -m bob 2>/dev/null || true       # skip if bob exists from Task 1.4

setfacl -m u:bob:r /tmp/report.txt
getfacl /tmp/report.txt
ls -l /tmp/report.txt
sudo -u bob cat /tmp/report.txt
```

**Verify it worked**

**Expected output** (owner was `alice` in the captured run, yours will be you):

```text
# file: tmp/report.txt
# owner: alice
# group: root
user::rw-
user:bob:r--
group::---
mask::r--
other::---

-rw-r-----+ 1 alice root 6 Oct 17 12:26 /tmp/report.txt
hello
```

Notice that `ls -l` now shows `r--` in the group column: with an ACL that column displays the
**mask**, not the owning group. The trailing `+` tells you an ACL exists.

**Acceptance criteria**

- [ ] Bob can read the file; a third user cannot.
- [ ] The file's mode bits still say `600` for owner, none for others (check with `getfacl`).

**Undo it**

```bash
setfacl -x u:bob /tmp/report.txt     # remove one entry
setfacl -b /tmp/report.txt           # or remove all ACL entries
rm /tmp/report.txt
```

**Troubleshooting**

- Bob still cannot read: check that `/tmp/report.txt`'s parent directory is traversable by Bob (`namei -l /tmp/report.txt`).
- `mask::---` after you changed `chmod`: `chmod` on a file with an ACL changes the mask. Re-run `setfacl -m m::r file`.
- Backups lose ACLs: use `tar --acls` or `rsync -A`.

### Task 1.6: Organise files by extension

- **What you will learn:** globbing, `${var##*.}` parameter expansion, safe moves.
- **Target distro:** both. **Risk level:** `safe` if you test on a copy (the script refuses to overwrite).

```bash
mkdir -p ~/sandbox/inbox && cd ~/sandbox
touch inbox/{a.txt,b.txt,photo.jpg,song.mp3,README}

cat > organize.sh <<'EOF'
#!/usr/bin/env bash
# Move files in DIR into subdirectories named after their extension.
set -euo pipefail
dir="${1:?usage: organize.sh DIR}"
[[ -d "$dir" ]] || { echo "not a directory: $dir" >&2; exit 1; }
for f in "$dir"/*; do
  [[ -f "$f" ]] || continue
  name="${f##*/}"
  if [[ "$name" == *.* ]]; then ext="${name##*.}"; else ext="no-extension"; fi
  mkdir -p -- "$dir/$ext"
  mv -n -- "$f" "$dir/$ext/"
done
EOF
chmod +x organize.sh
./organize.sh inbox
find inbox | sort
```

**Verify it worked.** Expected result:

```text
inbox
inbox/jpg
inbox/jpg/photo.jpg
inbox/mp3
inbox/mp3/song.mp3
inbox/no-extension
inbox/no-extension/README
inbox/txt
inbox/txt/a.txt
inbox/txt/b.txt
```

*Typical output*; this is the layout the script produces (the file list is deterministic).

**Acceptance criteria**

- [ ] Files without an extension go to `no-extension`.
- [ ] Re-running the script does nothing and breaks nothing.
- [ ] `shellcheck organize.sh` is clean.

**Undo it**

```bash
rm -r ~/sandbox
```

**Troubleshooting**

- Filenames with spaces break: you forgot quotes. Always write `"$f"`.
- `mv: not replacing`: `-n` protected a file with the same name. That is the point.
- Glob matches nothing and the loop runs on the literal `*`: the `[[ -f "$f" ]] || continue` line handles this.

---

## Advanced

### Task 1.7: Quotas on a loop-device filesystem

- **What you will learn:** disk quotas for users, using a file-backed ext4 filesystem so you do not need a spare disk.
- **Target distro:** Debian/Ubuntu (`quota` package) and RHEL family (`quota` package; on XFS use `xfs_quota` instead).
- **Risk level:** `destructive` only to the image file you create. Needs root and a VM or privileged container.

> [!WARNING]
> `mkfs` formats whatever device you give it. Check that `$LOOP` is a `/dev/loopN` device before you run it.

```bash
sudo apt install -y quota e2fsprogs         # RHEL family: sudo dnf install -y quota e2fsprogs
mkdir -p ~/lab && cd ~/lab
dd if=/dev/zero of=disk.img bs=1M count=64 status=none
LOOP=$(sudo losetup --find --show disk.img); echo "loop=$LOOP"
sudo mkfs.ext4 -q -L labdisk "$LOOP"
sudo mkdir -p /mnt/labdisk
sudo mount -o usrquota "$LOOP" /mnt/labdisk
df -hT /mnt/labdisk

sudo quotacheck -cu /mnt/labdisk
sudo quotaon /mnt/labdisk
sudo useradd -m dave 2>/dev/null || true
sudo setquota -u dave 10000 12000 0 0 /mnt/labdisk      # soft/hard limits in 1K blocks
sudo repquota -s /mnt/labdisk
```

**Verify it worked**

**Expected output:**

```text
loop=/dev/loop0
Filesystem     Type  Size  Used Avail Use% Mounted on
/dev/loop0     ext4   56M   24K   52M   1% /mnt/labdisk
*** Report for user quotas on device /dev/loop0
Block grace time: 7days; Inode grace time: 7days
                        Space limits                File limits
User            used    soft    hard  grace    used  soft  hard  grace
----------------------------------------------------------------------
root      --     24K      0K      0K              3     0     0
```

`dave` appears in the report once he owns files. Test the limit:

```bash
sudo mkdir /mnt/labdisk/dave && sudo chown dave /mnt/labdisk/dave
sudo -u dave dd if=/dev/zero of=/mnt/labdisk/dave/big bs=1M count=20 || echo "blocked by quota"
```

*Typical output:* `dd: error writing ... Disk quota exceeded`. (I verified quota creation and the
report in a privileged container; I did not capture the over-quota write.)

**Acceptance criteria**

- [ ] `repquota` lists the filesystem with quotas on.
- [ ] A user writing past the hard limit gets "Disk quota exceeded".
- [ ] You have a one-line script that prints `repquota -s` for that mount.

**Undo it**

```bash
sudo quotaoff /mnt/labdisk
sudo umount /mnt/labdisk
sudo losetup -d "$LOOP"
rm ~/lab/disk.img
sudo userdel -r dave
```

**Troubleshooting**

- `quotaon: ... Operation not supported`: the kernel lacks quota support (some cloud and container kernels). Use a VM kernel.
- `target is busy` on `umount`: you have a shell `cd`'d into it. `cd ~` and try again, or find the culprit with `lsof +f -- /mnt/labdisk`.
- On RHEL family with XFS, `quotacheck` does not apply: mount with `-o usrquota` and use `xfs_quota -x -c 'report -h' /mnt/labdisk`.

### Task 1.8: Detect permission changes

- **What you will learn:** baselines and drift detection. You compare the current state with a saved one and alert on any difference. This is the idea behind AIDE, auditd and Wazuh file integrity monitoring.
- **Target distro:** both. **Risk level:** `safe` (read-only `find`).
- **Note:** the original `inotifywait` approach reacts instantly but needs `inotify-tools` and a long-running process. A scheduled comparison is simpler and survives reboots; the `inotifywait` variant is shown after.

```bash
sudo tee /usr/local/bin/perm-watch.sh >/dev/null <<'EOF'
#!/usr/bin/env bash
# Compare file modes under a directory with a stored baseline.
set -euo pipefail
dir="${1:?usage: perm-watch.sh DIR [BASELINE]}"
baseline="${2:-$HOME/.perm-baseline.txt}"
current="$(mktemp)"
trap 'rm -f "$current"' EXIT
find "$dir" -printf '%m %u:%g %p\n' | LC_ALL=C sort -k3 > "$current"
if [[ ! -f "$baseline" ]]; then
  cp -- "$current" "$baseline"
  echo "baseline created: $baseline"
  exit 0
fi
if diff -u -- "$baseline" "$current"; then
  echo "OK: no permission changes under $dir"
else
  echo "ALERT: permissions changed under $dir" >&2
  exit 2
fi
EOF
sudo chmod +x /usr/local/bin/perm-watch.sh

mkdir -p ~/watched && touch ~/watched/f && chmod 640 ~/watched/f
perm-watch.sh ~/watched          # creates the baseline
perm-watch.sh ~/watched          # no change
chmod 777 ~/watched/f
perm-watch.sh ~/watched; echo "exit=$?"
```

**Verify it worked**

**Expected output** (paths differ on your machine):

```text
baseline created: /root/.perm-baseline.txt
OK: no permission changes under /srv/w
--- /root/.perm-baseline.txt 2026-10-17 12:27:24.797013217 +0000
+++ /tmp/tmp.PmKjLrsiQz 2026-10-17 12:27:24.814964231 +0000
@@ -1,2 +1,2 @@
 755 root:root /srv/w
-640 root:root /srv/w/f
+777 root:root /srv/w/f
ALERT: permissions changed under /srv/w
exit=2
```

Schedule it and send the alert to the system log (no mail server needed):

```bash
( crontab -l 2>/dev/null; echo '*/15 * * * * /usr/local/bin/perm-watch.sh "$HOME/watched" || logger -p auth.warning -t perm-watch "permissions changed"' ) | crontab -
```

Real-time variant (needs `sudo apt install -y inotify-tools`; not verified here because
inotify did not work in the container I tested with):

```bash
inotifywait -m -r -e attrib --format '%T %w%f %e' --timefmt '%F %T' ~/watched
```

**Acceptance criteria**

- [ ] The script exits `0` when nothing changed and non-zero when a mode changes.
- [ ] `shellcheck /usr/local/bin/perm-watch.sh` is clean.
- [ ] An alert reaches the journal: `journalctl -t perm-watch`.

**Undo it**

```bash
crontab -l | grep -v perm-watch | crontab -
sudo rm /usr/local/bin/perm-watch.sh ~/.perm-baseline.txt
rm -r ~/watched
```

**Troubleshooting**

- Alert fires every run: log files or caches change in your directory. Watch a config directory such as `/etc/ssh`, not `/var/log`.
- `crontab: command not found`: install `cron` (Debian) or `cronie` (RHEL) and enable it (`systemctl enable --now cron` / `crond`).
- Baseline file is writable by attackers: store it on another host or read-only media for real use.

### Task 1.9: Build a minimal chroot

- **What you will learn:** how a process can be confined to a directory tree, which is the idea behind containers (see [Step 11](step-11-virtualization-and-containers.md)).
- **Target distro:** both. **Risk level:** `can lock you out` of nothing, but `destructive` if you `rm -rf` the wrong path: delete only `$J`.
- **Security note:** `chroot` is **not** a security boundary against root. Use containers or VMs for isolation.

```bash
J=$HOME/jail
mkdir -p "$J"/{bin,lib,lib64,usr/lib}
for b in bash ls cat; do
  cp "/bin/$b" "$J/bin/"
  for lib in $(ldd "/bin/$b" | grep -o '/[^ ]*'); do
    mkdir -p "$J$(dirname "$lib")"
    cp --update=none "$lib" "$J$lib"
  done
done

sudo chroot "$J" /bin/ls /
sudo chroot "$J" /bin/bash -c 'echo inside jail; ls /etc'
```

**Verify it worked**

**Expected output** (the `ls /etc` fails because nothing but your binaries exists inside):

```text
bin
lib
lib64
usr
inside jail
ls: cannot access '/etc': No such file or directory
```

**Acceptance criteria**

- [ ] Commands inside the chroot see only the copied files.
- [ ] You can explain why `ls /etc` fails inside but works outside.

**Undo it**

```bash
rm -r "$HOME/jail"
```

**Troubleshooting**

- `chroot: failed to run command '/bin/bash': No such file or directory`: a library (or the dynamic loader in `lib64`) is missing. Re-run the copy loop and check `ldd /bin/bash`.
- On merged-`/usr` systems `/bin` is a symlink to `/usr/bin`; the loop copies the real binary into `$J/bin`, which is fine.
- Prefer `debootstrap` (Debian/Ubuntu) or `dnf --installroot` (RHEL) for a full chroot once you understand this.

---

## Step checklist

- [ ] 1.1 Directory tree
- [ ] 1.2 chmod symbolic and octal
- [ ] 1.3 First script
- [ ] 1.4 Department directories
- [ ] 1.5 ACLs
- [ ] 1.6 Organise by extension
- [ ] 1.7 Quotas on a loop device
- [ ] 1.8 Permission drift detection
- [ ] 1.9 Minimal chroot

## Further reading

- [The Linux Filesystem Hierarchy Standard](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html): what each top-level directory is for.
- [chmod(1)](https://man7.org/linux/man-pages/man1/chmod.1.html): the authoritative manual page for permission modes.
- [acl(5)](https://man7.org/linux/man-pages/man5/acl.5.html): how POSIX ACLs and the mask work.

**Next:** [Step 2: Users and Groups](step-02-user-and-group-mgmnt.md)
