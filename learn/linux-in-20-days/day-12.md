# Day 12: Networking Basics and Connectivity Checks

> **Time:** ~75 min · **Level:** Intermediate
> **Prerequisites:** [Day 11](day-11.md)

## Goal

By the end of this lesson you can:

- Read interface, address and route information with `ip`, and list listening sockets with `ss`.
- Test a connection layer by layer: name resolution, TCP connect, HTTP answer.
- Explain how to change addresses and firewall rules safely on Debian/Ubuntu and RHEL-family systems, with a way back if you lock yourself out.

## Concepts

### The layers you check, in order

```text
1 link/address   ip -br addr          do I have an IP address?
2 route          ip route             is there a default gateway?
3 name           getent hosts NAME    does the name resolve to an address?
4 transport      port test            does something accept TCP connections on that port?
5 application    curl -f URL          does the service answer correctly?
```

Work **up** the layers and stop at the first failure. That is the whole technique; Day 19 generalises it.

| Command | Replaces | Use |
|---------|----------|-----|
| `ip addr`, `ip -br addr` | `ifconfig` | addresses (`-br` = brief table) |
| `ip route` | `route`, `netstat -r` | routing table |
| `ss -ltn` | `netstat -ltn` | listening TCP sockets (`-p` adds the owning process, needs root for other users') |
| `getent hosts NAME` | `nslookup` | resolve using the system's own order (`/etc/hosts`, then DNS) |
| `dig NAME` | | query DNS directly (package `dnsutils` on Debian, `bind-utils` on RHEL) |
| `curl -sS -f -m 5 URL` | `wget` | HTTP test with a timeout |
| `ping -c 3 HOST` | | ICMP reachability (often blocked; not proof a service is down) |
| `tracepath HOST` / `traceroute HOST` | | where along the path packets stop |

`localhost` is `127.0.0.1` (and `::1`), the loopback interface. A service bound to `127.0.0.1` is reachable only from the same machine; bound to `0.0.0.0` or `::` it listens on every interface.

### Name resolution order

`/etc/nsswitch.conf` line `hosts: files dns` means: first `/etc/hosts`, then DNS servers (listed in `/etc/resolv.conf`, often managed by `systemd-resolved`, so use `resolvectl status` to see the real ones).

## Worked example

Scenario: users say "the site is down". You have no idea yet whether it is the network or the app. We build a tiny web server on loopback and practise diagnosing it, so every output is something you can reproduce.

Start with the machine itself:

```bash
ip -br addr show lo
getent hosts localhost
```

**Expected output** (the extra `10.255.255.254/32` address is specific to WSL; a normal system shows just `127.0.0.1/8` and `::1/128`):

```text
lo               UNKNOWN        127.0.0.1/8 10.255.255.254/32 ::1/128
::1             localhost
```

Create a page and serve it on port 8099, only on loopback:

```bash
cd "$(mktemp -d)"
printf 'ok\n' > index.html
python3 -m http.server 8099 --bind 127.0.0.1 >/dev/null 2>&1 &
srv=$!
sleep 1
ss -ltn 'sport = :8099'
```

**Expected output:**

```text
State  Recv-Q Send-Q Local Address:Port Peer Address:Port
LISTEN 0      5          127.0.0.1:8099      0.0.0.0:*
```

Layer 4 and 5: can we connect, and what does the server say?

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8099/
curl -sI http://127.0.0.1:8099/ | head -n 1 | tr -d '\r'
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8099/nope
curl -sf -o /dev/null http://127.0.0.1:8099/nope; echo "f-rc=$?"
```

**Expected output:**

```text
200
HTTP/1.0 200 OK
404
f-rc=22
```

Without `-f`, `curl` treats a 404 as success. With `-f`, an HTTP error becomes exit status 22, which is what you want in scripts.

Now break it: a closed port. `bash` can test a port without `nc` using the special `/dev/tcp` path:

```bash
timeout 3 bash -c 'exec 3<>/dev/tcp/127.0.0.1/8098'; echo "closed-rc=$?"
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8098/; echo "curl-rc=$?"
getent hosts nonexistent.invalid; echo "resolve-rc=$?"
```

**Expected output** (bash also prints a "Connection refused" message to stderr):

```text
closed-rc=1
000
curl-rc=7
resolve-rc=2
```

The status codes tell the layer: `getent` exit 2 means "name not found" (layer 3); `curl` exit 7 means "failed to connect" (layer 4); `curl -f` exit 22 means "connected, server said error" (layer 5). The reference script [`hard.sh`](solutions/day-12/hard.sh) packages this ladder: it exits with the number of the first failing layer.

Stop the server:

```bash
kill "$srv"
```

**Undo:** nothing persisted; `kill` ended the only process we started.

## Root-only: change addresses and firewalls (read, do not run on a remote machine)

These steps were **not run** while writing this lesson. Practise on a VM you can reach from its console.

> [!WARNING]
> A wrong IP, gateway or firewall rule can cut the connection you are using, and you may need console
> access to recover. Keep a **second** SSH session open and change one thing at a time. For SSH hosts,
> allow SSH **before** enabling a firewall.

| Task | Debian / Ubuntu | RHEL family |
|------|-----------------|-------------|
| Persistent address config | Netplan: `/etc/netplan/*.yaml`, apply safely with `sudo netplan try` (auto-reverts after 120 s if you do not confirm) | NetworkManager: `sudo nmcli con mod eth0 ipv4.addresses 192.168.1.50/24 ipv4.gateway 192.168.1.1 ipv4.method manual` then `sudo nmcli con up eth0` |
| Temporary address (lost at reboot) | `sudo ip addr add 192.168.1.50/24 dev eth0` | same |
| Firewall tool | `ufw` | `firewalld` |
| Allow SSH, then enable | `sudo ufw allow OpenSSH && sudo ufw enable` | `sudo firewall-cmd --permanent --add-service=ssh && sudo firewall-cmd --reload` |
| Open TCP 8080 | `sudo ufw allow 8080/tcp` | `sudo firewall-cmd --permanent --add-port=8080/tcp && sudo firewall-cmd --reload` |
| Show rules | `sudo ufw status verbose` | `sudo firewall-cmd --list-all` |

**Undo:** `sudo ip addr del 192.168.1.50/24 dev eth0`; `sudo ufw delete allow 8080/tcp` or `sudo firewall-cmd --permanent --remove-port=8080/tcp && sudo firewall-cmd --reload`; `sudo ufw disable` as an emergency brake.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| Deciding a service is down because `ping` fails | Many hosts drop ICMP while serving HTTP | Test the port: `curl -f -m 5` or `/dev/tcp` |
| `curl` "works" but the page is an error | `curl` exits 0 on HTTP 404/500 | `curl -f`, and check `%{http_code}` |
| Script hangs on an unreachable host | No timeout; a dropped packet waits for minutes | `curl -m 5 --connect-timeout 3`, `timeout 3 ...` |
| Service reachable locally but not remotely | Bound to `127.0.0.1`, or blocked by firewall | `ss -ltn` shows the bind address; check firewall |
| "Name resolves with dig but not with ping" | `dig` bypasses `/etc/hosts` and nsswitch | Use `getent hosts NAME` to see what applications see |
| Editing `/etc/resolv.conf` by hand | It is regenerated by systemd-resolved / NetworkManager | Configure through those tools |
| Enabling the firewall before allowing SSH | Locks you out | Allow SSH first; keep a second session |

## Exercises

Reference solutions: [`solutions/day-12/`](solutions/day-12/). The scripts use free ports on `127.0.0.1` only.

### Easy

Start a web server on a free local port, prove with `ss` that it is listening, fetch its page with `curl`, and shut it down.

**Acceptance criteria:**

- `ss` shows `LISTEN` on `127.0.0.1:PORT`.
- `curl` returns status `200` and the page text.
- No server is left running afterwards.

### Medium

Write `portcheck.sh HOST PORT` using bash's `/dev/tcp` and `timeout` (no `nc`). Exit 0 if the port accepts a connection, 1 if not, 2 for bad arguments.

**Acceptance criteria:**

- Returns 1 for a closed local port, 0 once a server is listening, 2 for port `99999` or the wrong number of arguments.
- Never waits more than 3 seconds.

### Hard

Write `netdiag.sh HOST PORT` that checks 1 resolve, 2 connect, 3 HTTP and exits with the number of the first failing layer (0 if all pass), printing one line per layer.

**Acceptance criteria:**

- Healthy local server: three `ok` lines, exit 0.
- `nonexistent.invalid`: stops at layer 1, exit 1.
- Closed port on `127.0.0.1`: stops at layer 2, exit 2.
- HTTP errors (status >= 400) count as layer 3 failures; wrong argument count exits 64.

### Break it

[`solutions/day-12/break-it.sh`](solutions/day-12/break-it.sh) should print `web service is UP` only when HTTP succeeds quickly. It has three bugs.

**Acceptance criteria:** with a healthy server it prints `UP`; with the server stopped, or a path returning 404, it prints `DOWN` and exits non-zero; it never waits longer than about 5 seconds.

## Solutions

<details>
<summary>Easy</summary>

```bash
port=$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')
python3 -m http.server "$port" --bind 127.0.0.1 >/dev/null 2>&1 &
srv=$!; trap 'kill "$srv"' EXIT
ss -ltn "sport = :$port"
curl -s -w '%{http_code}\n' "http://127.0.0.1:$port/"
```

Binding to port 0 lets the kernel pick a free port, so the exercise never collides with another service. Script: [`easy.sh`](solutions/day-12/easy.sh).

</details>

<details>
<summary>Medium</summary>

```bash
timeout 3 bash -c 'exec 3<>"/dev/tcp/$1/$2"' _ "$1" "$2" 2>/dev/null
```

The `exec 3<>/dev/tcp/HOST/PORT` redirection opens a TCP connection; success or failure becomes the exit status. Script with `--self-test`: [`medium.sh`](solutions/day-12/medium.sh).

</details>

<details>
<summary>Hard</summary>

Use `getent hosts` for layer 1, the `/dev/tcp` test for layer 2, and `curl -s -f -m 5` for layer 3. Each failure `return`s its layer number, so the first failure ends the function. Script with `--self-test`: [`hard.sh`](solutions/day-12/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. `ping` tests ICMP, not the web service. Test the HTTP request itself.
2. `curl URL` exits 0 on a 404 or 500. Add `-f`.
3. No timeout: add `-m 5 --connect-timeout 3`.

Fixed script: [`break-it.fixed.sh`](solutions/day-12/break-it.fixed.sh).

</details>

## Self-check

1. In which order do you check address, route, name, port and application?
2. What does `curl` exit status 7 mean? And 22 with `-f`?
3. Why can `ping` succeed while a website is down?
4. How can you tell from `ss -ltn` that a service is reachable only locally?
5. What does `netplan try` do that `netplan apply` does not?

<details>
<summary>Answers</summary>

1. Address, route, name resolution, TCP port, application (bottom up).
2. 7: could not connect. 22: connected, but the server returned an HTTP error (400 or higher).
3. Ping tests the host, not the service; the service may be stopped, crashed or firewalled.
4. The local address column shows `127.0.0.1` or `::1` instead of `0.0.0.0`, `*` or `[::]`.
5. It reverts the change automatically after a timeout unless you confirm it, protecting against lock-out.

</details>

## Cheat sheet

```bash
ip -br addr; ip route; ip -br link
ss -ltn; ss -ltnp                    # listening TCP (-p: processes)
getent hosts NAME                    # resolve as applications do
curl -sS -f -m 5 -o /dev/null -w '%{http_code}\n' URL
timeout 3 bash -c 'exec 3<>/dev/tcp/HOST/PORT'   # port test
ping -c 3 HOST; tracepath HOST
resolvectl status                    # DNS servers in use (systemd-resolved)
sudo netplan try                     # Ubuntu: apply with auto-revert
sudo ufw status verbose              # Debian/Ubuntu firewall
sudo firewall-cmd --list-all         # RHEL firewall
```

## Further reading

- [ip(8)](https://man7.org/linux/man-pages/man8/ip.8.html): the full `ip` command family (address, link, route, neigh).
- [ss(8)](https://man7.org/linux/man-pages/man8/ss.8.html): socket filters such as `sport = :80` and state selectors.
- [curl man page](https://curl.se/docs/manpage.html): every option, including the `--write-out` variables used above.
- [Netplan reference](https://netplan.readthedocs.io/en/stable/netplan-yaml/): the YAML keys for static addresses, routes and DNS on Ubuntu.
- [firewalld documentation](https://firewalld.org/documentation/): zones, services and rich rules on RHEL-family systems.

**Next:** [Day 13](day-13.md)
