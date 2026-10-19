# Step 8: Disk Management

> **Time:** ~10-12 hours · **Level:** Beginner → Advanced
> **Prerequisites:** [Step 1](step-01-linux-fundamentals.md) · **Next:** [Step 9: Backup and Recovery](step-09-backup-and-recovery.md)

<!-- -->

> [!WARNING]
> Disk commands are **destructive**: `fdisk`, `mkfs`, `mdadm --create`, `pvcreate` and `cryptsetup luksFormat`
> erase whatever is on the target. Do this in a throwaway VM or the devcontainer, never on a machine you
> cannot afford to lose. **This step uses loop devices (files that act as disks), so no real disk is touched.**
> Before every command that takes a device, run `lsblk` and read the name twice. Keep a second SSH session
> open: a bad `/etc/fstab` line can stop a server booting.

Conventions: see [Step 1](step-01-linux-fundamentals.md#how-to-read-each-task).
Tasks 8.1-8.3 and 8.5-8.6 were run as root in a privileged Ubuntu 24.04 container with loop devices. A container shares the
host kernel and `udev`, so LVM needed extra flags there (marked); on a normal VM you do **not** need them.

## Set up practice disks

```bash
cd ~ && for i in 1 2 3; do dd if=/dev/zero of=disk$i.img bs=1M count=128 status=none; done
sudo losetup -f --show disk1.img      # prints /dev/loopN: note it
sudo losetup -f --show disk2.img
sudo losetup -f --show disk3.img
lsblk -f | grep loop
```

Use the printed names below as `$L1 $L2 $L3` (e.g. `L1=/dev/loop2`). Remove them at the end with `sudo losetup -D`.
Packages: `sudo apt install -y fdisk parted e2fsprogs xfsprogs mdadm lvm2 cryptsetup rsync`
(RHEL: `sudo dnf install -y util-linux parted e2fsprogs xfsprogs mdadm lvm2 cryptsetup rsync`).

---

## Beginner

### Task 8.1: Partition, format, mount and persist

- **What you will learn:** GPT partition tables, filesystems (ext4 vs XFS), mounting by **UUID**, `/etc/fstab` options, and testing fstab before a reboot.
- **Target distro:** both. RHEL defaults to XFS (can grow, cannot shrink); Debian/Ubuntu default to ext4.
- **Risk level:** `destructive`.

```bash
L1=/dev/loop2                                   # your loop device from above
printf 'label: gpt\n,64M,L\n' | sudo sfdisk $L1  # scriptable; fdisk $L1 does the same interactively (n, w)
sudo sfdisk -l $L1
sudo losetup -d $L1 && L1=$(sudo losetup -f --show -P ~/disk1.img)    # re-read the table (-P scans partitions)
sudo mkfs.ext4 -L labfs ${L1}p1                 # XFS: sudo mkfs.xfs -L labfs ${L1}p1
blkid ${L1}p1
sudo mkdir -p /mnt/labfs
UUID=$(sudo blkid -s UUID -o value ${L1}p1)
echo "UUID=$UUID /mnt/labfs ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
sudo findmnt --verify
sudo mount -a && df -hT /mnt/labfs
```

**Verify it worked.** Captured (sfdisk, mkfs and blkid; the mount step is the standard one):

```text
Device       Start    End Sectors Size Type
/dev/loop2p1  2048 133119  131072  64M Linux filesystem
mkfs-ext4-ok
/dev/loop2p1: UUID="eb537d09-f9c6-4612-9875-3d0f387fee17" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="93ee77e5-bfa2-4c00-ba0a-2fd9a7356796"
```

`findmnt --verify` prints `0 parse errors, 0 errors, 0 warnings` for a good file. (In my container test it reported
`[E] unreachable on boot required target: No such file or directory` for a mount point I had not created: a useful
demonstration that this check catches mistakes before a reboot.)

**Acceptance criteria**

- [ ] `lsblk -f` shows the partition with a filesystem and mount point.
- [ ] The fstab line uses UUID, `nofail` (non-system disks), and `findmnt --verify` is clean.
- [ ] After `sudo umount /mnt/labfs && sudo mount -a` it mounts again.

**Undo it**

```bash
sudo umount /mnt/labfs
sudo sed -i '/labfs/d' /etc/fstab        # remove YOUR line only; check with: grep labfs /etc/fstab
sudo losetup -D
```

**Troubleshooting**

- Boot drops to emergency mode after a bad fstab: add `nofail`, or boot rescue and fix the file. Always run `findmnt --verify` first.
- `mount: wrong fs type, bad option, bad superblock`: wrong filesystem type in fstab or no filesystem on the device.
- `/dev/loop2p1` does not exist: the table was not re-read. Re-attach with `losetup -P` or run `sudo partprobe`.

### Task 8.2: RAID 1 with `mdadm`

- **What you will learn:** mirroring, reading `/proc/mdstat`, and the failure drill (fail, remove, add, resync). RAID is **availability, not backup**: deleted files are deleted on both disks.
- **Target distro:** both. **Risk level:** `destructive` to the member devices.

```bash
sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 --run $L1 $L2
cat /proc/mdstat
sudo mdadm --detail /dev/md0 | grep -E 'State :|Raid Level|Active Devices'
# failure drill
sudo mdadm /dev/md0 --fail $L2
sudo mdadm /dev/md0 --remove $L2
sudo mdadm /dev/md0 --add $L2
cat /proc/mdstat
```

Persist the array definition: `sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf` (RHEL: `/etc/mdadm.conf`), then `sudo update-initramfs -u` (Debian) or `sudo dracut -f` (RHEL).

**Verify it worked.** Captured:

```text
mdadm: array /dev/md0 started.
md0 : active raid1 loop3[1] loop2[0]
      130048 blocks super 1.2 [2/2] [UU]
      [>....................]  resync =  0.7% (1024/130048) finish=2.0min speed=1024K/sec
        Raid Level : raid1
             State : clean, resyncing 
    Active Devices : 2
mdadm: set /dev/loop3 faulty in /dev/md0
mdadm: hot removed /dev/loop3 from /dev/md0
mdadm: added /dev/loop3
md0 : active raid1 loop3[2] loop2[0]
      130048 blocks super 1.2 [2/2] [UU]
```

`[UU]` means both members are up; `[U_]` is a degraded array.

**Acceptance criteria**

- [ ] The array shows `[UU]` after the re-add and resync.
- [ ] You can read a degraded state and name the failed device.
- [ ] You can explain why RAID does not replace backups.

**Undo it**

```bash
sudo umount /dev/md0 2>/dev/null; sudo mdadm --stop /dev/md0
sudo mdadm --zero-superblock $L1 $L2
```

**Troubleshooting**

- `mdadm: Cannot get exclusive access`: the device is mounted or used by LVM.
- Array comes back as `md127` after reboot: it is not in `mdadm.conf` or the initramfs is stale.
- Email alerts: set `MAILADDR` in `mdadm.conf` and enable `mdmonitor`.

### Task 8.3: LVM: grow storage online

- **What you will learn:** physical volumes, volume groups and logical volumes; extending a filesystem while mounted.
- **Target distro:** both (RHEL installs on LVM by default). **Risk level:** `destructive` to the disks you initialise; shrinking a logical volume can destroy data, take a backup first and prefer growing.

> [!NOTE]
> In my **container** test these LVM commands needed `--noudevsync -Zn -Wn` on `lvcreate` because the container has no `udev`.
> You do not need them on a VM. Without them LVM aborted with `Failed to wipe start of new LV`.

```bash
sudo pvcreate $L1 $L2
sudo vgcreate labvg $L1 $L2
sudo lvcreate -n data -L 100M labvg
lvs
sudo mkfs.ext4 /dev/labvg/data
sudo mkdir -p /mnt/data && sudo mount /dev/labvg/data /mnt/data
sudo lvextend -L +50M -r /dev/labvg/data       # -r resizes the filesystem too
df -h /mnt/data
```

Shrink (ext4 only, offline; XFS cannot shrink): `sudo umount /mnt/data && sudo e2fsck -f /dev/labvg/data && sudo lvreduce -r -L 80M /dev/labvg/data`.

**Verify it worked.** Captured (container):

```text
Logical volume "data" created.
  data labvg 100.00m
mounted
/dev/mapper/labvg-data  136M   24K  128M   1% /mnt/data
```

(`lvs` shows the 100 MiB LV; after the +50M extend the filesystem reports about 128M available.)

**Acceptance criteria**

- [ ] The LV grew to 150 MiB with the filesystem mounted and in use.
- [ ] You can name the three layers (PV, VG, LV) and the command for each.
- [ ] `vgs` shows free space you could still allocate.

**Undo it**

```bash
sudo umount /mnt/data
sudo lvremove -f labvg/data && sudo vgremove -f labvg && sudo pvremove -f $L1 $L2
```

**Troubleshooting**

- `Cannot use /dev/loopN: device is partitioned`: the device has a partition table; wipe it (`sudo wipefs -a`) or use the partition.
- `Insufficient free space`: add a PV with `vgextend`.
- Filesystem did not grow: you forgot `-r`; run `sudo resize2fs /dev/labvg/data` (ext4) or `sudo xfs_growfs /mnt/data` (XFS).

---

## Intermediate

### Task 8.4: RAID 5 and RAID 10, with a failure drill

- **What you will learn:** parity RAID (survives 1 disk), RAID 10 (mirrors striped: faster, 50% capacity), rebuild behaviour.
- **Target distro:** both. **Risk level:** `destructive`.

```bash
sudo mdadm --create /dev/md1 --level=5 --raid-devices=3 --run $L1 $L2 $L3     # RAID 10 needs 4 devices: --level=10
sudo mkfs.ext4 /dev/md1 && sudo mkdir -p /mnt/data && sudo mount /dev/md1 /mnt/data
seq 1 1000 | sudo tee /mnt/data/n.txt >/dev/null; md5sum /mnt/data/n.txt
sudo mdadm /dev/md1 --fail $L2
cat /proc/mdstat
md5sum /mnt/data/n.txt                     # still identical: the array runs degraded
sudo mdadm /dev/md1 --remove $L2 && sudo mdadm /dev/md1 --add $L2
sudo mdadm --wait /dev/md1; cat /proc/mdstat
```

**Verify it worked.** Captured (array creation and failure drill; the checksum steps need the filesystem and
were not reached in my run because I forgot to create the mount point, so treat the checksum comparison as *typical*):

```text
md1 : active raid5 loop5[3] loop4[1] loop3[0]
      258048 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/3] [UUU]
mdadm: set /dev/loop4 faulty in /dev/md1
md1 : active raid5 loop5[3] loop4[1](F) loop3[0]
      258048 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/2] [U_U]
mdadm: hot removed /dev/loop4 from /dev/md1
mdadm: added /dev/loop4
md1 : active raid5 loop4[4] loop5[3] loop3[0]
      258048 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/3] [UUU]
```

**Acceptance criteria**

- [ ] The checksum is the same before failure, during degraded operation and after rebuild.
- [ ] You can state the usable capacity: RAID 5 = (N-1) disks, RAID 10 = N/2.
- [ ] You know large-disk RAID 5 rebuilds are risky (second failure during rebuild); prefer RAID 6 or 10 for big disks.

**Undo it:** `sudo umount /mnt/data; sudo mdadm --stop /dev/md1; sudo mdadm --zero-superblock $L1 $L2 $L3`

**Troubleshooting**

- Rebuild is slow: `cat /proc/sys/dev/raid/speed_limit_min` and raise it temporarily.
- `mdadm: failed to add`: the replacement is smaller than the original.
- Hot spare: `--add` after creation adds a spare automatically used on failure.

### Task 8.5: LVM snapshots for consistent backups

- **What you will learn:** a snapshot freezes a point-in-time view using copy-on-write, so you can back up a consistent copy while the original keeps changing.
- **Target distro:** both (thin pools are the modern alternative for many snapshots). **Risk level:** `can lock you out` of writes: when the snapshot's space fills, the snapshot is invalidated. Size it for the expected changes, and delete it after the backup.

```bash
echo important | sudo tee /mnt/data/file.txt
sudo lvcreate -s -n snap -L 40M labvg/data
lvs -o lv_name,origin,lv_size labvg
echo changed | sudo tee /mnt/data/file.txt
sudo mkdir -p /mnt/snap && sudo mount -o ro /dev/labvg/snap /mnt/snap     # XFS: add -o nouuid
cat /mnt/snap/file.txt                                                     # important
sudo rsync -a /mnt/snap/ /backup/data-$(date +%F)/                         # back up the frozen view
sudo umount /mnt/snap && sudo lvremove -f labvg/snap
```

**Verify it worked.** *Typical output* (the snapshot command did not complete in my container because of the `udev` limits
described in Task 8.3, so this was not captured): `lvs` lists `snap` with origin `data`; the mounted snapshot prints
`important` while the live file prints `changed`.

**Acceptance criteria**

- [ ] The snapshot shows the old content while the live volume shows the new.
- [ ] The backup is restored to another directory and compared (`diff -r`).
- [ ] The snapshot is removed afterwards; `lvs` shows its usage (`Snap%`) never reaches 100.

**Undo it:** `sudo umount /mnt/snap; sudo lvremove -f labvg/snap`

**Troubleshooting**

- `Snapshot ... is invalid`: it ran out of space; make it larger.
- XFS `wrong fs type / duplicate UUID`: mount with `-o nouuid`.
- Database consistency: flush or lock tables first (`FLUSH TABLES WITH READ LOCK`), or use the database's own backup tool.

### Task 8.6: Encrypt a disk with LUKS

- **What you will learn:** LUKS2 headers, passphrases, opening a mapped device, and why the header backup matters. Encryption protects data at rest (stolen disk), not a running, unlocked system.
- **Target distro:** both. **Risk level:** `destructive`: `luksFormat` erases the device. **Losing the passphrase or the LUKS header means losing the data permanently.**

```bash
echo -n "lab-passphrase" | sudo cryptsetup luksFormat --batch-mode --type luks2 $L1 -     # lab passphrase only
echo -n "lab-passphrase" | sudo cryptsetup open $L1 labcrypt -
sudo cryptsetup status labcrypt
sudo mkfs.ext4 /dev/mapper/labcrypt
sudo mkdir -p /mnt/data && sudo mount /dev/mapper/labcrypt /mnt/data
echo secret | sudo tee /mnt/data/s.txt
sudo umount /mnt/data && sudo cryptsetup close labcrypt
sudo cryptsetup luksHeaderBackup $L1 --header-backup-file ~/luks-header.img
```

In real use, omit the pipe so `cryptsetup` prompts for the passphrase, and add a second key slot (`cryptsetup luksAddKey`).
Unlock at boot via `/etc/crypttab`: `labcrypt UUID=... none luks`. For unattended servers use TPM2 or network-bound
(Tang/Clevis) unlocking rather than a key file on the same disk.

**Verify it worked.** Captured (I used `--pbkdf pbkdf2` in the container to fit its memory limits; you can omit it):

```text
/dev/mapper/labcrypt is active.
  type:    LUKS2
  cipher:  aes-xts-plain64
  keysize: 512 bits
is LUKS
LUKS header information
Version:        2
```

**Acceptance criteria**

- [ ] The raw device shows no readable data (`sudo strings $L1 | grep secret` finds nothing).
- [ ] Opening with the wrong passphrase fails.
- [ ] The header backup is stored **off** the machine, protected.

**Undo it:** `sudo cryptsetup close labcrypt; sudo wipefs -a $L1; shred -u ~/luks-header.img`

**Troubleshooting**

- `Device labcrypt already exists`: it is still open; `cryptsetup close` first.
- `Not enough available memory to open a keyslot`: low-RAM VM; LUKS2 default PBKDF (argon2) needs memory.
- Boot waits forever for a passphrase: use `nofail` in fstab and `noauto` in crypttab for data disks.

---

## Advanced

### Task 8.7: Software-defined storage with Ceph

- **What you will learn:** a distributed storage cluster: monitors, OSDs (one per disk) and pools with replicas. Understand the model first, then deploy.
- **Target distro:** any with `cephadm` (container-based). **Risk level:** `destructive` to all disks you give Ceph. Needs at least 3 nodes with 4 GB RAM each for real behaviour; a single-node lab uses `--single-host-defaults`.
- *I did not run this task. All output below is typical.*

```bash
curl -sLO https://download.ceph.com/rpm-reef/el9/noarch/cephadm      # review it, then: chmod +x cephadm
sudo ./cephadm bootstrap --mon-ip 192.168.50.11 --single-host-defaults
sudo ./cephadm shell -- ceph orch daemon add osd node1:/dev/sdb        # destroys /dev/sdb
sudo ./cephadm shell -- ceph status
sudo ./cephadm shell -- ceph osd pool create labpool 32
```

*Typical output*: `health: HEALTH_OK` (or `HEALTH_WARN` with a single OSD/replica), `osd: 3 osds: 3 up, 3 in`.
Failure drill: stop an OSD (`ceph orch daemon stop osd.1`), watch `ceph -s` go `HEALTH_WARN` with degraded PGs, then restart it.

**Verify it worked.** Query the cluster from any node (typical output — needs a running Ceph cluster):

```bash
sudo ./cephadm shell -- ceph -s
sudo ./cephadm shell -- ceph osd tree
sudo ./cephadm shell -- ceph osd pool ls detail
```

*Typical output:*

```text
  cluster:
    id:     a1b2c3d4-0000-0000-0000-000000000000
    health: HEALTH_OK
  services:
    mon: 1 daemons, quorum node1
    osd: 3 osds: 3 up, 3 in
  data:
    pools:   2 pools, 33 pgs
    objects: 21 objects, 8.0 KiB
    usage:   3.0 GiB used, 27 GiB / 30 GiB avail

ID CLASS WEIGHT  TYPE NAME      STATUS REWEIGHT PRI-AFF
-1       0.0900 root default
-3       0.0900     host node1
 0   hdd 0.0300         osd.0      up  1.00000 1.00000
 1   hdd 0.0300         osd.1      up  1.00000 1.00000
 2   hdd 0.0300         osd.2      up  1.00000 1.00000

pool 2 'labpool' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 ...
```

`health: HEALTH_OK`, all three OSDs `up` and `in`, and `labpool` with `size 3 min_size 2` are the
signs the cluster is healthy. During the failure drill `ceph -s` drops to `HEALTH_WARN` with
`1 osds down` and active+degraded placement groups, then returns to `HEALTH_OK` after the OSD restarts.

**Acceptance criteria**

- [ ] You can explain pools, placement groups and replicas (size 3, min_size 2).
- [ ] Losing one OSD or node keeps data available.
- [ ] You know when not to use Ceph (small setups: NFS, ZFS or LVM are simpler).

**Undo it:** `sudo ./cephadm rm-cluster --force --zap-osds --fsid $(ceph fsid)`

**Troubleshooting**

- `HEALTH_WARN clock skew`: install and sync `chrony` on all nodes.
- OSD not created: the disk has a partition table or LVM data; wipe with `ceph-volume lvm zap`.
- Bootstrap fails pulling images: check outbound HTTPS to the image registry.

### Task 8.8: Automate provisioning (with a dry-run default)

- **What you will learn:** a script that finds an unused disk and turns it into an LVM-backed, mounted, fstab-registered filesystem, but only after you confirm. Safety design: dry-run by default, refuse disks with signatures, refuse disks that are mounted.
- **Target distro:** both. **Risk level:** `destructive` when run with `--apply`. Use loop devices first.
- *Not run end-to-end; written for review and shellcheck.*

```bash
sudo tee /usr/local/sbin/provision-disk.sh >/dev/null <<'EOF'
#!/usr/bin/env bash
# Usage: provision-disk.sh DEVICE VG LV MOUNTPOINT [--apply]
# Turns an EMPTY disk into VG/LV, formats ext4 and mounts it. Dry-run unless --apply.
set -euo pipefail
dev="${1:?usage: provision-disk.sh DEVICE VG LV MOUNTPOINT [--apply]}"
vg="${2:?vg}"; lv="${3:?lv}"; mnt="${4:?mountpoint}"; apply="${5:-}"

[[ $EUID -eq 0 ]] || { echo "run as root" >&2; exit 1; }
[[ -b "$dev" ]] || { echo "not a block device: $dev" >&2; exit 1; }
if lsblk -nr -o MOUNTPOINT "$dev" | grep -q .; then echo "refusing: $dev or its partitions are mounted" >&2; exit 1; fi
if [[ -n "$(blkid -p "$dev" 2>/dev/null)" ]] || [[ -n "$(lsblk -nr -o FSTYPE "$dev" | tr -d '[:space:]')" ]]; then
  echo "refusing: $dev already has a signature (use wipefs manually if you are sure)" >&2; exit 1
fi

run() { if [[ "$apply" == "--apply" ]]; then echo "+ $*"; "$@"; else echo "[dry-run] $*"; fi; }

run pvcreate "$dev"
if vgs "$vg" >/dev/null 2>&1; then run vgextend "$vg" "$dev"; else run vgcreate "$vg" "$dev"; fi
run lvcreate -l 100%FREE -n "$lv" "$vg"
run mkfs.ext4 -L "$lv" "/dev/$vg/$lv"
run mkdir -p "$mnt"
if [[ "$apply" == "--apply" ]]; then
  uuid="$(blkid -s UUID -o value "/dev/$vg/$lv")"
  grep -q "$uuid" /etc/fstab || echo "UUID=$uuid $mnt ext4 defaults,nofail 0 2" >> /etc/fstab
  findmnt --verify && mount "$mnt"
fi
EOF
sudo chmod +x /usr/local/sbin/provision-disk.sh
shellcheck /usr/local/sbin/provision-disk.sh
sudo provision-disk.sh $L3 datavg datalv /srv/data            # dry run
```

**Verify it worked.** *Typical dry-run output*:

```text
[dry-run] pvcreate /dev/loop4
[dry-run] vgcreate datavg /dev/loop4
[dry-run] lvcreate -l 100%FREE -n datalv datavg
[dry-run] mkfs.ext4 -L datalv /dev/datavg/datalv
[dry-run] mkdir -p /srv/data
```

Then run again with `--apply` on the loop device only.

**Acceptance criteria**

- [ ] Without `--apply` nothing changes.
- [ ] It refuses a mounted disk and a disk with an existing filesystem.
- [ ] `shellcheck` is clean, and the fstab line passes `findmnt --verify`.

**Undo it:** remove the fstab line, `umount`, `lvremove`, `vgremove`, `pvremove` (as in Task 8.3).

**Troubleshooting**

- `refusing: ... already has a signature`: intended. Check with `lsblk -f`; wipe only if you are certain (`wipefs -a`).
- Script finds the wrong disk: never auto-detect and format in one step; pass the device explicitly.
- In production prefer Ansible's `lvg`/`lvol`/`filesystem`/`mount` modules ([Step 10](step-10-automation.md)).

### Task 8.9: Replicated storage and failover (DRBD / GlusterFS)

- **What you will learn:** synchronous block replication between two nodes (DRBD) and the failover logic (Pacemaker/Corosync). Know the split-brain problem: two nodes both think they are primary and diverge.
- **Target distro:** Debian/Ubuntu (`drbd-utils`; the kernel ships an older in-tree DRBD 8, DRBD 9 comes from LINBIT packages), RHEL family (ELRepo or LINBIT packages). Check with `modinfo drbd`. **Risk level:** `destructive` to the backing devices. Two VMs required.
- *I did not run this task. All output is typical.* GlusterFS is in maintenance mode upstream; for new designs prefer Ceph or an NFS/ZFS pair.

```text
# /etc/drbd.d/r0.res on both nodes
resource r0 {
  device    /dev/drbd0;
  disk      /dev/vg0/drbd;
  meta-disk internal;
  on node1 { address 192.168.50.11:7789; }
  on node2 { address 192.168.50.12:7789; }
}
```

```bash
sudo drbdadm create-md r0 && sudo drbdadm up r0              # both nodes
sudo drbdadm primary --force r0                               # on node1 only, once
sudo mkfs.ext4 /dev/drbd0 && sudo mount /dev/drbd0 /mnt/ha
sudo drbdadm status r0
```

*Typical output*: `r0 role:Primary / disk:UpToDate / node2 role:Secondary peer-disk:UpToDate`.
Failover drill: unmount on node1, `drbdadm secondary r0`; on node2 `drbdadm primary r0 && mount /dev/drbd0 /mnt/ha`; files are present.
Automatic failover needs a cluster manager (Pacemaker) and **fencing** (STONITH).

**Verify it worked.** Prove replication with a manual failover (typical output — needs two nodes):

```bash
# node1 (Primary): write a file and confirm the role
echo "replicated $(date)" | sudo tee /mnt/ha/replicated.txt
sudo drbdadm status r0

# failover: demote node1, promote node2
sudo umount /mnt/ha && sudo drbdadm secondary r0           # run on node1
sudo drbdadm primary r0 && sudo mount /dev/drbd0 /mnt/ha   # run on node2
cat /mnt/ha/replicated.txt
```

*Typical output:*

```text
r0 role:Primary
  disk:UpToDate
  node2 role:Secondary
    peer-disk:UpToDate

replicated Mon Oct 19 09:00:00 UTC 2026
```

Both `peer-disk:` lines read `UpToDate` and the file written on node1 is visible on node2 after the
promote — synchronous replication working. Back on node1, `sudo drbdadm status r0` now shows
`role:Secondary`.

**Acceptance criteria**

- [ ] Data written on node1 appears on node2 after manual failover.
- [ ] You can describe split-brain and how fencing prevents it.
- [ ] Network used for replication is private and fast.

**Undo it:** `sudo drbdadm down r0; sudo drbdadm wipe-md r0`

**Troubleshooting**

- `Connecting` / `StandAlone`: firewall blocks 7789 or the hostnames do not match the `on` names.
- `Split-Brain detected`: choose a survivor and discard the other's changes with `drbdadm connect --discard-my-data`.
- Cluster failover loops: missing fencing or too-aggressive timeouts.

### Task 8.10: Disk quotas on a loopback filesystem

- **What you will learn:** limit how much disk space and how many inodes a user may consume, using a file-backed filesystem so no real disk is touched.
- **Target distro:** both. Debian/Ubuntu: `quota` package (ext4 `usrquota`/`grpquota`). RHEL family: `quota` package; on XFS use `xfs_quota` instead of `quotacheck`/`edquota`.
- **Risk level:** `destructive` only to the image file you create. Needs root and a real or loopback block device.

```bash
sudo apt install -y quota e2fsprogs   # RHEL: sudo dnf install -y quota e2fsprogs
mkdir -p ~/lab && cd ~/lab
truncate -s 1G disk.img
LOOP=$(sudo losetup -f --show disk.img); echo "loop=$LOOP"
sudo mkfs.ext4 -q -L labdisk "$LOOP"
sudo mkdir -p /mnt/labdisk
sudo mount -o usrquota,grpquota "$LOOP" /mnt/labdisk
sudo quotacheck -cum /mnt/labdisk
sudo quotaon -v /mnt/labdisk

sudo useradd -m dave 2>/dev/null || true
sudo mkdir /mnt/labdisk/dave && sudo chown dave /mnt/labdisk/dave
# soft 100 MB, hard 120 MB; 0 inode limits here
sudo setquota -u dave 102400 122880 0 0 /mnt/labdisk
sudo repquota -s /mnt/labdisk
```

**Verify it worked:** `repquota -s` shows `dave` with the limits you set, and writing past the hard limit fails:

```bash
sudo -u dave dd if=/dev/zero of=/mnt/labdisk/dave/big bs=1M count=130 2>&1 | tail -n 2
```

*Typical output:* `dd: error writing '/mnt/labdisk/dave/big': Disk quota exceeded`.

**Acceptance criteria:**

- [ ] `repquota -s` lists the filesystem with quota limits on.
- [ ] A user past the hard limit gets "Disk quota exceeded".

**Undo it**

```bash
sudo quotaoff /mnt/labdisk
sudo umount /mnt/labdisk
sudo losetup -d "$LOOP"
rm ~/lab/disk.img
sudo userdel -r dave 2>/dev/null || true
```

**Troubleshooting:**

- `quotaon: Operation not supported`: the kernel/filesystem lacks quota support — use a VM with ext4/XFS, not a container.
- `target is busy` on `umount`: `cd` out of the mount, or find the culprit with `lsof +f -- /mnt/labdisk`.
- On RHEL/XFS: mount with `-o uquota,gquota` and use `xfs_quota -x -c 'report -h' /mnt/labdisk` instead of `repquota`.

### Task 8.11: Check disk health with SMART

- **What you will learn:** read a disk's SMART health status, temperature, reallocated sectors, and run a short self-test — so you catch a failing disk before data loss.
- **Target distro:** both (`smartmontools`: `sudo apt install -y smartmontools` / `sudo dnf install -y smartmontools`).
- **Risk level:** `safe` (read-only; a short self-test takes a few minutes and does not touch data). *A loopback file has no SMART, so use a real disk here — in a VM, pass a spare disk through; on your laptop, check your main disk but do not run a long test.*

```bash
sudo smartctl --health /dev/sda          # or /dev/nvme0, your actual disk
sudo smartctl -a /dev/sda | grep -iE 'reallocated|temperature|power_on|health'
```

*Typical output (a healthy disk):*

```text
SMART overall-health self-assessment test result: PASSED
```

**Verify it worked:** `smartctl --health` prints `PASSED` (or warns if the disk is failing). `Reallocated_Sector_Ct` should be `0` on a healthy disk.

**Acceptance criteria:**

- [ ] You can run `smartctl --health` on a disk and interpret `PASSED` vs a warning.
- [ ] You know where to find reallocated-sector and temperature values.

**Undo it:** none (read-only inspection).

**Troubleshooting:**

- `SMART command failed`: the disk or controller does not expose SMART (common in VMs and some RAID controllers) — check the physical disk on the host, not the virtual block device.
- `Permission denied`: run `smartctl` with `sudo`.
- NVMe: use `/dev/nvme0` and `sudo nvme smart-log /dev/nvme0` as an equivalent.

---

## Step checklist

- [ ] 8.1 Partition, format, fstab
- [ ] 8.2 RAID 1
- [ ] 8.3 LVM
- [ ] 8.4 RAID 5/10
- [ ] 8.5 LVM snapshots
- [ ] 8.6 LUKS
- [ ] 8.7 Ceph (read/lab)
- [ ] 8.8 Provisioning script
- [ ] 8.9 DRBD / failover (read/lab)
- [ ] 8.10 Disk quotas (repquota, setquota)
- [ ] 8.11 SMART health check (smartctl)

## Further reading

- [Linux RAID wiki](https://raid.wiki.kernel.org/): mdadm usage, recovery and monitoring.
- [Red Hat: Configuring and managing logical volumes](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_and_managing_logical_volumes/index): LVM in depth, including thin pools and snapshots.
- [Cryptsetup FAQ](https://gitlab.com/cryptsetup/cryptsetup/-/wikis/FrequentlyAskedQuestions): practical LUKS answers.
- [Ceph documentation](https://docs.ceph.com/en/latest/): architecture and `cephadm`.
- [quota(1)](https://man7.org/linux/man-pages/man1/quota.1.html) and [repquota(8)](https://man7.org/linux/man-pages/man8/repquota.8.html): disk quotas for users and groups.
- [smartctl(8)](https://www.smartmontools.org/browser/trunk/smartmontools.8): disk health, self-tests, and attribute interpretation.

**Next:** [Step 9: Backup and Recovery](step-09-backup-and-recovery.md)
