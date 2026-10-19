# Day 22: Networking Basics in Bash

> **Time:** ~60 min · **Level:** Intermediate
> **Prerequisites:** [Day 21](day-21.md)

## Goal

By the end of this lesson you can:

- Check whether a host is reachable, a port is open and an HTTP endpoint is healthy.
- Use `curl` correctly in scripts (fail on HTTP errors, time out, read the status code).
- Wait for a service with retries and a deadline instead of a blind `sleep`.

## Concepts

All examples here talk to a throwaway web server on `127.0.0.1`, so they work offline and touch
nothing else. Only probe machines you own or are authorised to test.

### Is it up? Layers of checking

1. **Name resolution:** `getent hosts example.com` (or `dig +short`, `host`).
2. **Reachability:** `ping -c 1 -W 2 host` (some networks block ICMP, so it can lie).
3. **Port:** can I open a TCP connection? `nc -z -w 2 host 80` or pure Bash below.
4. **Service:** does it answer correctly? `curl` and check the status code.

Check from the outermost layer you care about. A TCP port can be open while the application behind
it returns errors.

### A port check without extra tools

```bash
(exec 3<>"/dev/tcp/example.com/443") 2>/dev/null && echo open || echo closed
```

`/dev/tcp/HOST/PORT` is a Bash feature (not a real file) that opens a TCP connection. Wrap it in
`timeout 2 bash -c '...'` when a firewall might drop packets and make it hang.

### `curl` in scripts

| Flag | Meaning |
|------|---------|
| `-f` | Fail with exit 22 on HTTP 4xx/5xx instead of saving the error page |
| `-s` | Silent: no progress meter |
| `-S` | With `-s`, still show errors (use `-sS`) |
| `-L` | Follow redirects |
| `--max-time N` | Give up after N seconds in total |
| `--connect-timeout N` | Give up connecting after N seconds |
| `-o file` / `-O` | Save to a file |
| `-w '%{http_code}'` | Print the status code (`000` means no HTTP response) |
| `-H 'Header: v'`, `-d data`, `-X POST` | Headers, body and method |

Useful exit codes: `6` cannot resolve host, `7` connection refused, `28` timed out, `22` HTTP error
with `-f`.

### Retry with back-off and a deadline

A service that is "starting" needs waiting, but not forever and not hammering it:

```bash
deadline=$(( SECONDS + 30 )); delay=1
until curl -fsS --max-time 2 "$url" >/dev/null 2>&1; do
    (( SECONDS < deadline )) || { echo "timeout" >&2; exit 1; }
    sleep "$delay"; (( delay < 8 )) && delay=$(( delay * 2 ))
done
```

### Looking at your own machine

```bash
ip -brief address        # interfaces and addresses
ss -ltnp                 # listening TCP sockets (and the owning process, with sudo)
ss -tn state established # current connections
```

## Worked example

`net.sh` starts a local server, waits for its port, and demonstrates the main checks. Save it and run
it in an empty directory (needs `python3` and `curl`).

```bash
#!/usr/bin/env bash
# net.sh - network checks against a throwaway web server on localhost (no internet needed)
set -euo pipefail

free_port() {
    python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])'
}
port_open() {                                   # port_open HOST PORT  (pure Bash: /dev/tcp)
    (exec 3<>"/dev/tcp/$1/$2") 2>/dev/null
}

port="$(free_port)"
mkdir site
echo "hello from the test server" > site/index.html
python3 -m http.server "$port" --bind 127.0.0.1 --directory site >/dev/null 2>&1 &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true' EXIT

echo "--- 1. wait until the port accepts connections (never a blind sleep)"
for _ in {1..50}; do
    port_open 127.0.0.1 "$port" && break
    sleep 0.1
done
port_open 127.0.0.1 "$port" && echo "server is up"

echo "--- 2. curl flags: -f fail on HTTP errors, -sS quiet but show errors, --max-time"
curl -fsS --max-time 5 "http://127.0.0.1:${port}/"

echo "--- 3. just the status code"
curl -s -o /dev/null -w '%{http_code}\n' "http://127.0.0.1:${port}/"
curl -s -o /dev/null -w '%{http_code}\n' "http://127.0.0.1:${port}/missing"

echo "--- 4. -f turns a 404 into a non-zero exit status"
status=0
curl -fsS "http://127.0.0.1:${port}/missing" || status=$?
echo "curl exit status: ${status} (22 = HTTP error)"

echo "--- 5. connection refused is a different failure (exit 7)"
status=0
curl -sS --max-time 2 "http://127.0.0.1:1/" 2>/dev/null || status=$?
echo "curl exit status: ${status}"

echo "--- 6. who is listening, and can we reach it?"
echo "listening sockets on the test port: $(ss -ltn | grep -c ":${port} ")"
port_open 127.0.0.1 "$port" && echo "port open" || echo "port closed"
port_open 127.0.0.1 1 && echo "port 1 open" || echo "port 1 closed"

echo "--- 7. name resolution"
getent hosts localhost | awk '{ print "localhost resolves (" $2 ")" }'
```

