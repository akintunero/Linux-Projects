# Day 17: Remote Work With SSH, Tunnels and tmux

> **Time:** ~90 min · **Level:** Intermediate
> **Prerequisites:** [Day 04](day-04.md), [Day 12](day-12.md)

## Goal

By the end of this lesson you can:

- Create an SSH key pair, install the public key on a server, and write `~/.ssh/config` aliases that behave the way you intended (verified with `ssh -G`).
- Explain and write local (`-L`), remote (`-R`) and dynamic (`-D`) tunnels and a jump-host connection.
- Keep work alive across disconnects with `tmux`, and harden `sshd` without locking yourself out.

## Concepts

### Keys, not passwords

An SSH key pair has a **private key** (stays on your machine, mode `600`, protected with a passphrase) and a **public key** (a one-line `.pub` file you copy to servers). The server stores allowed public keys in `~/.ssh/authorized_keys`. Prefer `ed25519`.

```bash
ssh-keygen -t ed25519 -C "you@laptop"          # asks for a passphrase: use one
ssh-copy-id user@server                        # appends ~/.ssh/id_ed25519.pub to the server's authorized_keys
ssh-add                                        # (after eval "$(ssh-agent -s)") unlock the key once per session
ssh user@server
```

The first time you connect, ssh shows the server's host-key fingerprint and asks whether to trust it. Compare it with a fingerprint you obtained another way (the server's console, your provider's dashboard) before typing `yes`. It is then stored in `~/.ssh/known_hosts`; a later "REMOTE HOST IDENTIFICATION HAS CHANGED" warning means the key changed (reinstall) or someone is intercepting: do not just delete the line.

> [!WARNING]
> Never copy a private key (`id_ed25519`, no `.pub`) to a server, chat or repository. Never paste one into
> an AI tool. The key generated in this lesson has no passphrase **because it is a throwaway demo**.

### ~/.ssh/config: names for your servers

```text
Host web
    HostName 192.0.2.10
    User deploy
    Port 2222
    IdentityFile ~/.ssh/web_ed25519
    IdentitiesOnly yes
    LocalForward 8080 localhost:80

Host db
    HostName 10.0.0.5
    User admin
    ProxyJump web

Host *
    ServerAliveInterval 30
```

Now `ssh web` and `ssh db` (through `web`) work. Two rules cause most trouble: **the first value ssh finds for an option wins**, so specific `Host` blocks go before `Host *`; and the file must not be writable by others (`chmod 600 ~/.ssh/config`, `chmod 700 ~/.ssh`).

### Tunnels

| Goal | Command | Meaning |
|------|---------|---------|
| Reach a service on the server's side from here | `ssh -L 8080:localhost:80 web` | `http://localhost:8080` on your machine goes through the tunnel to port 80 on the server |
| Expose a local service on the server | `ssh -R 9000:localhost:3000 web` | port 9000 on the server reaches your port 3000 |
| SOCKS proxy through the server | `ssh -D 1080 web` | point a browser or `curl --socks5-hostname localhost:1080` at it |
| Jump through a bastion | `ssh -J bastion user@internal` | one command, two hops |
| Tunnel only, no shell | add `-N` (and `-f` to background) | |

Binding defaults to loopback, which is what you want. Forwarding a port to `0.0.0.0` publishes it to your network.

### tmux: sessions that survive disconnects

`tmux` keeps shells running on the server even if your connection drops. Everything starts with the prefix `Ctrl+b`.

| Keys / command | Action |
|----------------|--------|
| `tmux new -s work` | new named session |
| `Ctrl+b d` | detach (it keeps running) |
| `tmux ls` / `tmux attach -t work` | list / reattach |
| `Ctrl+b c`, `Ctrl+b n`, `Ctrl+b p` | new window, next, previous |
| `Ctrl+b %`, `Ctrl+b "` | split vertically / horizontally |
| `Ctrl+b arrows` | move between panes |
| `Ctrl+b [` | scroll mode (`q` leaves) |
| `tmux kill-session -t work` | end it |

