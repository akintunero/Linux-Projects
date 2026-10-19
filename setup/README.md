# Set up your practice lab

Everything in this repository is meant to be **typed and run**, not just read. Do it somewhere you cannot
hurt anything. Pick the option that matches your computer.

| Your computer | Recommended lab | Time |
|---------------|-----------------|------|
| Any (Windows, macOS, Linux) with Docker | [Dev container](#option-1-dev-container-fastest) | 5 min |
| Windows 10/11 | [WSL 2 + Ubuntu](#option-2-windows-wsl-2) | 10 min |
| Any, when you need `systemd`, kernel or disk lessons | [A virtual machine with Vagrant](vagrant/README.md) | 20 min |
| Linux desktop | Your own machine, with care: read every `sudo` command first | 0 min |

> [!WARNING]
> Security, firewall, SSH, disk and user-management lessons can lock you out of a machine or destroy
> data. Use a lab that you can delete and recreate. Never practise them on a server that other people
> rely on.

## Option 1: Dev container (fastest)

You get a clean Ubuntu 24.04 with every tool the lessons use (`shellcheck`, `bats`, `jq`, `tmux`,
`nmap`, `ufw`, `nftables`, `fail2ban`, `lynis` and more) and passwordless `sudo` inside the container.

1. Install [Docker Desktop](https://docs.docker.com/get-docker/) (or Docker Engine) and
   [VS Code](https://code.visualstudio.com/) with the *Dev Containers* extension.
2. Open this repository in VS Code and choose **Reopen in Container**.
3. Check it works:

   ```bash
   bash --version
   shellcheck --version
   make check
   ```

Without VS Code, build and enter it by hand:

```bash
docker build -t linux-projects .devcontainer
docker run -it --rm -v "$PWD":/workspaces/Linux-Projects linux-projects
```

**Limits.** A container shares the host kernel and has no `systemd` by default. Lessons on services,
timers, partitions, LVM or kernel modules need a [virtual machine](vagrant/README.md).

## Option 2: Windows WSL 2

In an administrator PowerShell:

```powershell
wsl --install -d Ubuntu
```

Restart, open *Ubuntu* from the Start menu, then inside it:

```bash
sudo apt-get update
sudo apt-get install -y git make bats shellcheck shfmt jq
git clone https://github.com/akintunero/Linux-Projects.git
cd Linux-Projects
make check
```

Work inside the Linux file system (`~/`), not under `/mnt/c`: it is much faster and avoids permission
and line-ending surprises.

## Option 3: A virtual machine

See [vagrant/README.md](vagrant/README.md) for a disposable Ubuntu VM on Intel/AMD and on Apple Silicon.

## Which lessons need what

| Lesson area | Dev container | WSL 2 | VM |
|-------------|:-------------:|:-----:|:--:|
| Bash scripting, text processing | yes | yes | yes |
| Users, groups, permissions | yes | yes | yes |
| Firewall (`ufw`, `nftables`) | partly | partly | yes |
| `systemd` units and timers | no | yes (enabled in recent WSL) | yes |
| Disks, LVM, RAID, mounts | no | no | yes |
| Networking beyond the loopback | partly | partly | yes |