**Expected output**

```text
--- 1. wait until the port accepts connections (never a blind sleep)
server is up
--- 2. curl flags: -f fail on HTTP errors, -sS quiet but show errors, --max-time
hello from the test server
--- 3. just the status code
200
404
--- 4. -f turns a 404 into a non-zero exit status
curl: (22) The requested URL returned error: 404
curl exit status: 22 (22 = HTTP error)
--- 5. connection refused is a different failure (exit 7)
curl exit status: 7
--- 6. who is listening, and can we reach it?
listening sockets on the test port: 1
port open
port 1 closed
--- 7. name resolution
localhost resolves (localhost)
```

The wait loop in section 1 polls the port every 0.1 s rather than guessing a `sleep` duration.
Section 4 and 5 show the two different failure modes a script must distinguish: the server answered
with an error (22), or nothing answered at all (7).

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| `curl url -o page.html` and treating success as "page exists" | Without `-f`, a 404 page is saved and curl exits 0 | `curl -fsS url -o page.html` |
| `sleep 5` before using a new service | Too short is flaky, too long wastes time | Poll the port or URL with a deadline |
| `ping host` in a script | Pings forever on Linux | `ping -c 1 -W 2 host` |
| No `--max-time` | One dead server hangs the script forever | Always set a timeout |
| Treating `ping` failure as "host down" | ICMP may be filtered | Test the actual port or service |
| `curl` output parsed with `grep` for the status | Fragile | `-w '%{http_code}'` |
| Passwords/tokens in the URL | Visible in `ps` and shell history | Read from a file or `-H @file`; use `--netrc` |
| Probing hosts you do not own | Unauthorised scanning can be a legal and ethical problem | Test only your own or permitted systems |

## Exercises

### Easy: `port_open`

Write `port_open HOST PORT` using `/dev/tcp` and `timeout 2` so it returns 0 for an open port and
non-zero otherwise. Start a throwaway server on a free port, wait for it, and report your test
server's port and port 1.

**Acceptance criteria**

- Output: `test server port: open` and `port 1: closed`.
- No `nc`, `nmap` or `telnet` used.
- The server is stopped when the script ends (trap).

### Medium: status report

Write `http_status URL` that prints the status code (printing `000` on connection failure without
aborting under `set -e`) and `check_url URL LABEL` that prints `200 OK ...` / `404 FAIL ...` and
returns 0 or 1. Check the home page, a missing page and a port with nothing listening, and print how
many checks failed.

**Acceptance criteria**

- Lines: `200  OK    home page`, `404  FAIL  missing page`, `000  FAIL  nothing listening`.
- Final line: `2 check(s) failed`.
- Every `curl` call has a timeout.

### Hard: wait for a service

Write `wait_for_url URL MAX_SECONDS` with exponential back-off (1, 2, 4, 4, ... seconds) and a hard
deadline measured with `$SECONDS`. Start the test server **after a 2-second delay** to prove the
waiting works, then test a URL that never answers and confirm the function gives up.

**Acceptance criteria**

- First case prints `ready after 3 attempt(s)` (on a normal machine) and `service is ready`.
- Second case returns non-zero after about 2 seconds and prints `gave up after the deadline`.
- Progress messages go to stderr.

### Break it

This script has **two bugs**: it reports success for a page that does not exist, and it relies on a
guess about how long the server takes. Save as `break-it.sh`, run it, and fix it so it reports a
failed download and does not leave `report.html` behind.

```bash
#!/usr/bin/env bash
port="$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')"
mkdir site
echo "welcome" > site/index.html
python3 -m http.server "$port" --bind 127.0.0.1 --directory site >/dev/null 2>&1 &
server=$!

sleep 1

if curl -s "http://127.0.0.1:${port}/report.html" -o report.html; then
    echo "download ok"
fi
echo "first line of report.html: $(head -n 1 report.html)"

kill $server
```