### Hardening the server (root; not run for this lesson)

> [!WARNING]
> A wrong `sshd_config` can lock you out of a remote machine. Keep your current session open, test with
> a **second** one, validate with `sudo sshd -t` before reloading, and keep console access to the VM.

Typical safe changes in `/etc/ssh/sshd_config` (or a drop-in in `/etc/ssh/sshd_config.d/`), made only after key login works:

```text
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
```

```bash
sudo sshd -t && sudo systemctl reload ssh      # Debian/Ubuntu service name
sudo sshd -t && sudo systemctl reload sshd     # RHEL family service name
```

**Undo:** restore the copy you made first (`sudo cp -a /etc/ssh/sshd_config /etc/ssh/sshd_config.orig`), run `sudo sshd -t`, reload. If you changed the port on a RHEL-family system with SELinux, add the port to the policy (`sudo semanage port -a -t ssh_port_t -p tcp 2222`) and the firewall (Day 12) first.

## Worked example

Everything in this section runs on one machine with no server, no network and no changes to your real `~/.ssh`.

### 1. A key pair

```bash
cd "$(mktemp -d)"
ssh-keygen -q -t ed25519 -N '' -C 'linux20-demo' -f demo_key
stat -c '%a %n' demo_key demo_key.pub
ssh-keygen -lf demo_key.pub
cut -d' ' -f1 demo_key.pub
```

**Expected output** (the hash differs for every key):

```text
600 demo_key
644 demo_key.pub
256 SHA256:<hash> linux20-demo (ED25519)
ssh-ed25519
```

`-N ''` means an empty passphrase, acceptable only for a demo. The `SHA256:` value (shown here as `<hash>` because it differs for every key) is the fingerprint you compare when asked to trust a host.

### 2. Ask ssh what an alias means, without connecting

`ssh -G HOST` prints the final settings ssh would use after reading the config, and never opens a connection. Use `-F` to read a config file other than the default.

```bash
cat > config <<'EOF'
Host web
    HostName 192.0.2.10
    User deploy
    Port 2222
    IdentityFile ~/.ssh/web_ed25519
    IdentitiesOnly yes
    LocalForward 8080 localhost:80

Host db
    HostName 10.0.0.5
    User admin
    ProxyJump web

Host *
    ServerAliveInterval 30
    User nobody
EOF
ssh -F config -G web | grep -E '^(hostname|user|port|identityfile|identitiesonly|localforward|proxyjump|serveraliveinterval) '
echo ---
ssh -F config -G db | grep -E '^(hostname|user|port|proxyjump) '
```

**Expected output** (ssh prints the keys in its own order):

```text
user deploy
hostname 192.0.2.10
port 2222
identitiesonly yes
serveraliveinterval 30
localforward 8080 [localhost]:80
identityfile ~/.ssh/web_ed25519
---
user admin
hostname 10.0.0.5
port 22
proxyjump web
```

`web` got `User deploy` even though `Host *` says `nobody`: the first match wins and `web` comes first. `db` has no port, so the default 22 appears.

Now the same blocks in the wrong order:

```bash
cat > badconfig <<'EOF'
Host *
    User nobody
    Port 22

Host web
    HostName 192.0.2.10
    User deploy
    Port 2222
EOF
ssh -F badconfig -G web | grep -E '^(user|port) '
```

**Expected output:**

```text
user nobody
port 22
```

The general block won. This is the classic "why is ssh ignoring my config" bug.

Syntax mistakes are caught the same way:

```bash
printf 'Host x\n    Prot 22\n' > typo
ssh -F typo -G x
```

**Expected output** (the path in the message is the file you passed):

```text
typo: line 2: Bad configuration option: prot
typo: terminating, 1 bad configuration options
```

### 3. tmux without a keyboard

A private socket (`-L NAME`) keeps this away from any tmux sessions you already have.

