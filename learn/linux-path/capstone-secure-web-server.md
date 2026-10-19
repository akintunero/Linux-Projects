# Capstone: Build and Harden a Secure Web Server

> **Time:** ~8-10 hours · **Level:** Intermediate → Advanced
> **Prerequisites:** [Step 6](step-06-system-security.md), [Step 7](step-07-system-monitoring.md), [Step 8](step-08-disk-mgmnt.md), [Step 9](step-09-backup-and-recovery.md), [Step 10](step-10-automation.md), [Step 11](step-11-virtualization-and-containers.md)

## Scenario

You are given a fresh Ubuntu 24.04 or AlmaLinux 9 VM with root access and a public IP. Your job: stand up a small HTTPS web server, harden it, monitor it, and back it up — then prove the backup works with a restore test.

Everything below is written for a real VM or a privileged container (the earlier steps already ran in containers; this capstone needs networking, a listening port and a web server, so it *must* run on a VM or a container with `systemd` and `root`). Marked output is *typical* where it could not be captured.

> [!WARNING]
> You are opening a port to the network, installing software as root, changing SSH, and running a firewall. Do this only on a throwaway VM or cloud instance you can delete. Take a snapshot first. Keep a second SSH session open while changing SSH or firewall rules — never close the working session until a new key-based login is proven.

---

## Phase 1: Prepare the VM and a non-root admin user

### Task C.1: Create a sudo user and lock root password login

- **What you will learn:** `adduser`, `usermod`, `sudoers`, and disabling direct root SSH.
- **Target distro:** both (`useradd`/`usermod` are the same; `sudo` group is `sudo` on Debian/Ubuntu, `wheel` on RHEL).
- **Risk level:** `can lock you out` — test `sudo` before you close your root session.

```bash
# Run as root on the fresh VM
sudo adduser deploy               # Debian: adduser; RHEL: useradd -m deploy && passwd deploy
usermod -aG sudo deploy           # RHEL: usermod -aG wheel deploy

# Test sudo in a SECOND shell before touching root login
su - deploy                       # or open a new SSH session as deploy
sudo -n true && echo "sudo works"
```

**Verify it worked:** `sudo -n true` returns 0 and `groups deploy` shows `sudo` (or `wheel`).

**Undo it:** `sudo deluser --remove-home deploy` (Debian) / `sudo userdel -r deploy` (RHEL).

**Troubleshooting:**

- `deploy is not in the sudoers file`: you misspelled the group (`sudo` vs `wheel`). Check `getent group sudo wheel`.
- `su: Authentication failure`: set a password first with `sudo passwd deploy`.

### Task C.2: SSH key-only access for the admin user

- **What you will learn:** `ssh-keygen`, `ssh-copy-id`, `sshd_config.d` hardening, `sshd -t`, and the second-session safety net.
- **Target distro:** both. Service: `ssh` (Debian/Ubuntu) or `sshd` (RHEL).
- **Risk level:** `can lock you out`. Keep your current root session open.

On your **workstation**:

```bash
VM_IP=192.0.2.10   # replace with your VM's real address (find it with: ip -br addr)
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/lab-web -C "deploy@webserver"
ssh-copy-id -i ~/.ssh/lab-web.pub "deploy@$VM_IP"
ssh -i ~/.ssh/lab-web -o PasswordAuthentication=no "deploy@$VM_IP" true && echo "key login works"
```

On the **server** (as deploy, using sudo):

```bash
sudo tee /etc/ssh/sshd_config.d/90-capstone.conf >/dev/null <<'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
AllowUsers deploy
EOF
sudo sshd -t && sudo systemctl reload ssh          # RHEL: sshd
```

*Do not close your root session.* Open a third terminal and confirm `ssh -i ~/.ssh/lab-web deploy@<VM-IP>` works before logging out of root.

**Verify it worked:**

- `sudo sshd -t` is clean.
- Key login succeeds; `ssh -o PasswordAuthentication=no deploy@<VM-IP> true` returns 0.
- `sudo sshd -T | grep -E 'permitrootlogin|passwordauthentication'` shows `no`.

**Undo it:** `sudo rm /etc/ssh/sshd_config.d/90-capstone.conf && sudo systemctl reload ssh`; this re-enables password login (only safe on a trusted lab network).

**Troubleshooting:**

- `Permission denied (publickey)`: `~/.ssh` must be `700`, `authorized_keys` `600`, home not group-writable; check `journalctl -u ssh`.
- Locked out: use the cloud console or VM console as root, remove the drop-in, reload.

---

## Phase 2: Web server, nftables firewall, TLS

### Task C.3: Install and serve a static site (loopback first)

- **What you will learn:** install nginx/apache, serve a page, confirm it listens on `127.0.0.1` only before opening the firewall.
- **Target distro:** both. Debian: `nginx`; RHEL: `nginx` or `httpd`.
- **Risk level:** `safe` (loopback only).