**Expected output**

```text
download ok
first line of report.html: <!DOCTYPE HTML>
```

<details>
<summary>Hint</summary>

What is in `report.html`? Which `curl` flag makes an HTTP 404 count as failure? And what should
replace `sleep 1`?

</details>

## Solutions

<details>
<summary>Easy</summary>

`bash -c 'exec 3<>"/dev/tcp/$1/$2"' _ HOST PORT` passes the host and port as positional arguments, so
there is no string-building and no quoting risk.

```bash
#!/usr/bin/env bash
# Day 22 easy: test whether a TCP port accepts connections using only Bash (/dev/tcp).
# Uses a throwaway server on localhost.
set -euo pipefail

port_open() {
    local host="$1" port="$2"
    timeout 2 bash -c 'exec 3<>"/dev/tcp/$1/$2"' _ "$host" "$port" 2>/dev/null
}

port="$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')"
python3 -m http.server "$port" --bind 127.0.0.1 >/dev/null 2>&1 &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true' EXIT

for _ in {1..50}; do
    port_open 127.0.0.1 "$port" && break
    sleep 0.1
done

if port_open 127.0.0.1 "$port"; then echo "test server port: open"; else echo "test server port: closed"; fi
if port_open 127.0.0.1 1; then echo "port 1: open"; else echo "port 1: closed"; fi
```

**Expected output**

```text
test server port: open
port 1: closed
```

</details>

<details>
<summary>Medium</summary>

`curl ... || true` makes the function succeed even when curl fails; `-w '%{http_code}'` still prints
`000` in that case. The `case` pattern `2??|3??` matches any 2xx or 3xx code.

```bash
#!/usr/bin/env bash
# Day 22 medium: http_status URL prints the status code; check_url turns it into OK/FAIL.
# Uses a throwaway server on localhost.
set -euo pipefail

http_status() {
    # %{http_code} is 000 when no HTTP response was received at all
    curl -s -o /dev/null --max-time 3 -w '%{http_code}' "$1" || true
}

check_url() {
    local url="$1" code
    code="$(http_status "$url")"
    case "$code" in
        2??|3??) printf '%-4s OK    %s\n' "$code" "$2"; return 0 ;;
        *)       printf '%-4s FAIL  %s\n' "$code" "$2"; return 1 ;;
    esac
}

work="$(mktemp -d)"
echo "ok" > "${work}/index.html"
port="$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')"
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$work" >/dev/null 2>&1 &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true; rm -rf -- "$work"' EXIT

until curl -s -o /dev/null "http://127.0.0.1:${port}/"; do sleep 0.1; done

failed=0
check_url "http://127.0.0.1:${port}/"        "home page"        || failed=$(( failed + 1 ))
check_url "http://127.0.0.1:${port}/missing" "missing page"     || failed=$(( failed + 1 ))
check_url "http://127.0.0.1:1/"              "nothing listening" || failed=$(( failed + 1 ))

echo "${failed} check(s) failed"
```

**Expected output**

```text
200  OK    home page
404  FAIL  missing page
000  FAIL  nothing listening
2 check(s) failed
```

</details>

<details>
<summary>Hard</summary>

`$SECONDS` counts seconds since the shell started, so `deadline=$(( SECONDS + max ))` is a simple
timer. The server is launched by a background subshell that sleeps first. The trap kills it on exit.
The attempt count on your machine may differ by one if it is very slow.

