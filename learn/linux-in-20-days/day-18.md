# Day 18: Containers With Podman

> **Time:** ~75 min · **Level:** Intermediate
> **Prerequisites:** [Day 10](day-10.md), [Day 12](day-12.md), [Day 15](day-15.md)

## Goal

By the end of this lesson you can:

- Explain what a container is (a process with isolated views of files, processes and network) and how it differs from a virtual machine.
- Run, inspect, stop and remove containers with Podman, publish a port to loopback only, and mount a volume safely.
- Write a `Containerfile` that runs as a non-root user, and describe how to run it as a systemd service (Quadlet).

> [!NOTE]
> **How this lesson was verified.** Podman was not installed where the course was tested, but Docker was.
> The commands in the "Run it" and "Build it" parts are identical in both tools, and the outputs shown
> were produced with `docker` using the same arguments, but with `ubuntu:24.04` (already present on the
> test machine) as the base image instead of `alpine:3.20`, to avoid pulling anything. The `/etc/passwd`
> trick is distribution-neutral, so alpine should behave the same, but that exact image was not run.
> Podman-specific parts (rootless setup, SELinux `:Z`, Quadlet, the nginx example) are described from
> the documentation and **were not run**; they are marked.

## Concepts

A **container** is an ordinary Linux process started with its own *namespaces* (its own view of the process list, mounts, network, hostname) and limited by *cgroups* (CPU, memory). It shares the host kernel, so it starts in milliseconds, but it is not a separate machine: a kernel bug or a `--privileged` container weakens the isolation.

| Word | Meaning |
|------|---------|
| **Image** | read-only template: a root filesystem plus metadata (command, user, ports), built in layers |
| **Container** | a running (or stopped) instance of an image, with a thin writable layer |
| **Registry** | server hosting images (`docker.io`, `quay.io`, `registry.fedoraproject.org`) |
| **Containerfile** | the recipe for building an image (same syntax as a `Dockerfile`) |
| **Volume / bind mount** | storage that outlives the container / a host directory shown inside it |

**Podman** is daemonless (each container is a child of your user session or of systemd) and runs **rootless** by default: a normal user starts containers, and "root" inside is mapped to your unprivileged UID on the host. The commands match Docker's, so `alias docker=podman` works for most day-to-day use.

Install (root; not run): `sudo apt install podman` on Debian/Ubuntu, `sudo dnf install podman` on RHEL-family. Rootless needs ranges in `/etc/subuid` and `/etc/subgid` for your user (the installer normally creates them; check with `grep "$USER" /etc/subuid`).

> [!WARNING]
> Treat images like software you install: only pull from sources you trust, pin versions, and never run
> `--privileged` or mount `/` or the container socket into a container unless you understand that this
> hands over the host. Use fully-qualified names (`docker.io/library/alpine:3.20`); a short name like
> `alpine` may prompt you to choose a registry.

### Everyday commands

| Task | Command |
|------|---------|
| Run, remove on exit | `podman run --rm IMAGE CMD` |
| Run in background | `podman run -d --name web IMAGE` |
| Publish a port to **loopback** | `-p 127.0.0.1:8080:80` (host:container) |
| Mount a host directory read-only | `-v "$PWD/data:/data:ro"` (add `,Z` on SELinux systems) |
| Environment variable | `-e NAME=value` |
| List | `podman ps` (running), `podman ps -a` (all), `podman images` |
| Logs / shell inside | `podman logs -f web`, `podman exec -it web sh` |
| Stop / remove | `podman stop web`, `podman rm web`, `podman rmi IMAGE` |
| Details | `podman inspect web`, `podman image inspect IMAGE` |
| Clean up unused | `podman system prune` (asks first) |

## Worked example

### Run it

```bash
podman run --rm docker.io/library/alpine:3.20 echo "hello from a container"
```

**Expected output** (verified with Docker and an Ubuntu image; the first run with Podman also prints pull progress):

```text
hello from a container
```

`--rm` deleted the container after it exited, so `podman ps -a` shows nothing left over.

### Build it

Create a tiny image that runs as an unprivileged user. Appending to `/etc/passwd` creates the user on any base distribution:

