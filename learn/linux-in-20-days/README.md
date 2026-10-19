# Linux in 20 Days — Syllabus

A 20-day, hands-on introduction to Linux for learners who have never opened a
terminal. Each day is a self-contained lesson with a goal, concepts you can
type and verify, exercises with acceptance criteria, and tested solutions.
Everything runs in WSL 2, a virtual machine or the devcontainer — never on your
daily machine.

## Outcomes

By the end of the course you can:

- Navigate the shell, manage files and permissions, and read system documentation.
- Install and update software on Debian/Ubuntu and RHEL-family systems.
- Read processes, users, networking and storage, and troubleshoot what is broken.
- Run services under systemd, schedule work with cron and timers, back data up
  and restore it from a tested backup.
- Harden SSH, use the firewall, and run a small container.

## Prerequisites

- A computer with internet access, and the ability to install software.
- One of: [WSL 2](https://learn.microsoft.com/en-us/windows/wsl/install) (Windows),
  VirtualBox or VMware with an Ubuntu/Rocky ISO, or the repository
  [devcontainer](../../.devcontainer/) (Docker + VS Code).
- About 45–90 minutes per day, for twenty days.

No prior Linux experience is assumed.

## Set up your lab

Follow the steps in [../../setup/README.md](../../setup/README.md) to prepare
your environment before Day 01. Days that need root, a real disk or a real
service say so at the top — use a VM with a snapshot for those.

## Course plan

| Day | Topic | Time | Skills |
|-----|-------|------|--------|
| [Day 01](day-01.md) | What Linux Is, Your Lab, and Your First Commands | ~45 min | Kernel vs distribution vs shell, `uname`, `/etc/os-release`, `type`, `man` vs `help` |
| [Day 02](day-02.md) | Working With Files and Directories | ~45 min | `ls`, `cd`, `pwd`, `cp`, `mv`, `rm`, `mkdir`, wildcards, quoting |
| [Day 03](day-03.md) | The Filesystem Hierarchy, Paths and Links | ~45 min | `/etc`, `/var`, `/home`, absolute vs relative paths, `ln -s`, `namei` |
| [Day 04](day-04.md) | Permissions, Ownership and umask | ~60 min | `chmod`, `chown`, `chgrp`, `umask`, setuid/setgid/sticky bit |
| [Day 05](day-05.md) | Editing Files With nano and vim | ~60 min | `nano`, `vim` basics, opening, saving, quitting |
| [Day 06](day-06.md) | Finding Things, Pipes and Redirection | ~60 min | `grep`, `find`, `locate`, redirection operators, `tee` |
| [Day 07](day-07.md) | Text Processing With awk, sed and jq | ~60 min | `awk`, `sed`, `jq`, columns, filtering, JSON |
| [Day 08](day-08.md) | Disks, Filesystems, Mounting and LVM | ~75 min | `lsblk`, `df`, `mount`, `fstab`, `mkfs`, LVM basics (loopback files) |
| [Day 09](day-09.md) | Package Management (APT and DNF) | ~60 min | `apt`, `dnf`, repositories, updates, searching packages |
| [Day 10](day-10.md) | Processes, Signals and Job Control | ~60 min | `ps`, `top`, `kill`, signals, `&`, `fg`, `bg`, `nohup` |
| [Day 11](day-11.md) | Users, Groups and sudo | ~60 min | `useradd`, `usermod`, `groupadd`, `/etc/passwd`, `sudo`, `su` |
| [Day 12](day-12.md) | Networking Basics and Connectivity Checks | ~75 min | `ip`, `ss`, `ping`, `curl`, DNS, `traceroute`, ports |
| [Day 13](day-13.md) | Monitoring CPU, Memory, Disk and Load | ~60 min | `uptime`, `vmstat`, `free`, `df -i`, `ps` sorted by CPU/memory |
| [Day 14](day-14.md) | Backups, Archives and Safe Automation | ~75 min | `tar`, `rsync`, `cron`, `crontab`, 3-2-1 rule, restore test |
| [Day 15](day-15.md) | systemd Services and the Journal | ~75 min | unit files, `systemctl`, `journalctl`, `Restart=`, enabling services |
| [Day 16](day-16.md) | Scheduling With cron and systemd Timers | ~75 min | `crontab`, systemd timers, environment pitfalls, logging |
| [Day 17](day-17.md) | Remote Work With SSH, Tunnels and tmux | ~90 min | `ssh`, keys, `ssh-agent`, port forwarding, `tmux` sessions |
| [Day 18](day-18.md) | Containers With Podman | ~75 min | images, containers, volumes, `USER`, rootless, Quadlet services |
| [Day 19](day-19.md) | Troubleshooting: "Something Is Broken, Now What?" | ~75 min | five-step method, exit statuses, `ss`, `journalctl`, `bash -x` |
| [Day 20](day-20.md) | Capstone — Run, Back Up, and Recover a Web Service | ~90 min | user systemd service, health check, timer backup, verified restore, failure drill |

## Progress checklist

Tick each box when you finish the day and its exercises.

- [ ] Day 01 — What Linux Is, Your Lab, and Your First Commands
- [ ] Day 02 — Working With Files and Directories
- [ ] Day 03 — The Filesystem Hierarchy, Paths and Links
- [ ] Day 04 — Permissions, Ownership and umask
- [ ] Day 05 — Editing Files With nano and vim
- [ ] Day 06 — Finding Things, Pipes and Redirection
- [ ] Day 07 — Text Processing With awk, sed and jq
- [ ] Day 08 — Disks, Filesystems, Mounting and LVM
- [ ] Day 09 — Package Management (APT and DNF)
- [ ] Day 10 — Processes, Signals and Job Control
- [ ] Day 11 — Users, Groups and sudo
- [ ] Day 12 — Networking Basics and Connectivity Checks
- [ ] Day 13 — Monitoring CPU, Memory, Disk and Load
- [ ] Day 14 — Backups, Archives and Safe Automation
- [ ] Day 15 — systemd Services and the Journal
- [ ] Day 16 — Scheduling With cron and systemd Timers
- [ ] Day 17 — Remote Work With SSH, Tunnels and tmux
- [ ] Day 18 — Containers With Podman
- [ ] Day 19 — Troubleshooting: "Something Is Broken, Now What?"
- [ ] Day 20 — Capstone — Run, Back Up, and Recover a Web Service

## How the lessons work

Each day follows the same structure:

1. **Goal** — three verifiable things you can do by the end.
2. **Concepts** — short explanations, each followed by a command to type.
3. **Worked example** — a realistic scenario you reproduce, with expected output.
4. **Common mistakes** — a table of mistake, why it fails, and the fix.
5. **Exercises** — Easy, Medium and Hard, each with acceptance criteria, plus a
   "Break it" script with bugs to find and fix.
6. **Solutions** — collapsed `<details>` blocks; full scripts live in
   `solutions/day-NN/` and pass ShellCheck.
7. **Self-check** — five quick questions with collapsed answers.
8. **Cheat sheet** — the commands from the lesson.
9. **Further reading** — official documentation links, each with a one-line note.
10. **Next / Previous** — links to the neighbouring days.

All commands are copy-pasteable. Anything that can lock you out, delete data or
change the system carries a `> [!WARNING]` before it and an undo step after it.

Scripting practice continues in the companion course:
[30 Days of Bash](../30-days-of-bash/README.md).

## License

This project is licensed under the MIT License.