```bash
#!/usr/bin/env bash
# Day 22 hard: wait_for_url with exponential back-off and an overall deadline.
# A throwaway server on localhost is started LATE on purpose, so the wait has something to do.
set -euo pipefail

# wait_for_url URL MAX_SECONDS  -> 0 when it answers with 2xx/3xx, 1 on timeout
wait_for_url() {
    local url="$1" deadline=$(( SECONDS + $2 )) delay=1 attempt=1
    while (( SECONDS < deadline )); do
        if curl -fsS -o /dev/null --max-time 2 "$url" 2>/dev/null; then
            echo "ready after ${attempt} attempt(s)" >&2
            return 0
        fi
        echo "attempt ${attempt} failed, retrying in ${delay}s" >&2
        sleep "$delay"
        attempt=$(( attempt + 1 ))
        (( delay < 4 )) && delay=$(( delay * 2 ))
    done
    return 1
}

work="$(mktemp -d)"
echo "ok" > "${work}/index.html"
port="$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')"

( sleep 2; exec python3 -m http.server "$port" --bind 127.0.0.1 --directory "$work" >/dev/null 2>&1 ) &
starter=$!
trap 'kill "$starter" 2>/dev/null || true; pkill -f "http.server ${port}" 2>/dev/null || true; rm -rf -- "$work"' EXIT

if wait_for_url "http://127.0.0.1:${port}/" 15; then
    echo "service is ready"
else
    echo "service did not become ready" >&2
    exit 1
fi

echo "--- a service that never starts"
if wait_for_url "http://127.0.0.1:1/" 2; then
    echo "unexpectedly ready"
else
    echo "gave up after the deadline, as designed"
fi
```

**Expected output**

```text
attempt 1 failed, retrying in 1s
attempt 2 failed, retrying in 2s
ready after 3 attempt(s)
service is ready
--- a service that never starts
attempt 1 failed, retrying in 1s
attempt 2 failed, retrying in 2s
gave up after the deadline, as designed
```

</details>

<details>
<summary>Break it</summary>

Bug 1: without `-f`, curl saves the server's HTML error page and exits 0, so the script said
"download ok" about a 404. Bug 2: `sleep 1` is a guess; wait for the port or URL instead. The fix also
cleans up the server with a `trap`.

```bash
#!/usr/bin/env bash
# Fixed: wait for the port instead of sleeping, make curl fail on HTTP errors (-f),
# and clean up the server with a trap.
set -euo pipefail

port="$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')"
mkdir site
echo "welcome" > site/index.html
python3 -m http.server "$port" --bind 127.0.0.1 --directory site >/dev/null 2>&1 &
server=$!
trap 'kill "$server" 2>/dev/null || true' EXIT

until curl -s -o /dev/null "http://127.0.0.1:${port}/"; do sleep 0.1; done

if curl -fsS "http://127.0.0.1:${port}/report.html" -o report.html 2>/dev/null; then
    echo "download ok"
else
    echo "download failed: no such page"
fi
[[ -f report.html ]] && rm -f report.html
echo "report.html exists: $([[ -f report.html ]] && echo yes || echo no)"
```

**Expected output**

```text
download failed: no such page
report.html exists: no
```

</details>

Solution files live in [`solutions/day-22/`](solutions/day-22/).

## Self-check

1. Which `curl` flag turns an HTTP 404 into a non-zero exit status?
2. What does a status code of `000` from `-w '%{http_code}'` mean?
3. How can you test a TCP port using only Bash?
4. Why is `sleep 5` a poor way to wait for a service?
5. Why might `ping` fail for a host that is up?

<details>
<summary>Answers</summary>

1. `-f` (`--fail`).
2. No HTTP response was received (connection refused, timeout, DNS failure).
3. `(exec 3<>/dev/tcp/HOST/PORT)` and check the exit status.
4. It is either too short (flaky) or too long (slow); polling with a deadline is both fast and reliable.
5. ICMP echo may be blocked by a firewall.

</details>

## Cheat sheet

| Command | Meaning |
|---------|---------|
| `getent hosts name` | Resolve a name |
| `ping -c 1 -W 2 host` | One ping, 2 s timeout |
| `nc -z -w 2 host port` | Port open? |
| `(exec 3<>/dev/tcp/h/p)` | Port open? (pure Bash) |
| `curl -fsS --max-time 5 URL` | Robust fetch |
| `curl -s -o /dev/null -w '%{http_code}' URL` | Status code |
| `ss -ltn` | Listening TCP sockets |
| `ip -brief address` | Interfaces and addresses |
| `timeout 3 cmd` | Kill after 3 seconds |

## Further reading

- [curl man page](https://curl.se/docs/manpage.html): every option, including `-w` variables and exit
  codes.
- [Everything curl](https://everything.curl.dev/): the free book from curl's author, with a chapter on
  scripting.
- [Greg's Wiki: BashFAQ/041](https://mywiki.wooledge.org/BashFAQ/041): explains `/dev/tcp` and other
  ways to reach the network from Bash.
- [ss(8) manual](https://man7.org/linux/man-pages/man8/ss.8.html): inspect sockets and connections.

**Next:** [Day 23](day-23.md)
