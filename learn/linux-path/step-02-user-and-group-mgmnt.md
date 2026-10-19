# Step 2: Users and Groups

> **Time:** ~6-8 hours · **Level:** Beginner → Advanced
> **Prerequisites:** [Step 1](step-01-linux-fundamentals.md) · **Next:** [Step 3: Networking](step-03-networking-basics.md)

<!-- -->

> [!WARNING]
> This step creates and locks accounts, edits PAM and sudo rules, and (in Task 2.7) sets up
> network authentication. A bad `sudoers` or PAM change can lock **you** out of root.
> Do this in a throwaway VM or the devcontainer, never on a machine you cannot afford to lose.
> Keep a second root shell open (`sudo -s` in another terminal) while changing sudo or PAM, and
> always validate sudo files with `visudo -c`.

Conventions are explained in [Step 1](step-01-linux-fundamentals.md#how-to-read-each-task).
Unless stated, output was captured on Ubuntu 24.04 (container, as root). Debian/Ubuntu and RHEL
family differences are called out in each task.

---

## Beginner

### Task 2.1: Create users and groups

- **What you will learn:** `useradd`, `groupadd`, and where accounts live (`/etc/passwd`, `/etc/group`).
- **Target distro:** both. `useradd -m` works on every distro. Debian/Ubuntu also ship the friendlier `adduser`; RHEL family does not.
- **Risk level:** `safe` on a lab machine (adds accounts only).

```bash
sudo groupadd developers
sudo groupadd ops
for u in anna ben cleo; do sudo useradd -m -s /bin/bash "$u"; done
```

**Verify it worked**

```bash
getent group developers ops
getent passwd anna ben cleo
```

**Expected output:**

```text
developers:x:1001:
ops:x:1002:
anna:x:1001:1003::/home/anna:/bin/bash
ben:x:1002:1004::/home/ben:/bin/bash
cleo:x:1003:1005::/home/cleo:/bin/bash
```

(`getent` queries every identity source, so it also works with LDAP later. UID numbers may differ.)
The `x` means the hash is stored in `/etc/shadow`, which only root can read.

**Acceptance criteria**

- [ ] 3 new users and 2 new groups appear in `getent`.
- [ ] Each user has a home directory under `/home` (`ls -ld /home/anna`).
- [ ] You can say why `getent` is preferred over `grep /etc/passwd`.

**Undo it**

```bash
for u in anna ben cleo; do sudo userdel -r "$u"; done
sudo groupdel developers; sudo groupdel ops
```

**Troubleshooting**

- `useradd: user 'anna' already exists`: pick another name or `id anna` to inspect it.
- `userdel: user anna is currently used by process N`: log them out or `sudo pkill -KILL -u anna` first.
- `useradd: command not found` as a normal user: it lives in `/usr/sbin`; use `sudo useradd`.

### Task 2.2: Add users to groups

- **What you will learn:** supplementary groups and why `-a` matters.
- **Target distro:** both. **Risk level:** `safe`, but `usermod -G` **without** `-a` removes the user from other groups, including `sudo`/`wheel`.

```bash
sudo usermod -aG developers anna
sudo usermod -aG developers,ops ben
```

**Verify it worked**

```bash
id ben
groups anna
```

**Expected output:**

```text
uid=1002(ben) gid=1004(ben) groups=1004(ben),1001(developers),1002(ops)
anna : anna developers
```

**Acceptance criteria**

- [ ] `ben` is in `developers` and `ops`, `anna` only in `developers`.
- [ ] You can explain why a logged-in user must log out and back in to see a new group.

**Undo it**

```bash
sudo gpasswd -d ben ops
```

**Troubleshooting**

- User lost all other groups: you forgot `-a`. Re-add them with `usermod -aG`.
- New group not visible: existing sessions keep the old group list. Run `newgrp developers` or log in again.
- `usermod: group 'x' does not exist`: create it with `groupadd`.

### Task 2.3: Set, check and lock passwords

- **What you will learn:** `passwd`, `chpasswd`, password status flags, locking.
- **Target distro:** both. **Risk level:** `safe` (never reuse a real password in a lab).

```bash
echo 'anna:Str0ng-Pass-123' | sudo chpasswd      # non-interactive (scripts); never do this with real secrets in shell history
sudo passwd -S anna
sudo passwd -S ben
sudo passwd -l ben
sudo passwd -S ben
```

Interactively, `sudo passwd ben` prompts twice and is the normal way.
Test with `su - anna` (enter the password) and `exit` to come back.

**Verify it worked**

**Expected output** (`P` = usable password, `L` = locked, `NP` = no password; the date is the last change):

```text
anna P 2026-10-17 0 99999 7 -1
ben L 2026-10-17 0 99999 7 -1
passwd: password changed.
ben L 2026-10-17 0 99999 7 -1
```

(The first `ben L` line is from `passwd -S ben` before locking: new accounts have a locked `!` password by default. After `passwd -l` it stays `L`.)

**Acceptance criteria**

- [ ] `su - anna` succeeds with the password and fails with a wrong one.
- [ ] `ben` shows `L`.

**Undo it**

```bash
sudo passwd -u ben     # fails with "would result in a passwordless account" if ben never had a password; set one first
```

**Troubleshooting**

- `passwd -u` refuses: the account had no password. Set one with `passwd ben`, then unlock.
- `su: Authentication failure`: wrong password, or the account is locked.
- Password rejected as too simple: that is `pam_pwquality` working (Task 2.5). Choose a longer passphrase.

---

## Intermediate

### Task 2.4: Per-user shell environment

- **What you will learn:** which startup file does what: `~/.bashrc` (interactive non-login), `~/.bash_profile` or `~/.profile` (login), `/etc/skel` (the template for new users).
- **Target distro:** both. On Debian, `~/.profile` sources `~/.bashrc`; on RHEL, `~/.bash_profile` does.
- **Risk level:** `safe`. Keep a backup because a syntax error in `.bashrc` can break logins.

```bash
sudo cp /home/anna/.bashrc /home/anna/.bashrc.bak
sudo tee -a /home/anna/.bashrc >/dev/null <<'EOF'

# --- team defaults ---
alias ll='ls -lah'
export EDITOR=nano
EOF
sudo chown anna:anna /home/anna/.bashrc
```

**Verify it worked**

```bash
sudo -iu anna bash -ic 'alias ll; echo "$EDITOR"'
```

*Typical output:*

```text
alias ll='ls -lah'
nano
```

(I verified that the file is changed and that the shell starts; the alias line itself was not captured because non-interactive `su -c` skips `.bashrc`, which is why the command above uses `bash -i`.)

To give **future** users the same defaults, put the lines in `/etc/skel/.bashrc` instead.

**Acceptance criteria**

- [ ] `alias ll` works in a fresh login of the user.
- [ ] You can say which file you would edit for login-only variables.

**Undo it**

```bash
sudo mv /home/anna/.bashrc.bak /home/anna/.bashrc
```

**Troubleshooting**

- Change not visible: you are in an old shell. Open a new one or run `source ~/.bashrc`.
- Login loops or drops you out: a command in `.bash_profile` exited. Fix it from a root shell using the `.bak` copy.
- Works over SSH but not in a script: scripts do not read `.bashrc`. Use explicit paths.

### Task 2.5: Password ageing and complexity policy

- **What you will learn:** `chage`, `/etc/login.defs`, `pam_pwquality`, and the modern view: **length and a blocklist beat arbitrary complexity and forced rotation** (NIST SP 800-63B). Use ageing for service accounts and compliance requirements.
- **Target distro:** both. Package: `libpam-pwquality` (Debian/Ubuntu); it is installed by default on RHEL family and managed with `authselect`.
- **Risk level:** `can lock you out`. A strict policy applies to the next password change, and `chage` expiry can force a change at the next login.

> [!WARNING]
> Do not set `chage -M` or `-E` on `root` or on your only admin account in a lab you cannot reboot into recovery mode.

```bash
sudo chage -l anna
sudo chage -M 90 -m 7 -W 14 anna      # max 90 days, min 7, warn 14 days ahead
sudo chage -l anna
grep -E '^(PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_WARN_AGE|UMASK)' /etc/login.defs
```

`/etc/login.defs` only affects **new** accounts. Raise the minimum length with `pam_pwquality`:

```bash
sudo apt install -y libpam-pwquality libpwquality-tools     # RHEL: already installed (dnf install libpwquality)
sudo tee /etc/security/pwquality.conf.d/10-lab.conf >/dev/null <<'EOF'
minlen = 12
dictcheck = 1
usercheck = 1
retry = 3
EOF
```

**Verify it worked**

```bash
echo 'password' | pwscore
echo 'Tr0ub4dor&3-horse-staple' | pwscore
```

**Expected output** for the dictionary word (the second command printed `100` in my run, scores vary by version):

```text
Password quality check failed:
 The password fails the dictionary check - it is based on a dictionary word
```

`chage -l anna` after the change (captured):

```text
Last password change     : Oct 17, 2026
Password expires     : Jan 15, 2027
Password inactive     : never
Account expires      : never
Minimum number of days between password change  : 7
Maximum number of days between password change  : 90
Number of days of warning before password expires : 14
```

On Ubuntu `/etc/pam.d/common-password` already loads `pam_pwquality.so retry=3`. On RHEL family
use `authselect` (do not hand-edit generated PAM files): `sudo authselect current`.

**Acceptance criteria**

- [ ] `chage -l anna` shows max 90 / min 7 / warn 14.
- [ ] `pwscore` rejects a dictionary word.
- [ ] `sudo passwd anna` rejects a password shorter than 12 characters (try `abc`).

**Undo it**

```bash
sudo chage -M 99999 -m 0 -W 7 anna
sudo rm /etc/security/pwquality.conf.d/10-lab.conf
```

**Troubleshooting**

- `pwscore: command not found`: install `libpwquality-tools`.
- Policy seems ignored for root: root can override `pam_pwquality` warnings (`enforce_for_root` changes this).
- `/etc/security/pwquality.conf.d/` missing on an old release: edit `/etc/security/pwquality.conf` directly.

### Task 2.6: Delegate with sudo

- **What you will learn:** least privilege with `/etc/sudoers.d/` drop-ins, command allow-lists, and `visudo -c` as a safety net.
- **Target distro:** both. The admin group is `sudo` on Debian/Ubuntu and `wheel` on RHEL family.
- **Risk level:** `can lock you out`. A syntax error in a sudoers file can disable sudo for everyone.

> [!WARNING]
> Never edit `/etc/sudoers` with a normal editor. Use `visudo`, or write a drop-in and validate it
> with `visudo -cf FILE` **before** it is live. Keep a root shell open.

Allow the `ops` group to check and restart `ssh` (the unit is `sshd` on RHEL family):

```bash
sudo tee /etc/sudoers.d/ops-services >/dev/null <<'EOF'
%ops ALL=(root) /usr/bin/systemctl status ssh, /usr/bin/systemctl restart ssh
EOF
sudo chmod 440 /etc/sudoers.d/ops-services
sudo visudo -cf /etc/sudoers.d/ops-services
```

**Verify it worked**

```bash
sudo -l -U ben
```

**Expected output:**

```text
/etc/sudoers.d/ops-services: parsed OK
Matching Defaults entries for ben on e76a4582a41d:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin, use_pty

User ben may run the following commands on e76a4582a41d:
    (root) /usr/bin/systemctl status ssh, /usr/bin/systemctl restart ssh
```

A deliberately broken file is caught:

```bash
echo "bad line" > /tmp/bad; visudo -cf /tmp/bad; echo "exit=$?"
```

```text
/tmp/bad:1:9: syntax error
bad line
        ^
exit=1
```

Then, as `ben`, allowed commands work (after entering ben's password) and anything else prints
`Sorry, user ben is not allowed to execute ...` (*typical output*; not captured because the test
container has no `systemctl`).

**Acceptance criteria**

- [ ] `sudo -l -U ben` lists only the two commands.
- [ ] `visudo -c` reports no errors.
- [ ] You can explain why allowing `sudo vim` or `sudo less` is equivalent to giving root (shell escapes).

**Undo it**

```bash
sudo rm /etc/sudoers.d/ops-services
```

**Troubleshooting**

- `sudo: parse error in /etc/sudoers.d/...`: boot into recovery or use `pkexec visudo` / a root shell to fix. This is why you keep one open.
- File ignored: drop-ins must not have a `.` or end in `~`, and must be mode `0440`.
- Rule does not match: use the absolute path shown by `command -v systemctl` (it is `/usr/bin` on modern systems, `/bin` on older ones).

---

## Advanced

### Task 2.7: Centralised accounts with LDAP

- **What you will learn:** how a directory service replaces local accounts, and how NSS (who exists?) and PAM (may they log in?) consume it via SSSD.
- **Target distro:** server tested on Ubuntu 24.04 (`slapd`). On RHEL family 9 the `openldap-servers` package was removed from the base repos, so use **389 Directory Server** (`389-ds-base`) or **FreeIPA** (LDAP + Kerberos + DNS + sudo rules in one product) for the server. Clients use **SSSD** on both families.
- **Risk level:** `can lock you out` (PAM changes on the client). Use two VMs and a console that does not depend on LDAP.

> [!WARNING]
> Never switch a machine's only authentication source to a network service you have not tested.
> Keep local `root` and a local admin account that works with the network down.

**Server (Ubuntu 24.04 lab).** This pre-answers the installer prompts and starts a non-production
server on loopback only:

```bash
sudo debconf-set-selections <<'EOF'
slapd slapd/domain string lab.example
slapd shared/organization string Lab
slapd slapd/password1 password LabAdmin-123
slapd slapd/password2 password LabAdmin-123
EOF
sudo DEBIAN_FRONTEND=noninteractive apt install -y slapd ldap-utils

cat > base.ldif <<'EOF'
dn: ou=People,dc=lab,dc=example
objectClass: organizationalUnit
ou: People

dn: ou=Groups,dc=lab,dc=example
objectClass: organizationalUnit
ou: Groups

dn: uid=anna,ou=People,dc=lab,dc=example
objectClass: inetOrgPerson
objectClass: posixAccount
cn: Anna Example
sn: Example
uid: anna
uidNumber: 10001
gidNumber: 10001
homeDirectory: /home/anna
loginShell: /bin/bash
EOF
ldapadd -x -H ldap://127.0.0.1 -D cn=admin,dc=lab,dc=example -w LabAdmin-123 -f base.ldif
```

The password is a lab-only example. In real use prompt with `-W` and never put secrets on the command line.

**Verify it worked**

```bash
ldapsearch -x -H ldap://127.0.0.1 -b dc=lab,dc=example -LLL "(uid=anna)" uid uidNumber
```

**Expected output:**

```text
dn: uid=anna,ou=People,dc=lab,dc=example
uid: anna
uidNumber: 10001
```

(`adding new entry ...` lines were printed by `ldapadd`.)

**Client (second machine; typical configuration, not run here).**

```bash
sudo apt install -y sssd sssd-ldap libnss-sss libpam-sss         # RHEL: sudo dnf install -y sssd sssd-ldap oddjob-mkhomedir
sudo tee /etc/sssd/sssd.conf >/dev/null <<'EOF'
[sssd]
services = nss, pam
domains = lab.example

[domain/lab.example]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldaps://ldap.lab.example
ldap_search_base = dc=lab,dc=example
ldap_tls_reqcert = demand
cache_credentials = true
EOF
sudo chmod 600 /etc/sssd/sssd.conf
sudo systemctl enable --now sssd
sudo pam-auth-update --enable mkhomedir        # Debian/Ubuntu; RHEL: sudo authselect select sssd with-mkhomedir --force
getent passwd anna                              # should now resolve through LDAP
```

Use `ldaps://` or StartTLS in anything beyond a lab: plain LDAP sends passwords in clear text.

**Acceptance criteria**

- [ ] `ldapsearch` returns the entry on the server.
- [ ] On the client, `getent passwd anna` and `id anna` resolve the LDAP user.
- [ ] You can log in as `anna` with the network up, and still log in as a local admin with it down.

**Undo it**

```bash
ldapdelete -x -D cn=admin,dc=lab,dc=example -w LabAdmin-123 "uid=anna,ou=People,dc=lab,dc=example"
sudo apt purge -y slapd ldap-utils && sudo rm -rf /var/lib/ldap /etc/ldap/slapd.d     # server (lab only!)
sudo systemctl disable --now sssd; sudo pam-auth-update          # client: untick "Create home directory..." if enabled
```

**Troubleshooting**

- `ldap_bind: Invalid credentials (49)`: wrong bind DN or password; the DN must match your `dc=` suffix.
- `getent` returns nothing on the client: `sudo sssctl domain-status lab.example` and `journalctl -u sssd`. The usual causes are a wrong `ldap_search_base` or a TLS certificate the client does not trust.
- `sssd.conf` is ignored: it must be owned by root with mode `600`.

### Task 2.8: Automate onboarding and offboarding

- **What you will learn:** a safe account lifecycle script: validate input, create, force password change, lock and archive on departure.
- **Target distro:** both (`useradd`, `usermod`, `passwd`, `tar` are common). **Risk level:** `destructive` (it locks accounts and kills processes). Run in a lab.

```bash
sudo tee /usr/local/sbin/user-lifecycle.sh >/dev/null <<'EOF'
#!/usr/bin/env bash
# Usage: user-lifecycle.sh onboard USER GROUP[,GROUP...] | offboard USER
# Must run as root. Offboarding locks the account and archives the home directory.
set -euo pipefail

archive_dir=/var/backups/offboarded

die() { echo "error: $*" >&2; exit 1; }
[[ $EUID -eq 0 ]] || die "run as root"

onboard() {
  local user="$1" groups="$2" g
  local -a glist
  [[ "$user" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || die "invalid user name: $user"
  id "$user" &>/dev/null && die "user exists: $user"
  IFS=',' read -r -a glist <<< "$groups"
  for g in "${glist[@]}"; do getent group "$g" >/dev/null || groupadd "$g"; done
  useradd -m -s /bin/bash -G "$groups" "$user"
  install -d -m 700 -o "$user" -g "$user" "/home/$user/.ssh"
  echo "created $user in groups: $groups; set a password with: passwd $user"
}

offboard() {
  local user="$1"
  id "$user" &>/dev/null || die "no such user: $user"
  usermod -L -e 1 -s /usr/sbin/nologin "$user"     # lock password, expire account, no shell
  pkill -KILL -u "$user" 2>/dev/null || true
  umask 077
  install -d -m 700 "$archive_dir"
  tar -czf "$archive_dir/$user-$(date +%F).tar.gz" -C /home "$user"
  echo "locked $user, archive: $archive_dir/$user-$(date +%F).tar.gz"
}

case "${1:-}" in
  onboard)  [[ $# -eq 3 ]] || die "usage: onboard USER GROUPS"; onboard "$2" "$3" ;;
  offboard) [[ $# -eq 2 ]] || die "usage: offboard USER"; offboard "$2" ;;
  *) die "usage: $0 onboard USER GROUPS | offboard USER" ;;
esac
EOF
sudo chmod 755 /usr/local/sbin/user-lifecycle.sh
shellcheck /usr/local/sbin/user-lifecycle.sh
sudo user-lifecycle.sh onboard zoe staff,web
sudo user-lifecycle.sh offboard zoe
```

On RHEL family `nologin` is `/usr/sbin/nologin` too; the `staff` group exists only on Debian (the
script creates it if missing). I did not capture the `umask 077` line: my captured run used the
same script without it and produced a world-readable archive, which is why the line was added.

**Verify it worked**

```bash
id zoe
sudo passwd -S zoe; getent passwd zoe
sudo ls -l /var/backups/offboarded
sudo user-lifecycle.sh onboard zoe staff; echo "exit=$?"
```

**Expected output** (captured; archive mode will be `-rw-------` with the `umask` line):

```text
uid=1002(zoe) gid=1004(zoe) groups=1004(zoe),50(staff),1003(web)
zoe L 1970-01-01 0 99999 7 -1
zoe:x:1002:1004::/home/zoe:/usr/sbin/nologin
-rw-r--r-- 1 root root 2324 Oct 17 12:29 zoe-2026-10-17.tar.gz
error: user exists: zoe
exit=1
```

**Acceptance criteria**

- [ ] `shellcheck` is clean.
- [ ] Onboarding twice fails safely; invalid names (`Bad Name`, `../x`) are rejected.
- [ ] After offboarding the user cannot log in, and the archive exists and is readable only by root.

**Undo it**

```bash
sudo userdel -r zoe 2>/dev/null; sudo rm -rf /var/backups/offboarded
```

**Troubleshooting**

- `userdel: user zoe is currently used by process N`: the `pkill` in offboard handles this; check for `systemd --user` sessions with `loginctl terminate-user zoe`.
- Archive is huge: exclude caches with `tar --exclude=zoe/.cache`.
- Needs email or ticket integration: call `logger -t user-lifecycle "..."` and let your monitoring (Step 7) alert on it.

### Task 2.9: Per-user and per-group disk quotas

- **What you will learn:** `edquota`, group quotas and a report script.
- **Target distro:** both; on XFS use project/user quotas through `xfs_quota`. Mount setup is identical to [Task 1.7](step-01-linux-fundamentals.md#task-17-quotas-on-a-loop-device-filesystem), so complete that first.
- **Risk level:** `safe` on the loop-device lab from Task 1.7; `can lock you out` of writing if you set a tiny quota on a real `/home`.

```bash
# assumes /mnt/labdisk is mounted with -o usrquota,grpquota and quotacheck -cug has run
sudo setquota -u dave 10000 12000 0 0 /mnt/labdisk      # soft, hard blocks (1K), soft, hard inodes
sudo setquota -g developers 50000 60000 0 0 /mnt/labdisk
sudo edquota -u dave                                     # interactive editor alternative
```

Report script:

```bash
sudo tee /usr/local/sbin/quota-report.sh >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mount_point="${1:?usage: quota-report.sh MOUNTPOINT}"
repquota -s -u -g "$mount_point"
EOF
sudo chmod 755 /usr/local/sbin/quota-report.sh
sudo quota-report.sh /mnt/labdisk
```

**Verify it worked.** The user-quota report was verified in [Task 1.7](step-01-linux-fundamentals.md#task-17-quotas-on-a-loop-device-filesystem)
(root row: `24K used, 0 soft, 0 hard`). Group quotas and `edquota` were not run here.
*Typical output* after `dave` writes data: a row such as `dave -- 20480 10000 12000 ...` and a
`+-` flag with a grace period once over the soft limit.

**Acceptance criteria**

- [ ] A user over the hard limit cannot write.
- [ ] The report script prints usage for a mount point you pass in.
- [ ] You know the difference between the soft limit (grace period) and the hard limit.

**Undo it**

```bash
sudo setquota -u dave 0 0 0 0 /mnt/labdisk
sudo setquota -g developers 0 0 0 0 /mnt/labdisk
```

**Troubleshooting**

- `quotaon: cannot find ... mountpoint`: filesystem not mounted with the quota option, or not listed in `/etc/fstab`.
- Quota numbers do not move: run `sudo quotacheck -cug /mnt/labdisk` again (with the filesystem quiet).
- XFS needs the option at mount time (`-o usrquota`); it cannot be added with a remount.

---

## Step checklist

- [ ] 2.1 Users and groups
- [ ] 2.2 Group membership
- [ ] 2.3 Passwords
- [ ] 2.4 Shell environment
- [ ] 2.5 Ageing and complexity
- [ ] 2.6 sudo delegation
- [ ] 2.7 LDAP and SSSD
- [ ] 2.8 Onboarding script
- [ ] 2.9 Quotas

## Further reading

- [sudoers(5)](https://man7.org/linux/man-pages/man5/sudoers.5.html): every sudoers option, with examples.
- [NIST SP 800-63B](https://pages.nist.gov/800-63-3/sp800-63b.html): why length and blocklists beat forced rotation.
- [SSSD documentation](https://sssd.io/docs/introduction.html): how SSSD connects Linux to LDAP, Kerberos, AD and IPA.

**Next:** [Step 3: Networking](step-03-networking-basics.md)
