# Step 12: Staying Updated

> **Time:** ongoing · **Level:** Beginner → Advanced
> **Prerequisites:** [Step 1](step-01-linux-fundamentals.md) · **Next:** none — this is the final step; see the capstone below.
> **Review this step every 3–6 months.** Linux moves fast; the point is to build the habit of checking the sources below.

<!-- -->

> [!NOTE]
> Every link below was verified to return HTTP 200 when this step was written. Links rot — if one returns 404, search the project name and find its current documentation page.

Conventions: see [Step 1](step-01-linux-fundamentals.md#how-to-read-each-task).

---

## 1. Reference and documentation (bookmark these)

These are the sources you should trust first, before blogs or videos.

| Resource | What you will find there | Link |
|----------|--------------------------|------|
| Linux man pages | The authoritative reference for every command, system call and file format | [man7.org](https://man7.org/linux/man-pages/) |
| systemd | Unit files, timers, journal, `systemd-analyze security` | [freedesktop.org systemd](https://www.freedesktop.org/software/systemd/) |
| Ubuntu Server docs | Package management, users, LVM, storage for Ubuntu | [ubuntu.com/server/docs](https://ubuntu.com/server/docs) |
| Red Hat docs | RHEL/Rocky/Alma: SELinux, LVM, DNF, users, systemd | [Red Hat customer portal docs](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/) |
| Debian reference | Debian-specific administration | [Debian reference](https://www.debian.org/doc/manuals/debian-reference/) |
| OpenSSH | `ssh_config`, `sshd_config`, keys, hardening | [OpenSSH manual](https://www.openssh.com/manual.html) |
| Podman | Rootless containers, images, Quadlet systemd units | [Podman docs](https://docs.podman.io/en/latest/) |
| Docker | Images, volumes, Compose | [Docker docs](https://docs.docker.com/) |
| Ansible | Playbooks, modules, inventories | [Ansible docs](https://docs.ansible.com/) |
| Terraform | Providers, state, `plan`/`apply` | [HashiCorp Terraform tutorials](https://developer.hashicorp.com/terraform/tutorials) |
| restic | Encrypted, deduplicated backups | [restic docs](https://restic.readthedocs.io/) |
| Suricata | IDS/IPS rules, outputs, tuning | [Suricata docs](https://docs.suricata.io/en/latest/) |
| Wazuh | HIDS/SIEM agents and rules | [Wazuh docs](https://documentation.wazuh.com/current/index.html) |
| Lynis | Host hardening audit | [Lynis (CISOfy)](https://cisofy.com/documentation/lynis/) |
| Grafana Loki | LogQL, Loki + Grafana | [Grafana Loki docs](https://grafana.com/docs/loki/latest/) |

## 2. News, blogs and podcasts

| Resource | Why read it | Link |
|----------|-------------|------|
| LWN.net | Weekly kernel and userspace development, deep and accurate | [LWN.net](https://lwn.net/) |
| Phoronix | Linux kernel, drivers, benchmarks and distro releases | [Phoronix](https://www.phoronix.com/) |
| Hacker News (Linux stories) | What practitioners are actually talking about | [news.ycombinator.com](https://news.ycombinator.com/) |
| /r/linux and /r/sysadmin | Community troubleshooting and tool tips | [reddit.com/r/sysadmin](https://www.reddit.com/r/sysadmin/) |

## 3. Certification paths

A certification is a structured study plan and a signal to employers, not a substitute for practice.

| Certification | Best for | What it covers | Link |
|---------------|----------|----------------|------|
| **RHCSA** (Red Hat Certified System Administrator) | RHEL/Rocky/Alma jobs | Users, storage, SELinux, systemd, networking, containers (Podman) | [Red Hat RHCSA](https://www.redhat.com/en/services/certification/rhcsa) |
| **LFCS** (Linux Foundation Certified SysAdmin) | Distro-neutral, performance-based | File operations, users, networking, services, containers | [Linux Foundation LFCS](https://training.linuxfoundation.org/certification/linux-foundation-certified-system-administrator-lfcs/) |
| **Linux+** (CompTIA) | Entry-level, vendor-neutral | Hardware, file management, security, scripting, troubleshooting | [CompTIA Linux+](https://www.comptia.org/certifications/linux) |

**Study tip:** pick one and build a lab that covers its exam objectives. For RHCSA, practice in AlmaLinux or Rocky (RHEL clones); for LFCS/Linux+, Ubuntu and Debian are fine.

## 4. Keep learning: home lab and contributing

- **Home lab:** one old PC or a cheap VPS, run Ubuntu Server and AlmaLinux side by side. Practise: SSH key-only login, a firewall (ufw/firewalld or nftables), a systemd service, a timer-based backup with a restore test, and a container. Snapshotting lets you break things safely.
- **Contribute:** fix a typo in a man page, improve this repository (see [CONTRIBUTING.md](../../CONTRIBUTING.md)), or package a tool for your distro. Your first pull request is the hardest; the second gets easier.
- **Re-run this path:** every 12–18 months, re-do a step on a newer release and notice what changed (systemd versions, package defaults, container runtimes).

## Capstone

When you finish Step 12, put it all together in the capstone: build and harden a web server, then monitor it and back it up with a tested restore.

- [Capstone: Secure Web Server](capstone-secure-web-server.md)

## Step checklist

- [ ] Bookmark man7.org and your distro's docs
- [ ] Pick a certification (RHCSA, LFCS, or Linux+) and list its exam objectives
- [ ] Stand up a two-distro home lab (Ubuntu + AlmaLinux/Rocky)
- [ ] Make one contribution (an issue, a docs fix, or a pull request)
- [ ] Complete the secure web server capstone

## Further reading

- [Linux Foundation Training](https://training.linuxfoundation.org/): courses and certifications.
- [Red Hat Certification](https://www.redhat.com/en/services/certification): RHCSA/RHCE exam details.
- [CompTIA Linux+](https://www.comptia.org/certifications/linux): vendor-neutral Linux certification.
- [CONTRIBUTING guide for this repo](../../CONTRIBUTING.md): how to improve these lessons.

**Previous:** [Step 11: Virtualization and Containers](step-11-virtualization-and-containers.md)
