# Step 6: System Security

> **Time:** ~10-12 hours · **Level:** Beginner → Advanced
> **Prerequisites:** [Step 2](step-02-user-and-group-mgmnt.md), [Step 3](step-03-networking-basics.md) · **Next:** [Step 7: Monitoring](step-07-system-monitoring.md)

<!-- -->

> [!WARNING]
> Do this in a throwaway VM or the devcontainer, never on a machine you cannot afford to lose.
> Keep a second SSH session open while changing SSH or firewall settings. Test every SSH change
> from a **new** terminal before closing the old one, and validate with `sshd -t` first.

Conventions: see [Step 1](step-01-linux-fundamentals.md#how-to-read-each-task).
SSH, fail2ban, Suricata, Lynis and `systemd-analyze` results were captured in Ubuntu 24.04 containers or a
systemd host. Anything needing a full OS (SELinux, auditd, Wazuh, real firewalls, hardware keys) is marked
*typical output*. Firewall basics are in [Task 3.3](step-03-networking-basics.md#task-33-a-firewall-with-nftables-and-ufw--firewalld);
this step applies them.

---

## Beginner

### Task 6.1: A host firewall policy (nftables, ufw, firewalld)

- **What you will learn:** default-deny inbound, allow only what you serve, rate-limit SSH, and block an address.
- **Target distro:** both. Ubuntu: `ufw`. RHEL family: `firewalld`. Either sits on nftables; pick one.
- **Risk level:** `can lock you out`.

> [!WARNING]
> Add the SSH allow rule **before** enabling the firewall. Keep your current session open and test a second one.

```bash
# Ubuntu / Debian
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw limit 22/tcp               # allow SSH but throttle bursts of connections
sudo ufw allow 80,443/tcp
sudo ufw deny from 203.0.113.50
sudo ufw enable
sudo ufw status verbose
```

```bash
# RHEL family
sudo systemctl enable --now firewalld
sudo firewall-cmd --permanent --add-service={ssh,http,https}
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="203.0.113.50" drop'
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

Native nftables (any distro): see the tested ruleset in [Task 3.3](step-03-networking-basics.md#task-33-a-firewall-with-nftables-and-ufw--firewalld).

**Verify it worked.** *Typical output* (not run: needs a full OS):

```text
Status: active
Default: deny (incoming), allow (outgoing), disabled (routed)
22/tcp                     LIMIT IN    Anywhere
80,443/tcp                 ALLOW IN    Anywhere
Anywhere                   DENY IN     203.0.113.50
```

From another host: `nmap -Pn -p 22,80,443,3306 SERVER` should show 22/80/443 open and 3306 filtered.

**Acceptance criteria**

- [ ] Only the ports you serve are reachable from outside.
- [ ] A new SSH session works after enabling.
- [ ] Rules survive a reboot.

**Undo it**

```bash
sudo ufw disable && sudo ufw --force reset          # firewalld: remove rules with --remove-service / --remove-rich-rule
```

**Troubleshooting**

- Locked out: use the console, run `sudo ufw disable` or `sudo nft flush ruleset`.
- Docker published ports bypass `ufw` (Docker writes its own nftables/iptables rules). Bind containers to `127.0.0.1` or use `DOCKER-USER` rules.
- `ufw` and `firewalld` or raw `nft` conflict: use only one manager.

### Task 6.2: SSH key-only login and hardening

- **What you will learn:** key pairs, `authorized_keys`, a hardening drop-in, and how to prove password and root logins are refused.
- **Target distro:** both. Config in `/etc/ssh/sshd_config.d/*.conf`. Service `ssh` (Debian/Ubuntu) or `sshd` (RHEL).
- **Risk level:** `can lock you out`.

> [!WARNING]
> Disable passwords only **after** a key login works from a second terminal. On Ubuntu 22.10 and later
> `ssh.socket` listens on the port, so a `Port` change needs
> `sudo systemctl edit ssh.socket` (override `ListenStream=`) or `sudo systemctl disable --now ssh.socket && sudo systemctl enable --now ssh`.

On your **client**:

```bash
ssh-keygen -t ed25519 -a 100 -C "alice@laptop"
ssh-copy-id alice@SERVER
ssh -o PasswordAuthentication=no alice@SERVER true && echo "key login works"
```

On the **server** (validate before reload):

```bash
sudo tee /etc/ssh/sshd_config.d/10-hardening.conf >/dev/null <<'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey
AllowUsers alice
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
sudo sshd -t && sudo systemctl reload ssh        # RHEL: sshd
```

**Verify it worked.** Captured in a container (sshd on port 2222 with the same options):

```text
sshd -t OK
port 2222
maxauthtries 3
permitrootlogin no
passwordauthentication no
allowusers alice
authenticationmethods publickey
logged-in-as alice
alice@127.0.0.1: Permission denied (publickey).      <- password attempt
root@127.0.0.1: Permission denied (publickey).       <- root attempt
```

Key creation printed `256 SHA256:... alice@lab (ED25519)`. Show the effective settings any time with `sudo sshd -T`.

**Acceptance criteria**

- [ ] Key login works; password and root logins are refused.
- [ ] `sshd -t` is clean and `AllowUsers` lists only real users.
- [ ] Private key has mode `600` and a passphrase (use `ssh-agent`).

**Undo it**

```bash
sudo rm /etc/ssh/sshd_config.d/10-hardening.conf && sudo systemctl reload ssh
```

**Troubleshooting**

- `Permission denied (publickey)` after setup: wrong permissions. `~/.ssh` must be `700`, `authorized_keys` `600`, and the home directory not group-writable. Check `journalctl -u ssh`.
- Options ignored: first match wins; files in `sshd_config.d` load in alphabetical order before the main file's later lines.
- Locked out: console login, remove the drop-in, reload.

### Task 6.3: SELinux basics (RHEL family) and AppArmor (Ubuntu)

- **What you will learn:** mandatory access control: check the mode, read a context, fix a mislabelled web file, use booleans.
- **Target distro:** SELinux on RHEL family/Fedora. Ubuntu uses AppArmor (`sudo aa-status`).
- **Risk level:** `can lock you out` if you enable enforcing on a system that never ran SELinux (relabel needed, can fail to boot).

> [!WARNING]
> Never disable SELinux to "fix" a problem; diagnose it. Switching from `disabled` to `enforcing` needs `touch /.autorelabel` and a reboot, and should be tried in a VM snapshot first.

```bash
sestatus
getenforce
ls -Z /var/www/html
sudo setenforce 0          # permissive until reboot, for diagnosis only
sudo setenforce 1
sudo dnf install -y httpd policycoreutils-python-utils setroubleshoot-server
echo hello | sudo tee /srv/web/index.html >/dev/null 2>&1 || { sudo mkdir -p /srv/web; echo hello | sudo tee /srv/web/index.html; }
sudo semanage fcontext -a -t httpd_sys_content_t '/srv/web(/.*)?'
sudo restorecon -Rv /srv/web
sudo setsebool -P httpd_can_network_connect on
```

**Verify it worked.** *Typical output* (not run: containers have no SELinux):

```text
SELinux status:                 enabled
Current mode:                   enforcing
Policy from config file:        targeted
Relabeled /srv/web/index.html from unconfined_u:object_r:default_t:s0 to unconfined_u:object_r:httpd_sys_content_t:s0
```

Ubuntu: `sudo aa-status` lists profiles in enforce mode.

**Acceptance criteria**

- [ ] `getenforce` prints `Enforcing`.
- [ ] A web file with the wrong label is denied, then served after `restorecon`.
- [ ] You can read denials: `sudo ausearch -m avc -ts recent`.

**Undo it**

```bash
sudo semanage fcontext -d '/srv/web(/.*)?'; sudo setsebool -P httpd_can_network_connect off; sudo rm -r /srv/web
```

**Troubleshooting**

- 403 from httpd but permissions look right: check the label with `ls -Z` and AVC denials.
- `semanage: command not found`: install `policycoreutils-python-utils`.
- Boot hangs after enabling: boot with `enforcing=0`, run `restorecon -R /`, reboot.

---

## Intermediate

### Task 6.4: fail2ban

- **What you will learn:** jails, `maxretry`/`findtime`/`bantime`, testing a filter against sample logs, and manual unban.
- **Target distro:** both (`sudo apt install -y fail2ban`; RHEL: `sudo dnf install -y epel-release fail2ban`). It bans through nftables/firewalld.
- **Risk level:** `can lock you out`: you can ban yourself. Add your admin IP to `ignoreip`.

```bash
sudo tee /etc/fail2ban/jail.d/lab.local >/dev/null <<'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3
ignoreip = 127.0.0.1/8 ::1
backend = systemd

[sshd]
enabled = true
port = ssh
EOF
sudo fail2ban-client -t
sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd
```

Test the filter on sample lines without banning anyone:

```bash
fail2ban-regex /tmp/auth.log sshd
```

**Verify it worked.** Captured (sample log with 3 failures and 1 success):

```text
Failregex: 4 total
|-  #) [# of hits] regular expression
|   4) [3] ^Failed (?:<F-NOFAIL>publickey</F-NOFAIL>|\S+) for ...
Lines: 4 lines, 1 ignored, 3 matched, 0 missed
OK: configuration test is successful
```

*Typical output* of `fail2ban-client status sshd` after an attack: `Currently banned: 1` and the IP in `Banned IP list`.

**Acceptance criteria**

- [ ] `fail2ban-regex` matches your failed-login lines.
- [ ] Three failed logins from a test host get that host banned (`sudo fail2ban-client status sshd`).
- [ ] You can unban: `sudo fail2ban-client set sshd unbanip IP`.

**Undo it**

```bash
sudo systemctl disable --now fail2ban; sudo rm /etc/fail2ban/jail.d/lab.local
```

**Troubleshooting**

- Never bans: wrong `backend` or log path. On journald systems use `backend = systemd`; otherwise set `logpath`.
- Bans you: add your IP to `ignoreip`.
- Bans have no effect: Docker or another tool bypasses the chain; check `sudo nft list ruleset | grep f2b`.

### Task 6.5: Second factor for SSH: TOTP and FIDO2 keys

- **What you will learn:** two options. **FIDO2 security keys** (`ed25519-sk`) are phishing-resistant and the modern choice. **TOTP** with PAM is the fallback when no hardware is available.
- **Target distro:** both. TOTP package: `libpam-google-authenticator` (Debian/Ubuntu), `google-authenticator` (EPEL).
- **Risk level:** `can lock you out`. PAM mistakes block logins. Keep a root console and a second session.

**Option A: FIDO2 hardware key** (OpenSSH 8.2+; needs a key such as a YubiKey, so *not run*):

```bash
ssh-keygen -t ed25519-sk -O resident -O verify-required -C "alice-yubikey"
ssh-copy-id -i ~/.ssh/id_ed25519_sk.pub alice@SERVER
```

Without a key the command fails (captured): `Key enrollment failed: device not found`.

**Option B: TOTP.** Create the secret as the user (`-C` skips the interactive confirm):

```bash
sudo apt install -y libpam-google-authenticator
google-authenticator -t -d -f -r 3 -R 30 -w 3 -C
```

It prints a QR code and emergency codes: store them in a password manager. Then:

```bash
sudo cp /etc/pam.d/sshd /etc/pam.d/sshd.bak
sudo sed -i 's/^@include common-auth/#@include common-auth/' /etc/pam.d/sshd
echo 'auth required pam_google_authenticator.so' | sudo tee -a /etc/pam.d/sshd
sudo tee /etc/ssh/sshd_config.d/20-2fa.conf >/dev/null <<'EOF'
UsePAM yes
PasswordAuthentication no
KbdInteractiveAuthentication yes
AuthenticationMethods publickey,keyboard-interactive:pam
EOF
sudo sshd -t && sudo systemctl reload ssh
```

**Verify it worked.** In a container I confirmed that the TOTP secret generation prompts without `-C` and
fails without a terminal (`getline(): Inappropriate ioctl for device`), that `sshd -t` accepts the config, and that
`oathtool --totp -b SECRET` prints a 6-digit code. The full two-factor SSH login was *not* verified.
*Typical login*: key accepted, then `Verification code:` prompt; a wrong code gives `Permission denied`.

**Acceptance criteria**

- [ ] Login needs both your key and a valid code.
- [ ] Emergency codes are stored offline.
- [ ] You tested from a second session before logging out of the first.

**Undo it**

```bash
sudo rm /etc/ssh/sshd_config.d/20-2fa.conf; sudo mv /etc/pam.d/sshd.bak /etc/pam.d/sshd; sudo systemctl reload ssh
```

**Troubleshooting**

- Codes rejected: clock drift. Check `timedatectl`; `-w 3` widens the window.
- Still asked for a password: `common-auth` still included, or `KbdInteractiveAuthentication` is off.
- Service accounts and automation break: exempt them with `Match User svc-backup` and `AuthenticationMethods publickey`.

### Task 6.6: Intrusion detection with Suricata

- **What you will learn:** run Suricata on a packet capture, write a rule, read alerts. Suricata replaces Snort for most new deployments: multithreaded, Snort-compatible rules, JSON logs (`eve.json`).
- **Target distro:** Ubuntu (`sudo apt install -y suricata`), RHEL (EPEL or OISF repo). Rules updates: `sudo suricata-update`.
- **Risk level:** `safe` on pcap files. Inline blocking (IPS) can drop legitimate traffic, so start in alert-only mode.

```bash
sudo apt install -y suricata tcpdump
mkdir -p /tmp/s
cat > /tmp/s/local.rules <<'EOF'
alert http any any -> any any (msg:"LAB curl user-agent seen"; http.user_agent; content:"curl"; sid:1000001; rev:1;)
EOF
(cd /tmp && python3 -m http.server 8077 --bind 127.0.0.1 >/dev/null 2>&1 &)
sudo tcpdump -i lo -w /tmp/s/t.pcap port 8077 &
sleep 1; curl -s http://127.0.0.1:8077/ >/dev/null; sleep 1; sudo kill %1
sudo suricata -T -c /etc/suricata/suricata.yaml -S /tmp/s/local.rules
sudo suricata -r /tmp/s/t.pcap -S /tmp/s/local.rules -l /tmp/s -k none
grep LAB /tmp/s/fast.log
```

**Verify it worked.** Captured:

```text
i: suricata: Configuration provided was successfully loaded. Exiting.
10/17/2026-17:25:38.165514  [**] [1:1000001:1] LAB curl user-agent seen [**] [Classification: (null)] [Priority: 3] {TCP} 127.0.0.1:42872 -> 127.0.0.1:8077
```

Live monitoring (`suricata -i eth0` or the service) and rule feeds (`sudo suricata-update`) were not run.

**Acceptance criteria**

- [ ] `suricata -T` passes before every restart.
- [ ] Your custom rule fires on the test traffic and not on other traffic.
- [ ] You know where alerts go (`fast.log`, `eve.json`) and how to ship them to your SIEM (Task 6.8).

**Undo it:** `pkill -f "http.server 8077"; rm -r /tmp/s; sudo apt remove -y suricata`

**Troubleshooting**

- No alerts: wrong interface, checksum offloading (add `-k none` or `checksum-validation: no`), or encrypted traffic (HTTPS hides the payload).
- High CPU / dropped packets: tune `af-packet` threads and ruleset size.
- `rule ... failed to parse`: check keywords with `suricata --list-keywords`.

---

## Advanced

### Task 6.7: SELinux policy for a custom service

- **What you will learn:** the audit-driven workflow: run in permissive mode, collect denials, generate a minimal module, review it, load it. Never accept `audit2allow` output blindly.
- **Target distro:** RHEL family. **Risk level:** `can lock you out`: a loose policy removes protection; a missing rule breaks the service.

```bash
sudo semanage permissive -a httpd_t        # only this domain permissive, not the whole system
# ...exercise the application...
sudo ausearch -m avc -ts recent | audit2allow -M myapp-local
cat myapp-local.te                          # REVIEW every allow rule
sudo semodule -i myapp-local.pp
sudo semanage permissive -d httpd_t
```

**Verify it worked.** *Typical output* (not run):

```text
module myapp-local 1.0;
require { type httpd_t; type var_lib_t; class file { read open }; }
allow httpd_t var_lib_t:file { read open };
```

Prefer a boolean or a file label fix (`semanage fcontext`) over a custom module when one exists: `getsebool -a | grep httpd`.

**Acceptance criteria**

- [ ] The service works in enforcing mode with the module loaded.
- [ ] You can justify each `allow` line.
- [ ] No domain stays permissive.

**Undo it:** `sudo semodule -r myapp-local`

**Troubleshooting**

- Nothing in `ausearch`: `dontaudit` rules hide some denials; run `sudo semodule -DB` temporarily, and `-B` to restore.
- Still denied after the module: file labels are wrong; run `restorecon -Rv`.
- `audit2allow: command not found`: install `policycoreutils-python-utils`.

### Task 6.8: Central logging and detection: Wazuh, and Loki + Grafana

- **What you will learn:** agents ship logs to a central place where rules correlate them into alerts. **Wazuh** (open-source SIEM/XDR, HIDS, file integrity, vulnerability detection) is the usual choice. **Loki + Grafana** is a lighter log store you will also use for monitoring in [Step 7](step-07-system-monitoring.md). ELK/OpenSearch is the heavier alternative.
- **Target distro:** both. **Risk level:** `safe` in a lab, but the Wazuh all-in-one installer needs about 4 GB RAM and 2 vCPU, and agents send logs that can contain secrets.

Wazuh single-node quickstart on a spare VM (`curl -sO` the installer from the official docs, review it, then run; *not run here*):

```bash
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh
less wazuh-install.sh                         # read before running as root
sudo bash wazuh-install.sh -a                 # prints the admin password at the end
```

On a monitored host, add the agent from the dashboard ("Deploy new agent" shows a generated command), then check:

```bash
sudo systemctl status wazuh-agent
```

Detection example: after repeated SSH failures, the dashboard raises rule `5710`/`5712` (sshd brute force). Verify the version in the URL above against the Wazuh install guide before use.

**Verify it worked.** *Typical output* (not run): the agent shows `Active` in the dashboard and `Active: active (running)` for `wazuh-agent`.
Rule logic (counting failures per source) you can try right now in Task 4.7's report script.

**Acceptance criteria**

- [ ] At least two hosts report to the manager.
- [ ] A test of 5 failed SSH logins produces an alert.
- [ ] Agent-to-manager traffic is encrypted and the dashboard is not exposed to the internet.

**Undo it:** `sudo bash wazuh-install.sh -u` (uninstall) on the server, `sudo apt remove --purge wazuh-agent` on agents.

**Troubleshooting**

- Agent stuck `Never connected`: ports 1514/1515 blocked, or name/time mismatch.
- Installer fails on low RAM: use a VM with at least 4 GB.
- Alert noise: tune or disable specific rule IDs instead of the whole group.

### Task 6.9: Audit with Lynis

- **What you will learn:** run a hardening audit, read the report, fix findings, re-run and watch the score move. Lynis is read-only and agentless.
- **Target distro:** both (`sudo apt install -y lynis` / EPEL `lynis`). **Risk level:** `safe`: audit only. Fix suggestions are not automatic.

```bash
sudo apt install -y lynis
sudo lynis audit system --quick --no-colors
sudo grep -E '^(warning|suggestion)\[\]' /var/log/lynis-report.dat | head
```

Schedule weekly and keep the score:

```bash
echo '0 3 * * 0 root lynis audit system --cronjob > /var/log/lynis-weekly.log 2>&1' | sudo tee /etc/cron.d/lynis-weekly
```

**Verify it worked.** Captured on a fresh Ubuntu 24.04 container:

```text
  Warnings (2):
  Suggestions (40):
  Hardening index : 60 [############        ]
  Tests performed : 234
suggestion[]=DEB-0280|Install libpam-tmpdir to set $TMP and $TMPDIR for PAM sessions|-|-|
```

**Acceptance criteria**

- [ ] You fix at least five suggestions and the index rises.
- [ ] You can explain why you ignore some (and record them).
- [ ] OpenVAS/Greenbone is the next tool for network vulnerability scans; Lynis checks the host configuration.

**Undo it:** `sudo rm /etc/cron.d/lynis-weekly`

**Troubleshooting**

- Lower score in a container: many tests need a real kernel and services.
- `This release is more than 4 months old`: install the latest from the CISOfy repository or GitHub.
- Findings you cannot fix: add `skip-test=ID` to `/etc/lynis/custom.prf` with a comment.

### Task 6.10: Harden a systemd service

- **What you will learn:** sandboxing services with unit options, scored by `systemd-analyze security` (0 = best, 10 = worst).
- **Target distro:** both (systemd 250+ recommended). **Risk level:** `can lock you out` of the service: over-restriction makes it crash. Test and read `journalctl -u`.

```bash
cat > hard.service <<'EOF'
[Unit]
Description=Lab demo service
[Service]
ExecStart=/usr/bin/sleep 3600
DynamicUser=yes
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictAddressFamilies=AF_UNIX
RestrictNamespaces=yes
LockPersonality=yes
MemoryDenyWriteExecute=yes
SystemCallFilter=@system-service
SystemCallArchitectures=native
CapabilityBoundingSet=
EOF
printf '[Service]\nExecStart=/usr/bin/sleep 1\n' > plain.service
systemd-analyze security --offline=true plain.service | tail -1
systemd-analyze security --offline=true hard.service | tail -1
```

Apply to a real service with `sudo systemctl edit nginx` (a drop-in) rather than editing vendor files.

**Verify it worked.** Captured on systemd 259:

```text
→ Overall exposure level for plain.service: 9.4 UNSAFE 😨
→ Overall exposure level for hard.service: 1.7 OK 🙂
```

**Acceptance criteria**

- [ ] You raise a real service from "UNSAFE" to below 5.0 and it still works.
- [ ] You know what `ProtectSystem=strict` and `ReadWritePaths=` do.
- [ ] A drop-in file, not the vendor unit, carries your changes.

**Undo it:** `sudo systemctl revert SERVICE` (removes drop-ins).

**Troubleshooting**

- Service exits with `status=31/SYS` (SIGSYS): the syscall filter blocked a call. Loosen with `SystemCallFilter=~@privileged` or check `journalctl`.
- `Permission denied` writing: add `ReadWritePaths=/var/lib/app`.
- Needs a low port: `AmbientCapabilities=CAP_NET_BIND_SERVICE`.

### Task 6.11: Audit events with auditd

- **What you will learn:** the kernel audit trail: watch sensitive files and commands, search events.
- **Target distro:** both (`sudo apt install -y auditd`; RHEL: `audit`). **Risk level:** `safe`, but too many rules fill the disk and slow the system. Needs a real kernel (not run in containers).

```bash
sudo tee /etc/audit/rules.d/lab.rules >/dev/null <<'EOF'
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/ssh/sshd_config -p wa -k sshd
-w /etc/sudoers.d/ -p wa -k sudoers
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -F auid!=-1 -k root_cmds
EOF
sudo augenrules --load
sudo auditctl -l
sudo touch /etc/passwd
sudo ausearch -k identity -ts recent
```

**Verify it worked.** *Typical output*: `auditctl -l` lists your rules; `ausearch` shows `type=SYSCALL ... key="identity"` and the user's `auid`.

**Acceptance criteria**

- [ ] Changes to `/etc/passwd` produce an event tagged `identity`.
- [ ] Logs are forwarded to your SIEM (Task 6.8) and `max_log_file_action` is set.

**Undo it:** `sudo rm /etc/audit/rules.d/lab.rules && sudo augenrules --load`

**Troubleshooting**

- Rules not active: `auditctl -s` shows `enabled 2` when immutable; reboot to change.
- Disk fills: rotate with `max_log_file` and `num_logs` in `auditd.conf`.
- Missing `auid`: the process did not start from a login session.

---

## Step checklist

- [ ] 6.1 Firewall policy
- [ ] 6.2 SSH keys + hardening
- [ ] 6.3 SELinux / AppArmor
- [ ] 6.4 fail2ban
- [ ] 6.5 2FA (FIDO2/TOTP)
- [ ] 6.6 Suricata
- [ ] 6.7 SELinux custom policy
- [ ] 6.8 Wazuh / Loki
- [ ] 6.9 Lynis
- [ ] 6.10 systemd hardening
- [ ] 6.11 auditd

## Further reading

- [OpenSSH manual pages](https://www.openssh.com/manual.html): `sshd_config` options and their defaults.
- [Suricata documentation](https://docs.suricata.io/en/latest/): rules, outputs and tuning.
- [Wazuh documentation](https://documentation.wazuh.com/current/index.html): quickstart, agents, rules.
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks): free hardening checklists per distro.

**Next:** [Step 7: Monitoring](step-07-system-monitoring.md)
