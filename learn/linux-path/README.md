# Linux Path — 12-Step Syllabus

A hands-on path from first terminal to job-ready Linux administrator. Each step is a directory
containing tasks with **what you will learn**, **target distro**, **risk level and warning**,
**copy-pasteable commands**, **verify it worked**, **undo it**, and **troubleshooting**. Work in a
throwaway VM or the devcontainer — never on a machine holding data you cannot lose.

## How to use this path

1. Set up a lab: a VM with Ubuntu 24.04 LTS or AlmaLinux/Rocky 9 (take a snapshot first), or the
   [repository devcontainer](../../.devcontainer/). See [../../setup/README.md](../../setup/README.md).
2. Work the steps in order. Each step's tasks build on the last.
3. Tick the progress checklist as you finish each step.
4. Finish with the [capstone](#capstone-secure-web-server): build and harden a web server, monitor it,
   and back it up with a tested restore.
5. Keep going with [30 Days of Bash](../30-days-of-bash/README.md) for deeper scripting, and [Step 12](step-12-staying-updated.md)
   for certifications (RHCSA, LFCS, Linux+) and a home lab.

Every risky command carries a `> [!WARNING]` before it and an undo step after it.

## The 12 steps

| # | Step | Time | What you will do |
|---|------|------|------------------|
| 1 | [Linux Fundamentals](step-01-linux-fundamentals.md) | ~6–8 h | Filesystem, permissions, `chmod`/`chown`, ACLs, first script, quotas on a loop device, chroot |
| 2 | [Users and Groups](step-02-user-and-group-mgmnt.md) | ~6–8 h | Accounts, groups, `sudo`, password policy, SSH basics |
| 3 | [Networking Basics](step-03-networking-basics.md) | ~6–8 h | `ip`, `ss`, DNS, DHCP, `curl`, nftables/ufw/firewalld firewall |
| 4 | [Shell Scripting for Administrators](step-04-shell-scripting.md) | ~6–8 h | `set -euo pipefail`, quoting, cron backups, log monitoring (full language: [30 Days of Bash](../30-days-of-bash/README.md)) |
| 5 | [Package Management](step-05-package-mgmnt.md) | ~6–8 h | `apt`/`dnf`, repositories, local packages, package ownership |
| 6 | [System Security](step-06-system-security.md) | ~10–12 h | SSH key-only hardening, nftables/ufw/firewalld, fail2ban, TOTP/FIDO2, auditd, Suricata, Wazuh/Lynis, SELinux + audit2allow, systemd hardening |
| 7 | [System Monitoring](step-07-system-monitoring.md) | ~8–10 h | `top`/`htop`/`vmstat`/`iostat`/`ss`, journald, Prometheus node_exporter, Grafana + Loki, alerts, log rotation |
| 8 | [Disk Management](step-08-disk-mgmnt.md) | ~8–10 h | Partitions, filesystems, fstab, LVM, RAID with mdadm, quotas, SMART, LUKS (loopback files — no real disk touched) |
| 9 | [Backup and Recovery](step-09-backup-and-recovery.md) | ~8–10 h | `rsync`, `tar`, restic, snapshots, cron vs systemd timers, 3-2-1 rule, mandatory restore test |
| 10 | [Automation](step-10-automation.md) | ~8–10 h | cron, systemd timers, Ansible, Terraform, GitHub Actions for shell projects |
| 11 | [Virtualization and Containers](step-11-virtualization-and-containers.md) | ~8–10 h | KVM/libvirt, Docker and Podman, rootless, images/volumes, compose, image hardening |
| 12 | [Staying Updated](step-12-staying-updated.md) | ongoing | Curated link-verified resources, cert paths (RHCSA, LFCS, Linux+), home lab, contributing |

## Step → certification objective map

Use this to target a certification while you work the path.

| Step | RHCSA objective areas | LFCS objective areas | Linux+ objective areas |
|------|----------------------|----------------------|------------------------|
| 1 Users & permissions | Users/groups, ACLs, permissions | File management, permissions | Users, groups, permissions |
| 2 User administration | User/group management, sudo | Users and groups | Identity and access |
| 3 Networking | IPv4/IPv6, hostname, firewall | Networking, firewalls | Network fundamentals |
| 4 Scripting | Bash scripting basics | Shell scripting | Scripting and automation |
| 5 Packages | `dnf`, repositories | Software management | Package management |
| 6 Security | SELinux, firewall, sshd | Security, SSH | Security, hardening |
| 7 Monitoring | `sar`, systemd, logging | Monitoring, logging | System operations |
| 8 Storage | LVM, partitions, filesystems | Storage management, disks | Storage and filesystems |
| 9 Backup | Backup/restore | Backup strategies | Disaster recovery |
| 10 Automation | `cron`, systemd timers | Ansible fundamentals | Automation, IaC |
| 11 Containers/Virt | KVM, containers | Containers, virtualization | Virtualization and containers |
| 12 Continuing | RHCSA exam prep | LFCS exam prep | Linux+ exam prep |

## Progress checklist

Tick each box when you finish the step and its tasks.

- [ ] Step 1 — Linux Fundamentals
- [ ] Step 2 — Users and Groups
- [ ] Step 3 — Networking Basics
- [ ] Step 4 — Shell Scripting for Administrators
- [ ] Step 5 — Package Management
- [ ] Step 6 — System Security
- [ ] Step 7 — System Monitoring
- [ ] Step 8 — Disk Management
- [ ] Step 9 — Backup and Recovery
- [ ] Step 10 — Automation
- [ ] Step 11 — Virtualization and Containers
- [ ] Step 12 — Staying Updated
- [ ] Capstone — Secure Web Server

## Capstone: Secure Web Server

Put everything together: users and `sudo`, SSH key-only login, an nftables firewall, TLS, systemd
hardening, monitoring (metrics and logs), and a backup with a tested restore. Includes a numbered
grading checklist with points and exact verification commands.

- [Capstone: Build and Harden a Secure Web Server](capstone-secure-web-server.md)

## License

This project is licensed under the MIT License.