```bash
cd "$(mktemp -d)"
echo "served by a container" > hello.txt
cat > Containerfile <<'EOF'
FROM docker.io/library/alpine:3.20
RUN echo "app:x:10001:10001::/home/app:/bin/sh" >> /etc/passwd
COPY hello.txt /srv/hello.txt
USER 10001
CMD ["cat", "/srv/hello.txt"]
EOF
podman build -t localhost/linux20-hello:1 -f Containerfile .
podman run --rm localhost/linux20-hello:1
podman run --rm localhost/linux20-hello:1 id -u
```

**Expected output** (of the two `run` commands; build progress text varies):

```text
served by a container
10001
```

The second line proves the container process is not root. If you omit the `USER` line the answer is `0`; root inside a container is not root on a rootless host, but it is still a good habit to avoid it.

Inspect without running:

```bash
podman image inspect --format '{{.Config.User}}' localhost/linux20-hello:1
```

```text
10001
```

### Serve something (local only)

```bash
mkdir -p data && echo "<h1>hi</h1>" > data/index.html
podman run -d --rm --name linux20-web -p 127.0.0.1:8080:80 \
  -v "$PWD/data:/usr/share/nginx/html:ro,Z" docker.io/library/nginx:1.27-alpine
curl -s http://127.0.0.1:8080/
podman logs linux20-web | tail -n 2
podman stop linux20-web
```

Expected: `curl` prints `<h1>hi</h1>`; the access log shows the request; `podman stop` ends the container and `--rm` deletes it. **This block was not run** (no Podman, and no pull of `nginx`): the ports and flags are standard, but run it in a VM and check with `ss -ltn` (Day 12) that the port is bound to `127.0.0.1` only. On Debian/Ubuntu without SELinux, `Z` is harmless and can stay.

### As a service: Quadlet (not run)

Podman can generate systemd units from a short `.container` file (Podman 4.4+). Put this in `~/.config/containers/systemd/linux20-web.container`:

```ini
[Unit]
Description=Linux in 20 days web demo

[Container]
Image=docker.io/library/nginx:1.27-alpine
PublishPort=127.0.0.1:8080:80
Volume=%h/data:/usr/share/nginx/html:ro,Z

[Service]
Restart=on-failure

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user start linux20-web.service
systemctl --user status linux20-web.service
journalctl --user -u linux20-web.service -n 5
```

All of Day 15 now applies: logs in the journal, `Restart=`, enable at login. To keep user services running after you log out, `sudo loginctl enable-linger "$USER"`.

**Undo:** `systemctl --user stop linux20-web.service`, delete the `.container` file, `systemctl --user daemon-reload`; `podman rmi localhost/linux20-hello:1`; `podman system prune` to reclaim leftovers.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `-p 8080:80` | Publishes on every interface | `-p 127.0.0.1:8080:80` |
| `image:latest` | The tag moves; builds are not reproducible | Pin a version (or digest) |
| Container runs as root | No `USER` in the image | `USER 10001` or `--user 10001` |
| `--privileged` "to make it work" | Removes isolation | Add only the specific capability or device needed |
| Permission denied on a bind mount (Fedora, RHEL, Rocky) | SELinux label | Add `:Z` (private) or `:z` (shared) to the volume |
| Permission denied on a mounted directory (rootless) | UID mapping: the container user differs from yours | `--userns=keep-id`, or `chown` the data to the mapped UID |
| Cannot bind port 80 rootless | Unprivileged users may not use ports below 1024 by default | Publish a high port, or lower `net.ipv4.ip_unprivileged_port_start` deliberately |
| Data vanished after `rm` | Written to the container layer | Use a named volume or bind mount |
| Short name "alpine" asks for a registry | Podman's short-name resolution | Use `docker.io/library/alpine:3.20` |
| Containers die when you log out | User services stop at logout | `loginctl enable-linger` or use Quadlet |

## Exercises

Reference solutions: [`solutions/day-18/`](solutions/day-18/). They use `CTR=podman` by default; set `CTR=docker` (and `BASE_IMAGE=` to an image you already have) to try them with Docker. They exit 77 (skipped) when the container tool is not installed. `break-it.sh` only prints a command.

### Easy

Run a throwaway container that prints `hello from a container` and is removed automatically.

**Acceptance criteria:**

- The output is exactly that line.
- No container for the image is left in `podman ps -a`.

### Medium

Build an image from a `Containerfile` with a `COPY`ed file and `USER 10001`; run it to print the file, and print `id -u` from inside. Remove the image afterwards.

**Acceptance criteria:**

- The first `run` prints the file's text; the second prints `10001`.
- The image tag includes a version (`:1`), not `latest`.
- The script removes the image even if a step fails (`trap`).