```bash
tmux -L linux20 new-session -d -s work 'echo hello-from-tmux; sleep 30'
tmux -L linux20 list-sessions -F '#{session_name}: #{session_windows} window(s)'
sleep 0.5
tmux -L linux20 capture-pane -p -t work | head -n 1
tmux -L linux20 new-window -d -t work -n logs 'sleep 30'
tmux -L linux20 list-windows -t work -F '#{window_index}:#{window_name}'
tmux -L linux20 kill-server
```

**Expected output:**

```text
work: 1 window(s)
hello-from-tmux
0:sleep
1:logs
```

The window name `sleep` is tmux's automatic name for the program running in it. To try it for real, type `tmux new -s work`, run something long, press `Ctrl+b` then `d`, and `tmux attach -t work`.

**Undo:** `kill-server` removed the private tmux server. The key files live in the temporary directory; delete the directory when done.

### 4. Tunnels and the server side (not run)

Tunnels, `ssh-copy-id`, agent forwarding and `sshd` hardening need a reachable SSH server (the machine used for testing had no `sshd`), so the commands in the Concepts section were **not run**. Practise them between two VMs, or between your machine and a cloud instance, and check each with the tools from Day 12: `ss -ltn` on the client shows the local forward listening on `127.0.0.1:8080`, and `curl http://localhost:8080/` goes through it.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `Permissions 0644 for 'id_ed25519' are too open` | ssh refuses a readable private key | `chmod 600 ~/.ssh/id_ed25519` |
| `Host *` placed first | First value wins; later blocks cannot override | Specific hosts first, `Host *` last |
| `LocalForward 8080:localhost:80` in the config | The `-L` colon syntax does not work there | `LocalForward 8080 localhost:80` |
| Key accepted for login on some servers but "Too many authentication failures" | ssh offers every key in the agent | `IdentitiesOnly yes` with `IdentityFile` |
| Locked out after disabling passwords | Key login was never tested | Test key login in a second session first |
| Deleting a `known_hosts` line to silence a warning | Hides a possible interception | Verify the new fingerprint out of band |
| Tunnel works, but others on the network can reach it | Bound to `0.0.0.0` (`-L 0.0.0.0:...`) | Keep the default loopback bind |
| Long job dies when the Wi-Fi drops | The shell was a child of the SSH connection | Run it inside `tmux` |
| `ssh-copy-id` used to a host you do not control | Gives that host a way back to your account | Only install keys on servers you trust |

## Exercises

Reference solutions: [`solutions/day-17/`](solutions/day-17/). They use temporary directories and a private tmux socket, never your real `~/.ssh`, and never connect to anything.

### Easy

Generate an Ed25519 key pair in a temporary directory and show its fingerprint.

**Acceptance criteria:**

- The private key has mode `600`; the first word of the `.pub` file is `ssh-ed25519`.
- `ssh-keygen -y -f KEY` prints the same public key as the `.pub` file.
- `ssh-keygen -lf` prints a `SHA256:` fingerprint.

### Medium

With a private tmux socket, create a detached session whose first window prints `hello-from-tmux`, add a second window named `logs`, list them, read the first pane's text with `capture-pane`, and clean up.

**Acceptance criteria:**

- Exactly one session with two windows exists before cleanup, and none after `kill-server`.
- `capture-pane -p` shows `hello-from-tmux`.

### Hard

Write `sshcheck.sh CONFIG ALIAS [key=value ...]` that uses `ssh -G` to compare what an alias resolves to with your expectations, printing `ok:`/`FAIL:` per expectation, and `WARN:` for `StrictHostKeyChecking no` and `ForwardAgent yes`.

**Acceptance criteria:**

- Exit 0 when every expectation matches, 1 when one does not (the message includes the value that was actually found).
- For the wrong-order config above, `user=deploy` fails with `got nobody`.
- A config with a typo, or missing arguments, exits 2.
- It never opens a network connection.

### Break it

