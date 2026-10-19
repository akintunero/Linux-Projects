# Step 11: Virtualization and Containers

> **Time:** ~8-10 hours · **Level:** Beginner → Advanced
> **Prerequisites:** [Step 3](step-03-networking-basics.md), [Step 6](step-06-system-security.md) · **Next:** [Step 12: Staying Updated](step-12-staying-updated.md)

<!-- -->

> [!WARNING]
> Virtual machines and containers consume real RAM and disk. Privileged containers and KVM need root or group membership (`libvirt`, `docker`). A container escape or `--privileged` can affect the host — use rootless containers and never mount `/` or the Docker socket into a container you do not fully trust. KVM and Docker tasks were not run against real hypervisors here; they are marked *typical output*. Podman/Docker commands were run with the available tool and noted.

Conventions: see [Step 1](step-01-linux-fundamentals.md#how-to-read-each-task).

---

## Beginner

### Task 11.1: KVM/libvirt overview

- **What you will learn:** what a hypervisor is, that KVM is Linux's built-in one, and how `libvirt`/`virsh` manage virtual machines. *KVM was not run here; commands are from the libvirt documentation.*
- **Target distro:** both. Install: `sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virt-manager` (Ubuntu) / `sudo dnf install -y @virtualization` (RHEL).
- **Risk level:** `can lock you out` of nothing on the host, but VMs need RAM/disk and root (or `libvirt` group). Needs a VM-capable CPU with virtualization enabled in BIOS.

```bash
# Check that KVM is available
egrep -c '(vmx|svm)' /proc/cpuinfo
ls -l /dev/kvm

# Install (Ubuntu)
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
sudo systemctl enable --now libvirtd
sudo virsh -c qemu:///system list --all
```

*Typical output:* `virsh list` shows no active guests; `/dev/kvm` exists and `egrep` prints a count ≥ 1.

**Verify it worked.** Check the host is KVM-capable and libvirt answers (captured; `systemctl` needs a
host with systemd as PID 1):

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo      # expect >= 1
ls -l /dev/kvm                          # expect the character device
sudo virsh -c qemu:///system list --all # expect an empty table, exit 0
```

*Captured output:*

```text
4
crw-rw---- 1 root kvm 10, 232 Oct 18 21:50 /dev/kvm
 Id   Name   State
--------------------
```

Any count ≥ 1 means the CPU exposes virtualization; an empty `virsh list --all` table with exit code 0
means the daemon is reachable.

**Acceptance criteria:**

- [ ] `/dev/kvm` exists and `egrep` finds `vmx` (Intel) or `svm` (AMD).
- [ ] `virsh -c qemu:///system list --all` runs without error.

**Undo it:** `sudo systemctl disable --now libvirtd`; uninstall if you do not need KVM.

**Troubleshooting:**

- `/dev/kvm` missing: virtualization is disabled in the BIOS/UEFI, or you are inside another VM without nested virtualization.
- `permission denied` on `virsh`: add your user to the `libvirt` group (`sudo usermod -aG libvirt $USER`) and log out/in.
- QEMU is slow without KVM: it still works but uses pure emulation — only for short tests.

### Task 11.2: Docker and Podman side by side

- **What you will learn:** run the same image with both tools, list containers/images, and clean up. Docker is a daemon; Podman is daemonless and rootless by default.
- **Target distro:** both. Docker: `sudo apt install -y docker.io` / `sudo dnf install -y docker`. Podman: `sudo apt install -y podman` / `sudo dnf install -y podman`.
- **Risk level:** `can lock you out` of nothing, but the Docker group is equivalent to root — do not add untrusted users to it. Use rootless Podman where possible.

Run a throwaway container (Docker shown; Podman uses the same flags with `podman` instead of `docker`):

```bash
# Docker (daemon; root or docker group)
docker run --rm docker.io/library/alpine:3.20 echo "hello from a container"

# Same image with Podman (rootless by default)
podman run --rm docker.io/library/alpine:3.20 echo "hello from a container"

# List images and (none running, because --rm cleaned up)
docker images      # or: podman images
docker ps -a       # or: podman ps -a
```

**Verify it worked:** both print `hello from a container`; `ps -a` shows no leftover container.

*Typical output (first run pulls the image, then):*

```text
hello from a container
```

**Acceptance criteria:**

- [ ] The same image runs under both Docker and Podman.
- [ ] No container is left behind after `--rm`.

**Undo it:** `docker rmi` / `podman rmi` the image, or `docker system prune` / `podman system prune`.

**Troubleshooting:**

- `docker: command not found`: install Docker or use Podman instead.
- Podman rootless port below 1024: unprivileged users cannot bind low ports; publish a high port (`-p 127.0.0.1:8080:80`).
- Short image name asks for a registry: use a fully-qualified name like `docker.io/library/alpine:3.20`.

### Task 11.3: Rootless containers

- **What you will learn:** run containers as a non-root user; Podman does this by default, Docker needs rootless mode (`dockerd-rootless.sh`).
- **Target distro:** both. Rootless Podman needs `/etc/subuid` and `/etc/subgid` ranges for your user.
- **Risk level:** `safe` — a compromise is confined to your UID range.

```bash
# Check your UID mapping ranges
grep "$USER" /etc/subuid /etc/subgid

# Podman is rootless by default; prove the container is not root
podman run --rm docker.io/library/alpine:3.20 id -u
```

*Typical output:* `1000` (your mapped UID) — not `0`.

**Verify it worked:** `podman run ... id -u` prints a non-zero UID.

**Acceptance criteria:**

- [ ] The container's `id -u` is not `0`.
- [ ] You ran it without `sudo`.

**Undo it:** `podman rm -a` / `podman rmi` to clean up.

**Troubleshooting:**

- `subuid`/`subgid` missing: `sudo usermod --add-subuids 100000-165536 --add-subgids 100000-165536 $USER`, then log out/in.
- Rootless Docker: follow the official rootless install script (`dockerd-rootless.sh`) and export `DOCKER_HOST`.

### Task 11.4: Images and volumes

- **What you will learn:** build an image with a `Containerfile`/`Dockerfile`, run as a non-root user, and persist data with a named volume or bind mount.
- **Target distro:** both.
- **Risk level:** `safe` (builds an image locally; volumes write where you point them).

```bash
cd "$(mktemp -d)"
mkdir -p data && echo "persisted" > data/notes.txt

cat > Containerfile <<'EOF'
FROM docker.io/library/alpine:3.20
RUN echo "app:x:10001:10001::/home/app:/bin/sh" >> /etc/passwd
WORKDIR /srv
COPY data/notes.txt /srv/notes.txt
USER 10001
CMD ["cat", "/srv/notes.txt"]
EOF

podman build -t localhost/lab-notes:1 .
podman run --rm localhost/lab-notes:1
podman run --rm --name notes-vol -v "$PWD/data:/srv/data:ro" \
  docker.io/library/alpine:3.20 cat /srv/data/notes.txt
podman rm notes-vol 2>/dev/null || true
```

**Verify it worked.** Both runs print `persisted`, and the built image runs as UID 10001 (captured in a
container):

```bash
podman run --rm localhost/lab-notes:1            # CMD cat /srv/notes.txt
podman run --rm localhost/lab-notes:1 id         # shows the non-root USER
podman run --rm -v "$PWD/data:/srv/data:ro" docker.io/library/alpine:3.20 \
  cat /srv/data/notes.txt                        # reads through the bind mount
```

*Captured output:*

```text
persisted
uid=10001(app) gid=10001(10001) groups=10001(10001)
persisted
```

The bind-mounted `notes.txt` is readable inside the container, and `id` shows the container really runs
as the non-root `app` user declared by `USER 10001`.

**Acceptance criteria:**

- [ ] The image tag includes a version (`:1`), not `latest`.
- [ ] The container runs as non-root (`USER 10001`).
- [ ] The bind-mounted file is readable inside the container.

**Undo it:** `podman rmi -f localhost/lab-notes:1`; `rm -rf` the temp directory.

**Troubleshooting:**

- Permission denied on the bind mount (SELinux): add `:Z` (`-v "$PWD/data:/srv/data:ro,Z`).
- Image refuses to run as root: add `USER` or `--user 10001`.

### Task 11.5: Compose

- **What you will learn:** define a multi-container application in a Compose file and bring it up/down with one command. Docker Compose; Podman Compose mirrors most of it.
- **Target distro:** both.
- **Risk level:** `safe` (containers on your machine only; publish ports to loopback).

```yaml
# compose.yaml
services:
  web:
    image: docker.io/library/nginx:1.27-alpine
    ports:
      - "127.0.0.1:8080:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
```

```bash
mkdir -p html && echo "<h1>compose lab</h1>" > html/index.html
docker compose up -d          # or: podman-compose up -d
curl -s http://127.0.0.1:8080/
docker compose down           # or: podman-compose down
```

*Typical output:* `curl` prints `<h1>compose lab</h1>`; `down` removes the containers and network.

**Verify it worked:** `curl http://127.0.0.1:8080/` returns your HTML; `docker compose ps` is empty after `down`.

**Acceptance criteria:**

- [ ] `up -d` starts the service and it answers on `127.0.0.1` only.
- [ ] `down` removes containers (no leftovers in `ps -a`).

**Undo it:** `docker compose down --rmi all -v` (also removes images and volumes).

**Troubleshooting:**

- Port already in use: change `8080` to another host port, or stop the holder (`ss -ltnp` to find it).
- Compose plugin missing: `docker compose` (not `docker-compose`) is the modern plugin; install `docker-compose-plugin`.

### Task 11.6: Basic image hardening

- **What you will learn:** run as non-root, pin versions, drop capabilities, and scan for known vulnerabilities.
- **Target distro:** both.
- **Risk level:** `safe` (image inspection).

Hardening checklist for every image:

| Check | Command / what to look for |
|-------|---------------------------|
| Non-root user | `podman image inspect --format '{{.Config.User}}' IMAGE` — must not be empty, `root`, or `0` |
| Pinned tag | reference ends in `:version` or a digest, never `:latest` |
| No extra tools | image contains only what the app needs (no `curl`/`ssh` in production images) |
| Read-only root | run with `--read-only` plus `--tmpfs` for writable dirs |
| Drop capabilities | `--cap-drop ALL` then add only what is needed |

```bash
podman image inspect --format '{{.Config.User}}' localhost/lab-notes:1
podman run --rm --read-only --cap-drop ALL localhost/lab-notes:1 true && echo "hardened run OK"
```

**Verify it worked:** the inspect command prints `10001`; the hardened run prints `hardened run OK`.

**Acceptance criteria:**

- [ ] Image runs as a non-root user.
- [ ] Tag is pinned (not `latest`).
- [ ] Container starts with `--read-only --cap-drop ALL`.

**Undo it:** `podman rmi` the test images.

**Troubleshooting:**

- `--read-only` fails: the app needs to write somewhere; add `--tmpfs /tmp:rw,noexec,nosuid` or a writable volume.
- `--cap-drop ALL` breaks networking: add back `--cap-add CAP_NET_BIND_SERVICE` only if you need a low port.

---

## Step checklist

- [ ] 11.1 KVM/libvirt available (`/dev/kvm`, `virsh list`)
- [ ] 11.2 Same image runs under Docker and Podman
- [ ] 11.3 Rootless container runs as non-root (`id -u` != 0)
- [ ] 11.4 Image built with `USER`; volume/bind mount works
- [ ] 11.5 Compose file brings a service up and down
- [ ] 11.6 Image passes the hardening checklist

## Further reading

- [Podman documentation](https://docs.podman.io/en/latest/): rootless containers, Quadlet, and the command reference.
- [Docker documentation](https://docs.docker.com/): images, volumes, and Compose.
- [Containerfile reference](https://github.com/containers/common/blob/main/docs/Containerfile.5.md): build instructions Podman supports.
- [Docker Compose reference](https://docs.docker.com/compose/): `compose.yaml` syntax.
- [libvirt](https://libvirt.org/): the virtualization API used by `virsh` and `virt-manager`.

**Next:** [Step 12: Staying Updated](step-12-staying-updated.md)