### Hard

Write `imgaudit.sh IMAGE` that reports whether the image runs as root, whether the reference is pinned to a version tag, and which ports it exposes.

**Acceptance criteria:**

- An image with `USER 10001` and an `EXPOSE 8000` reports `ok:   runs as '10001'`, a pinned tag and port `8000`, exit 0.
- An image with no `USER` and no tag prints `WARN: runs as root` and `WARN: ... not pinned`, exit 1.
- A missing image gives an error and exit 2.

### Break it

[`solutions/day-18/break-it.sh`](solutions/day-18/break-it.sh) prints a `podman run` command for local web development. It has three bugs and misses two good practices.

**Acceptance criteria:** the corrected command binds to `127.0.0.1`, pins the image tag, has no `--privileged`, mounts the volume `:ro` with an SELinux label, and uses `--rm`.

## Solutions

<details>
<summary>Easy</summary>

```bash
podman run --rm docker.io/library/alpine:3.20 echo "hello from a container"
```

Script: [`easy.sh`](solutions/day-18/easy.sh) (tested with Docker; Podman not run).

</details>

<details>
<summary>Medium</summary>

```bash
trap 'podman rmi -f localhost/linux20-d18-medium:1 >/dev/null 2>&1 || true' EXIT
podman build -q -t localhost/linux20-d18-medium:1 -f Containerfile .
podman run --rm localhost/linux20-d18-medium:1
podman run --rm localhost/linux20-d18-medium:1 id -u
```

Script: [`medium.sh`](solutions/day-18/medium.sh) (tested with Docker; Podman not run).

</details>

<details>
<summary>Hard</summary>

```bash
user=$(podman image inspect --format '{{.Config.User}}' "$image")
ports=$(podman image inspect --format '{{.Config.ExposedPorts}}' "$image")
```

An empty user, `root` or `0` means root. A reference is pinned if the last path component has a `:tag` that is not `latest`. Script with `--self-test`: [`hard.sh`](solutions/day-18/hard.sh) (tested with Docker; Podman not run).

</details>

<details>
<summary>Break it</summary>

1. `-p 8080:80` listens on all interfaces: use `-p 127.0.0.1:8080:80`.
2. `:latest` is not reproducible: pin `nginx:1.27-alpine`.
3. `--privileged` is not needed for a web server: remove it.

Also add `:ro,Z` to the volume and `--rm`. Fixed script with `--self-test`: [`break-it.fixed.sh`](solutions/day-18/break-it.fixed.sh).

</details>

## Self-check

1. How does a container differ from a virtual machine?
2. What does `-p 127.0.0.1:8080:80` do that `-p 8080:80` does not?
3. Why is `USER` in a Containerfile worth having even with rootless Podman?
4. What does `:Z` do on a bind mount?
5. What turns a `.container` file into a service?

<details>
<summary>Answers</summary>

1. A container is a process sharing the host kernel with isolated namespaces and cgroup limits; a VM runs its own kernel on virtual hardware.
2. It publishes the port on loopback only, so other machines cannot reach it.
3. Defence in depth: if the process is compromised or an isolation bug exists, it does not start with root privileges inside the container.
4. It relabels the directory for the container's SELinux context so the container may access it (private label).
5. Podman's Quadlet generator turns it into a systemd unit when you run `systemctl --user daemon-reload`.

</details>

## Cheat sheet

```bash
podman run --rm IMAGE CMD                       # throwaway
podman run -d --name web -p 127.0.0.1:8080:80 IMAGE
podman ps -a; podman images; podman logs -f web
podman exec -it web sh
podman stop web; podman rm web; podman rmi IMAGE
podman build -t localhost/app:1 -f Containerfile .
podman image inspect --format '{{.Config.User}}' IMAGE
-v "$PWD/data:/data:ro,Z"                       # read-only bind mount, SELinux label
systemctl --user daemon-reload                  # after adding a Quadlet .container file
```

## Further reading

- [Podman documentation](https://docs.podman.io/en/latest/): the full command reference and tutorials.
- [Podman: rootless tutorial](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md): prerequisites and limits of running without root.
- [podman-systemd.unit(5) (Quadlet)](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html): every key allowed in `.container` files.
- [Containerfile reference](https://github.com/containers/common/blob/main/docs/Containerfile.5.md): the build instructions that Podman supports.

**Next:** [Day 19](day-19.md)