Debian/Ubuntu:

```bash
sudo apt update && sudo apt install -y nginx
echo "<h1>capstone secure web</h1>" | sudo tee /var/www/html/index.html
# The stock site has two listen lines (IPv4 and IPv6). Remove the IPv6 one and bind IPv4 to
# loopback; rewriting both would create a duplicate default_server and nginx would refuse to load.
sudo sed -i -e '/listen \[::\]:80 default_server;/d' \
  -e 's/listen 80 default_server;/listen 127.0.0.1:80 default_server;/' /etc/nginx/sites-available/default
sudo nginx -t
sudo systemctl reload nginx
curl -s http://127.0.0.1/
ss -ltnp 'sport = :80'
```

**Verify it worked:** `curl http://127.0.0.1/` returns `<h1>capstone secure web</h1>`; `ss` shows nginx listening on `127.0.0.1:80` only.

**Undo it:** `sudo systemctl stop nginx; sudo apt remove -y nginx`.

**Troubleshooting:**

- `curl: connection refused`: nginx not started or listening elsewhere — `sudo ss -ltnp | grep nginx`.
- Default site conflict: remove `/etc/nginx/sites-enabled/default` and use your own site file.

### Task C.4: nftables firewall (default-deny, SSH + HTTPS only)

- **What you will learn:** write an nftables ruleset, load it, make it persistent, and confirm only 22 and 443 are reachable.
- **Target distro:** both (`nftables` is the backend; ufw/firewalld sit on top — use nftables directly here).
- **Risk level:** `can lock you out`. Allow SSH (22) **before** enabling, and keep a session open.

```bash
sudo apt install -y nftables       # RHEL: sudo dnf install -y nftables
sudo tee /etc/nftables.conf >/dev/null <<'EOF'
flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        iif "lo" accept
        ct state established,related accept
        ct state invalid drop
        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept
        tcp dport 22 accept        # SSH — keep your session open
        tcp dport 443 accept       # HTTPS
    }
    chain forward {
        type filter hook forward priority 0; policy drop;
    }
    chain output {
        type filter hook output priority 0; policy accept;
    }
}
EOF

sudo nft -f /etc/nftables.conf
sudo nft list ruleset
```

Make it persistent (Debian: `systemctl enable --now nftables`; RHEL: `systemctl enable --now nftables`).

> Opening 443 before TLS is ready is fine — clients will get a TLS error until Task C.5 configures the certificate. Do not open port 80 permanently; redirect it to 443 if you keep it.

**Verify it worked:** From another host: `nmap -Pn -p 22,443,80,3306 <VM-IP>` shows 22/443 open, 80/3306 filtered. From the VM: `sudo nft list ruleset` shows `tcp dport 22 accept` and `tcp dport 443 accept`.

**Acceptance criteria:**

- [ ] SSH (22) and HTTPS (443) reachable; everything else dropped.
- [ ] Rules survive a reboot (`nftables` service enabled).

**Undo it:** `sudo nft flush ruleset; sudo systemctl disable --now nftables`.

**Troubleshooting:**

- Locked out: console in, `sudo nft flush ruleset`.
- Docker published ports bypass nftables: do not run Docker on this capstone VM, or bind containers to `127.0.0.1` only.

### Task C.5: TLS with a local CA (self-signed) — or Let's Encrypt if you have a domain

- **What you will learn:** generate a key and certificate, configure nginx HTTPS, force HTTPS, and test with `curl -k` (local CA) or a real cert.
- **Target distro:** both. `openssl` is built in.
- **Risk level:** `safe` (local CA is fine for a lab; browsers will warn — that is expected).

**Option A: local CA (works without a domain).** As root:

```bash
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/capstone.key \
  -out /etc/nginx/ssl/capstone.crt \
  -subj "/CN=web.capstone.local"
sudo chmod 600 /etc/nginx/ssl/capstone.key
```

Add a server block (Debian: `/etc/nginx/sites-available/capstone`; symlink into `sites-enabled`; RHEL: `/etc/nginx/conf.d/capstone.conf`):

```nginx
server {
    listen 80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl default_server;
    server_name web.capstone.local;
    ssl_certificate     /etc/nginx/ssl/capstone.crt;
    ssl_certificate_key /etc/nginx/ssl/capstone.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    location / {
        root /var/www/html;
        index index.html;
    }
}
```

```bash
sudo nginx -t
sudo systemctl reload nginx
curl -sk https://127.0.0.1/            # -k: trust the self-signed cert in the lab
```

**Verify it worked:** `curl -sk https://127.0.0.1/` returns the page; `curl -s -o /dev/null -w "%{http_code}" https://127.0.0.1/` is `200`; port 80 redirects to 443 (`curl -sI http://127.0.0.1/` shows `301`).

