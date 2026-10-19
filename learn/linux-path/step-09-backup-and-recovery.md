# Step 9: Backup and Recovery

> **Time:** ~8-10 hours · **Level:** Beginner → Advanced
> **Prerequisites:** [Step 1](step-01-linux-fundamentals.md), [Step 5](step-05-package-mgmnt.md) · **Next:** [Step 10: Automation](step-10-automation.md)

<!-- -->

> [!WARNING]
> Backup tasks write to real files and can overwrite data if you point them at the wrong directory. Test every command on copies under `~/lab` or `/tmp` first. Restore tests delete and recreate the restore directory — never restore over your only copy of live data.

Conventions: see [Step 1](step-01-linux-fundamentals.md#how-to-read-each-task). Tasks were run as root in Ubuntu 24.04 and AlmaLinux 9 containers unless marked *typical*. Restic was not installed on the test machines; its commands are from the official documentation and marked.

## Why back up, and the 3-2-1 rule

A backup that has never been restored is not a backup — it is a hope. The **3-2-1 rule** is the practical standard:

- **3** copies of your data: the original plus at least two backups.
- **2** different media: e.g. a local disk and a network/USB location.
- **1** copy off-site: outside your building, or in a different cloud region/zone.

And the corollary: **test the restore**. A backup is only proven when you can restore it and the restored files match the original.

---

## Beginner

### Task 9.1: Copy files with `rsync`

- **What you will learn:** mirror a directory, preserve permissions and timestamps, delete nothing by default, and run a dry-run first.
- **Target distro:** both (`rsync` is in the base on both; install with `sudo apt install -y rsync` / `sudo dnf install -y rsync` if missing).
- **Risk level:** `safe` for the source (rsync only reads it). `destructive` on the destination if you add `--delete` — files absent from the source get removed there.

```bash
mkdir -p ~/lab/src ~/lab/dst
echo "important data" > ~/lab/src/notes.txt
mkdir -p ~/lab/src/sub && echo "nested" > ~/lab/src/sub/deep.txt

# Dry run first: -n shows what would happen without changing anything
rsync -avn ~/lab/src/ ~/lab/dst/

# For real: archive mode, verbose, human-readable
rsync -avh ~/lab/src/ ~/lab/dst/
```

Note the trailing slashes: `~/lab/src/` copies *contents* into `~/lab/dst/`; `~/lab/src` (no slash) copies the directory itself as `~/lab/dst/src`.

**Verify it worked**

```bash
find ~/lab/dst -type f | sort
diff -r ~/lab/src ~/lab/dst && echo "trees match"
```

**Expected output:**

```text
/home/<you>/lab/dst/notes.txt
/home/<you>/lab/dst/sub/deep.txt
trees match
```

**Acceptance criteria:**

- [ ] `~/lab/dst` contains `notes.txt` and `sub/deep.txt`.
- [ ] `diff -r` reports no differences.

**Undo it**

```bash
rm -r ~/lab/src ~/lab/dst
```

**Troubleshooting:**

- `rsync: command not found`: install the `rsync` package.
- Permission denied reading the source: run as a user that owns the files, or use `sudo` (and `--rsync-path="sudo rsync"` on the remote side for remote copies).
- Files reappear in `dst` after you delete them there: you did not use `--delete`; rsync only copies *new or changed* files by default.

### Task 9.2: Compressed archive with `tar` and verification

- **What you will learn:** create a `.tar.gz`, verify it with `sha256sum`, list its contents without extracting, and test-extract to a separate directory.
- **Target distro:** both (`tar` is built in on Debian/Ubuntu and RHEL family).
- **Risk level:** `safe` (reads source, writes only where you tell it).

```bash
mkdir -p ~/lab/src && echo "keep this safe" > ~/lab/src/important.txt

# Keep the archive name in a variable: a glob such as backup-*.tar.gz is NOT
# expanded inside a redirect target or an assignment, so name it once and reuse it.
archive=~/lab/backup-$(date +%Y%m%d-%H%M%S).tar.gz
tar -czf "$archive" -C ~/lab src
ls -lh "$archive"

# Verify the archive's integrity without extracting
tar -tzf "$archive"

# Checksum for long-term integrity
sha256sum "$archive" > "$archive.sha256"
sha256sum -c "$archive.sha256"
```

Expected output of the listing and the checksum check (the file name contains your timestamp):

```text
src/
src/important.txt
/home/<you>/lab/backup-<timestamp>.tar.gz: OK
```

Keep using the same terminal: the later commands reuse `$archive`.

**Verify it worked**

```bash
rm -rf ~/lab/restore && mkdir ~/lab/restore
tar -xzf "$archive" -C ~/lab/restore
diff -r ~/lab/src ~/lab/restore/src && echo "restore matches"
```

**Expected output:**

```text
restore matches
```

**Acceptance criteria:**

- [ ] `tar -tzf` lists the archived files.
- [ ] `sha256sum -c` reports OK.
- [ ] `diff -r` between original and restored tree is clean.

**Undo it**

```bash
rm -r ~/lab/src ~/lab/backup-*.tar.gz ~/lab/backup-*.tar.gz.sha256 ~/lab/restore
```

**Troubleshooting:**

- `tar: ...: Cannot open: No such file or directory`: the path is wrong; run from the right directory or use an absolute path with `-C`.
- Checksum fails: the archive changed after you created it (re-run `tar`, then re-create the checksum).
- Archive is huge: exclude logs/cache with `--exclude='*.log' --exclude='__pycache__'`.

### Task 9.3: Encrypted, deduplicated backup with `restic`

- **What you will learn:** initialize a repository, back up a directory, list snapshots, and restore. Restic encrypts and deduplicates, so repeated backups only store changed data.
- **Target distro:** both. Install restic from the official site or `sudo apt install -y restic` / `sudo dnf install -y restic` (EPEL on RHEL). *Not run on the test machines; commands are from the [restic documentation](https://restic.readthedocs.io/).*
- **Risk level:** `safe` (reads source, writes to the repo you choose). Losing the repository password means losing the backups — store it in a password manager.

```bash
export RESTIC_REPOSITORY=~/lab/restic-repo
export RESTIC_PASSWORD="change-me-in-a-password-manager"
restic init
restic backup ~/lab/src
restic snapshots
```

**Verify it worked**

```bash
restic snapshots --latest 1
rm -rf ~/lab/restic-restore && mkdir ~/lab/restic-restore
restic restore latest --target ~/lab/restic-restore
# restic recreates the ORIGINAL absolute path under the target directory
diff -r ~/lab/src "$HOME/lab/restic-restore$HOME/lab/src" && echo "restic restore matches"
```

*Typical output:* `restic snapshots` lists a snapshot with a short ID, the time, and the backed-up paths; `diff -r` prints nothing and `restore matches` appears.

**Acceptance criteria:**

- [ ] `restic snapshots` shows at least one snapshot.
- [ ] `restic restore latest` recreates the files.
- [ ] `diff -r` between original and restored tree is clean.

**Undo it**

```bash
unset RESTIC_REPOSITORY RESTIC_PASSWORD
rm -r ~/lab/restic-repo ~/lab/src ~/lab/restic-restore
```

**Troubleshooting:**

- `repository does not exist`: run `restic init` first, or point `RESTIC_REPOSITORY` at an existing repo.
- `incorrect password`: you changed or forgot `RESTIC_PASSWORD`; there is no recovery without it.
- Forgot the password: the data is unrecoverable — this is why the password lives in a password manager, not in a script.

> (Restic's main alternative is **Borg** (`borg create`, `borg extract`), which also deduplicates and encrypts. Pick one tool and learn it well; do not mix them for the same backup set.)

### Task 9.4: Snapshots (LVM or filesystem)

- **What you will learn:** take a point-in-time snapshot so you can back up a live, changing filesystem without stopping applications.
- **Target distro:** both. LVM (`lvm2`) on either; XFS/Btrfs snapshots on RHEL family; Btrfs on Ubuntu if you formatted with Btrfs.
- **Risk level:** `destructive` only to the snapshot volume you create. Needs root and a real or loopback block device. *Typical output: not run in containers, which lack device-mapper.*

Set up a loopback device (no real disk touched):

```bash
sudo apt install -y lvm2        # RHEL: sudo dnf install -y lvm2
truncate -s 2G ~/lab/disk.img
LOOP=$(sudo losetup -f --show ~/lab/disk.img); echo "loop=$LOOP"
sudo pvcreate "$LOOP"
sudo vgcreate labvg "$LOOP"
sudo lvcreate -L 1G -n labvol labvg
sudo mkfs.ext4 -q "$LOOP"  # replaced below
sudo mkfs.ext4 -q /dev/labvg/labvol
sudo mkdir -p /mnt/labvol
sudo mount /dev/labvg/labvol /mnt/labvol
echo "live data" | sudo tee /mnt/labvol/data.txt
```

Take a snapshot:

```bash
sudo lvcreate -L 500M -s -n labvol-snap /dev/labvg/labvol
sudo mkdir -p /mnt/snap
sudo mount -o ro /dev/labvg/labvol-snap /mnt/snap
cat /mnt/snap/data.txt
```

**Verify it worked:** `/mnt/snap/data.txt` prints `live data` even after you change or delete `/mnt/labvol/data.txt`.

**Acceptance criteria:**

- [ ] `lvs` shows `labvol-snap`.
- [ ] The snapshot contains the file as it was at snapshot time.

**Undo it**

```bash
sudo umount /mnt/snap /mnt/labvol 2>/dev/null
sudo lvremove -f /dev/labvg/labvol-snap
sudo lvremove -f /dev/labvg/labvol
sudo vgremove -f labvg
sudo pvremove -f "$LOOP"
sudo losetup -d "$LOOP"
rm ~/lab/disk.img
```

**Troubleshooting:**

- `snapshot is not activated`: the origin volume needs free space in the volume group for copy-on-write.
- `device-mapper` errors: you are in a container without device-mapper; use a VM for LVM tasks.
- Running out of snapshot space: monitor with `lvs`; a full snapshot becomes invalid and must be removed.

### Task 9.5: Schedule backups — cron vs systemd timers

- **What you will learn:** run `rsync` daily with cron, and the same job as a systemd timer; know when to use each.
- **Target distro:** both. cron service: `cron` (Debian/Ubuntu) / `crond` (RHEL). systemd timers work on both.
- **Risk level:** `safe` (the job only reads source and writes destination).

**cron version:**

```bash
# Edit your user's crontab
crontab -l 2>/dev/null; echo '---'
(crontab -l 2>/dev/null; echo '0 2 * * * /usr/bin/rsync -a --delete ~/src/ ~/dst/') | crontab -
crontab -l | grep rsync
```

**systemd timer version** (preferred on modern systems; integrates with journald and can run as your user):

```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/backup.service <<'EOF'
[Unit]
Description=Daily rsync backup

[Service]
Type=oneshot
ExecStart=/usr/bin/rsync -a --delete ~/src/ ~/dst/
EOF

cat > ~/.config/systemd/user/backup.timer <<'EOF'
[Unit]
Description=Run backup.service daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now backup.timer
systemctl --user list-timers --all | grep backup
```

**Verify it worked:**

- cron: `crontab -l` shows the line; check `/var/log/syslog` or `/var/log/cron` after the next run.
- timer: `systemctl --user list-timers` shows `backup.timer` and the next run time; `journalctl --user -u backup.service` shows the last run.

**Acceptance criteria:**

- [ ] The schedule is installed (`crontab -l` or `list-timers` shows it).
- [ ] Running the backup command by hand reproduces the destination tree.

**Undo it**

```bash
crontab -l | grep -v rsync | crontab -
systemctl --user disable --now backup.timer
rm ~/.config/systemd/user/backup.service ~/.config/systemd/user/backup.timer
systemctl --user daemon-reload
```

**Troubleshooting:**

- cron job never runs: the cron service is not enabled (`systemctl enable --now cron` / `crond`), or `PATH` in cron is too small — use absolute paths like `/usr/bin/rsync`.
- Timer fails: `journalctl --user -u backup.service` shows why; common cause is a relative path in `ExecStart`.
- "backup deleted my files": you used `--delete` and pointed `dst` at the wrong directory. Always dry-run first (`rsync -avn`).

### Task 9.6: Apply the 3-2-1 rule

- **What you will learn:** place backups on two media and keep one off-site; document where each copy lives.
- **Target distro:** both.
- **Risk level:** `safe` (planning step; no data moved unless you do it).

Keep these three copies:

1. **Original** — the live data on your server.
2. **Local backup** — a second disk or a network share in the same building (`rsync` to `/mnt/backups/local`).
3. **Off-site backup** — the same data copied to a different location: a USB drive you take elsewhere, another cloud region, or a friend's server (`rsync` over SSH, or restic to an S3-compatible bucket).

Write it down:

```text
Data:        /home/alice/projects
Copy 1:      live (original)
Copy 2:      /mnt/backups/local/projects   (external USB, updated nightly by cron)
Copy 3:      alice@offsite:/backups/projects  (rsync over SSH weekly; key-only login)
Last restore test: 2026-10-17, passed
```

**Verify it worked.** Save the plan to a file and check it names three copies (captured; the
reachability lines further down need your real local and off-site paths):

```bash
cat > ~/lab/3-2-1-plan.txt <<'EOF'
Copy 1 (live):     /home/alice/projects
Copy 2 (local):    /mnt/backups/local/projects
Copy 3 (off-site): alice@offsite:/backups/projects
Last restore test: 2026-10-17, passed
EOF
cat ~/lab/3-2-1-plan.txt
grep -c '^Copy ' ~/lab/3-2-1-plan.txt          # expect 3 distinct copies
```

*Captured output:*

```text
Copy 1 (live):     /home/alice/projects
Copy 2 (local):    /mnt/backups/local/projects
Copy 3 (off-site): alice@offsite:/backups/projects
Last restore test: 2026-10-17, passed
3
```

On your server, also confirm each copy really exists (typical output):

```bash
[ -d /mnt/backups/local/projects ] && echo "Copy 2 present" || echo "Copy 2 MISSING"
ssh -o BatchMode=yes alice@offsite 'test -d /backups/projects && echo "Copy 3 reachable"'
sudo tail -n 1 /var/log/restore-tests.log      # the last restore test recorded in Task 9.7
```

*Typical output:*

```text
Copy 2 present
Copy 3 reachable
RESTORE TEST PASSED: Sun Oct 18 21:46:34 UTC 2026
```

**Acceptance criteria:**

- [ ] You can name all three copies and where each lives.
- [ ] One copy is off-site (not in the same building/region).
- [ ] You know the date of the last successful restore test.

**Undo it:** none (documentation).

**Troubleshooting:**

- All copies on one machine: a fire or theft loses everything. Move copy 3 elsewhere.
- Off-site copy not tested: restore from it at least once a quarter.

### Task 9.7: Mandatory restore test (acceptance criteria)

- **What you will learn:** prove a backup works by restoring it to an empty directory and comparing; record the result.
- **Target distro:** both.
- **Risk level:** `safe` (restore into a fresh directory under `/tmp`, never over live data).

Save this as a script file rather than pasting it: it runs under `set -euo pipefail` and calls
`exit 1` on failure, which would close an interactive shell if the lines were typed or pasted
directly. Writing it into `~/lab/restore-test.sh` and running it with `bash` keeps your shell open
and makes the test repeatable.

```bash
cat > ~/lab/restore-test.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
src=~/lab/src
# Newest archive from Task 9.2 (timestamped names sort oldest to newest), or set your own path.
# Do not write archive=~/lab/backup-*.tar.gz: a glob is not expanded in an assignment.
archive=$(printf '%s\n' ~/lab/backup-*.tar.gz | sort | tail -n 1)
[ -f "$archive" ] || { echo "No archive found: complete Task 9.2 first" >&2; exit 1; }
rm -rf /tmp/restore-test && mkdir /tmp/restore-test
tar -xzf "$archive" -C /tmp/restore-test
if diff -r -- "$src" "/tmp/restore-test/src"; then
  echo "RESTORE TEST PASSED: $(date)" | sudo tee -a /var/log/restore-tests.log
else
  echo "RESTORE TEST FAILED: $(date)" | sudo tee -a /var/log/restore-tests.log >&2
  exit 1
fi
EOF
```

Run it:

```bash
bash ~/lab/restore-test.sh
```

**Verify it worked:** `/var/log/restore-tests.log` contains a `RESTORE TEST PASSED` line with today's date, and `diff -r` printed no differences.

**Acceptance criteria (all must pass):**

- [ ] The restore target was an empty directory (not your live data).
- [ ] `diff -r` between the original and restored trees reports no differences.
- [ ] `sha256sum -c` on the archive passed before restoring.
- [ ] The result (pass/fail + date) is written to a log you can show a teammate or auditor.

- [ ] `bash ~/lab/restore-test.sh` prints `RESTORE TEST PASSED` and exits 0.

**Undo it:** `rm -rf /tmp/restore-test ~/lab/restore-test.sh` (the log at `/var/log/restore-tests.log`
is the evidence — keep it, or `sudo rm /var/log/restore-tests.log` to remove it too).

**Troubleshooting:**

- Restore fails: the archive is corrupt (`sha256sum -c` would have caught it) or the backup was incomplete — re-run the backup and re-test.
- Restored files differ: something changed in the source between backup and restore; re-backup and re-test.
- No log permission: write to `~/restore-tests.log` if `/var/log` is not writable.

---

## Step checklist

- [ ] 9.1 rsync copy (dry run, then real)
- [ ] 9.2 tar archive + sha256 + restore compare
- [ ] 9.3 restic backup, snapshot, and restore
- [ ] 9.4 LVM snapshot on a loopback device
- [ ] 9.5 cron and systemd-timer backup schedules
- [ ] 9.6 3-2-1 rule written down with locations
- [ ] 9.7 Restore test passed and logged

## Further reading

- [rsync(1)](https://man7.org/linux/man-pages/man1/rsync.1.html): the full rsync option reference (`-a`, `--delete`, `--exclude`).
- [restic documentation](https://restic.readthedocs.io/): encrypted, deduplicated backups and the snapshot/restore model.
- [LVM HOWTO](https://www.tldp.org/HOWTO/LVM-HOWTO/): volume groups, logical volumes, and snapshots.
- [3-2-1 backup rule](https://en.wikipedia.org/wiki/Backup#3-2-1_rule): the origin and rationale of the 3-2-1 rule (three copies, two media, one off-site).

**Next:** [Step 10: Automation](step-10-automation.md)