[`solutions/day-17/break-it.sh`](solutions/day-17/break-it.sh) has a config meant to make `ssh web` mean `deploy@192.0.2.10:2222` with a forward `8080 -> localhost:80`. It has three bugs.

**Acceptance criteria:** `ssh -G web` prints `user deploy`, `port 2222`, `localforward 8080 [localhost]:80` and no error lines, while `Host *` still supplies `serveraliveinterval 30`.

## Solutions

<details>
<summary>Easy</summary>

```bash
ssh-keygen -q -t ed25519 -N '' -C linux20-demo -f demo_key
stat -c '%a' demo_key                      # 600
ssh-keygen -lf demo_key.pub
ssh-keygen -y -f demo_key | cut -d' ' -f1-2    # equals the first two fields of demo_key.pub
```

Script: [`easy.sh`](solutions/day-17/easy.sh).

</details>

<details>
<summary>Medium</summary>

```bash
t() { tmux -L linux20-medium "$@"; }
t new-session -d -s work 'echo hello-from-tmux; sleep 30'
t new-window -d -t work -n logs 'sleep 30'
t capture-pane -p -t work:0 | head -n 1
t kill-server
```

Script: [`medium.sh`](solutions/day-17/medium.sh).

</details>

<details>
<summary>Hard</summary>

Run `ssh -F "$cfg" -G "$alias"`, look up each expected key (ssh prints lower-case key names), and compare the rest of the line. A parse error from ssh makes `-G` exit non-zero, which becomes exit status 2. Script with `--self-test`: [`hard.sh`](solutions/day-17/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. Move `Host *` after `Host web`: the first value wins.
2. Write `LocalForward 8080 localhost:80` (a space, not a colon, between the local port and the destination).
3. `Prot` is a typo for `Port`; delete the line (the `Port 2222` is already there).

Fixed script: [`break-it.fixed.sh`](solutions/day-17/break-it.fixed.sh).

</details>

## Self-check

1. Which key file must never leave your machine, and what mode must it have?
2. In `~/.ssh/config`, why must `Host *` come last?
3. What does `ssh -L 8080:localhost:80 web` do?
4. What do `Ctrl+b d` and `tmux attach` do?
5. What must you do before reloading `sshd` after editing its config?

<details>
<summary>Answers</summary>

1. The private key (for example `id_ed25519`), mode `600`.
2. ssh uses the first value it finds for each option, so an earlier `Host *` overrides later specific blocks.
3. It opens port 8080 on your machine and forwards connections through `web` to port 80 as seen from `web`.
4. Detach from the tmux session (it keeps running) and reconnect to a running session.
5. Validate it with `sudo sshd -t` and keep an existing session open to test with a second one.

</details>

## Cheat sheet

```bash
ssh-keygen -t ed25519 -C "you@host"      # create a key (use a passphrase)
ssh-copy-id user@host                    # install the public key
ssh -G alias                             # what will ssh use? (no connection)
ssh -L 8080:localhost:80 host            # local forward
ssh -R 9000:localhost:3000 host          # remote forward
ssh -D 1080 -N host                      # SOCKS proxy, no shell
ssh -J bastion user@internal             # jump host
tmux new -s work | Ctrl+b d | tmux attach -t work | tmux ls
sudo sshd -t && sudo systemctl reload ssh      # RHEL: sshd
```

## Further reading

- [ssh_config(5)](https://man.openbsd.org/ssh_config): every client option, including `ProxyJump`, `IdentitiesOnly` and the first-match rule.
- [sshd_config(5)](https://man.openbsd.org/sshd_config): every server option, including `PermitRootLogin` and `PasswordAuthentication`.
- [OpenSSH manual pages index](https://www.openssh.com/manual.html): the official manuals for `ssh`, `ssh-keygen`, `ssh-agent` and `sshd`.
- [tmux manual](https://man.openbsd.org/tmux): the full command and key-binding reference.

**Next:** [Day 18](day-18.md)