**Option B: Let's Encrypt (real domain).** If you own `web.example.com` pointing at this VM:

```bash
sudo apt install -y certbot python3-certbot-nginx   # RHEL: certbot + nginx plugin from EPEL
sudo certbot --nginx -d web.example.com --non-interactive --agree-tos -m you@example.com
```

Certbot edits nginx for you and sets up auto-renewal via a systemd timer/cron. `curl -v https://web.example.com/` shows a valid cert.

**Acceptance criteria:**

- [ ] HTTPS serves on 443 and the certificate is presented (self-signed is fine for the lab).
- [ ] HTTP (80) redirects to HTTPS.
- [ ] The private key is mode `600` and readable only by root.

**Undo it:** remove the site block, `sudo systemctl reload nginx`, `sudo rm -rf /etc/nginx/ssl`.

**Troubleshooting:**

- `nginx: [emerg] cannot load certificate`: path or permissions wrong — `ls -l /etc/nginx/ssl`.
- Certbot fails: DNS is not pointed at this VM yet, or port 80 is blocked by the firewall.

---

## Phase 3: Systemd hardening

### Task C.6: Harden the nginx unit with systemd sandboxing

- **What you will learn:** `systemd-analyze security`, `ProtectSystem=strict`, `NoNewPrivileges`, `PrivateTmp`, and raising a service from UNSAFE to below 5.0.
- **Target distro:** both (systemd).
- **Risk level:** `can lock you out` of the service — over-restriction makes nginx fail to start; read `journalctl -u nginx`.

```bash
systemd-analyze security nginx.service | tail -n 1
```

*Typical output:* `Overall exposure level for nginx.service: 7.x UNSAFE`.

Create a drop-in (never edit the vendor unit):

```bash
sudo systemctl edit nginx.service
```

Paste:

```ini
[Service]
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
RestrictNamespaces=yes
LockPersonality=yes
MemoryDenyWriteExecute=yes
SystemCallFilter=@system-service
SystemCallArchitectures=native
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
ReadWritePaths=/var/log/nginx /var/lib/nginx
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart nginx
systemd-analyze security nginx.service | tail -n 1
curl -sk https://127.0.0.1/ && echo "still serving"
```

**Verify it worked:** the exposure number drops below 5.0 (`OK` range), and `curl` still gets the page.

**Acceptance criteria:**

- [ ] Exposure below 5.0.
- [ ] HTTPS still serves after the restart.
- [ ] Changes are in a drop-in (`systemctl cat nginx.service` shows the drop-in lines), not the vendor file.

**Undo it:** `sudo systemctl revert nginx.service`.

**Troubleshooting:**

- `nginx` fails to start (`status=31/SYS`): the syscall filter blocked something — check `journalctl -u nginx` and loosen `SystemCallFilter`.
- `Permission denied` writing logs: add the path to `ReadWritePaths`.

---

## Phase 4: Monitor it (metrics and logs)

### Task C.7: Node exporter + Grafana Loki for metrics and logs

- **What you will learn:** run Prometheus node_exporter to expose system metrics, push nginx access logs to Loki, and query both in Grafana.
- **Target distro:** both (node_exporter binary; Docker/Podman for Grafana+Loki).
- **Risk level:** `safe` (bind to `127.0.0.1` so metrics are not public).

```bash
# node_exporter (system service)
sudo useradd -rs /bin/false node_exporter 2>/dev/null || true
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xzf node_exporter-*.tar.gz
sudo cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/
sudo tee /etc/systemd/system/node_exporter.service >/dev/null <<'EOF'
[Unit]
Description=Prometheus node_exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address=127.0.0.1:9100

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable --now node_exporter
curl -s http://127.0.0.1:9100/metrics | head -n 5
```

Send nginx access logs to Loki via the HTTP API (run Grafana+Loki in Podman/Docker on `127.0.0.1`, or skip the GUI and just confirm Loki accepts a line):

```bash
# Push one test line to Loki (adjust the URL if you run Loki elsewhere)
curl -s -X POST 127.0.0.1:3100/loki/api/v1/push \
  --data-urlencode 'stream={job="capstone-web"}' \
  --data-urlencode 'entries="'"$(date '+%F %T')"' capstone web up"' | head -c 120; echo
```

**Verify it worked:** `curl http://127.0.0.1:9100/metrics` returns `node_` metrics; Loki accepts the push (204 or `{status":"success"}`).

**Acceptance criteria:**

- [ ] `node_exporter` is enabled and `curl :9100/metrics` works.
- [ ] You can name one metric (e.g. `node_cpu_seconds_total`) and one log label (`job`).

**Undo it:** `sudo systemctl disable --now node_exporter; sudo rm /usr/local/bin/node_exporter /etc/systemd/system/node_exporter.service`.

**Troubleshooting:**

- `curl :9100` connection refused: service not started — `sudo systemctl status node_exporter`.
- Loki push rejected: Loki not running on port 3100, or the JSON payload is malformed.

---

## Phase 5: Back it up, then restore and prove it

### Task C.8: Backup the web root and nginx config with a tested restore

- **What you will learn:** `tar` + `sha256sum`, restore to a fresh directory, compare, and log the result.
- **Target distro:** both.
- **Risk level:** `safe` (restores to `/tmp`, never over live data).

```bash
# /root is readable by root only (good: the archive contains your TLS private key).
# Name the archive once in a variable. Globs are NOT expanded in redirect targets or
# assignments, and your normal user cannot expand a glob inside /root anyway.
archive=/root/capstone-backup-$(date +%Y%m%d-%H%M%S).tar.gz
sudo tar -czf "$archive" /etc/nginx /var/www/html
sudo sha256sum "$archive" | sudo tee "$archive.sha256" >/dev/null
sudo sha256sum -c "$archive.sha256"
```

Restore test (same terminal, so `$archive` is still set; `sudo` is needed to read the private key):

```bash
sudo rm -rf /tmp/capstone-restore && mkdir /tmp/capstone-restore
sudo tar -xzf "$archive" -C /tmp/capstone-restore
sudo diff -r /etc/nginx /tmp/capstone-restore/etc/nginx && \
sudo diff -r /var/www/html /tmp/capstone-restore/var/www/html && \
echo "RESTORE TEST PASSED" | sudo tee -a /var/log/capstone-restore-tests.log
```

**Verify it worked:** `sha256sum -c` is OK and both `diff -r` commands are silent (trees match).

**Acceptance criteria:**

- [ ] Archive and `.sha256` exist under `/root`.
- [ ] `sha256sum -c` passes.
- [ ] `diff -r` original vs restored is clean for both `/etc/nginx` and `/var/www/html`.
- [ ] `/var/log/capstone-restore-tests.log` has a `RESTORE TEST PASSED` line.

**Undo it:** `rm -rf /tmp/capstone-restore`; keep the archive (it is your backup) or remove it when done.

**Troubleshooting:**

- `diff` reports differences: something changed between backup and restore — re-backup and re-test.
- `sha256sum` fails: the archive was modified after checksumming — re-create both.

---

## Grading rubric (100 points)

Have a peer (or yourself) check each item. The command shown is the proof.

| # | Requirement | Points | Verification command |
|---|-------------|--------|----------------------|
| 1 | `deploy` sudo user exists; root SSH disabled | 10 | `getent group sudo wheel` lists `deploy`; `sshd -T` shows `permitrootlogin no` |
| 2 | Key-only SSH works; password login refused | 10 | `ssh -i lab-web -o PasswordAuthentication=no deploy@IP true` = 0 |
| 3 | nftables default-deny; only 22/443 open | 15 | `sudo nft list ruleset` shows `tcp dport 22 accept`, `tcp dport 443 accept`; policy drop |
| 4 | HTTPS serves on 443, HTTP redirects to it | 10 | `curl -sk https://127.0.0.1/` = page; `curl -sI http://127.0.0.1/` = 301 |
| 5 | Private key mode 600, root-only | 5 | `stat -c '%a %U' /etc/nginx/ssl/capstone.key` = `600 root` |
| 6 | systemd security below 5.0, site still up | 15 | `systemd-analyze security nginx.service` < 5.0; `curl -sk https://127.0.0.1/` = 200 |
| 7 | node_exporter serving metrics on :9100 | 10 | `curl -s http://127.0.0.1:9100/metrics \| head -1` |
| 8 | Backup archive + checksum exist and verify | 10 | `sudo sha256sum -c "$archive.sha256"` |
| 9 | Restore test passes (`diff -r` clean) | 10 | `diff -r /etc/nginx /tmp/capstone-restore/etc/nginx` and `/var/www/html` |
| 10 | Restore test logged with date | 5 | `grep "RESTORE TEST PASSED" /var/log/capstone-restore-tests.log` |
| | **Total** | **100** | |

80+ points is a pass. Below 80, fix the failing phase and re-test.

---

## What to hand in

- The VM's IP and a snapshot name.
- The output of each verification command above (copy/paste).
- The `nftables.conf`, the nginx site block, the nginx systemd drop-in, and the backup archive.
- The restore-test log entry.

**Next:** you have finished the Linux path. Re-run any step on a newer release annually, keep contributing, and consider [RHCSA](https://www.redhat.com/en/services/certification/rhcsa), [LFCS](https://training.linuxfoundation.org/certification/linux-foundation-certified-system-administrator-lfcs/) or [Linux+](https://www.comptia.org/certifications/linux).
