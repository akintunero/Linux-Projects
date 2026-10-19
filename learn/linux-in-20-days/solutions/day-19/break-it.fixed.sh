#!/usr/bin/env bash
# Day 19 - Break it, fixed. Builds the broken lab in a temporary directory, diagnoses each fault the
# way the lesson teaches, fixes it, and finally checks that the page is served. Faults and diagnosis:
#   1. `./start.sh` -> "Permission denied", exit 126.   Diagnose: ls -l start.sh (mode 644, no x).  Fix: chmod u+x.
#   2. "PORT is not set in app.conf".                    Diagnose: read app.conf -> key spelled PROT.   Fix: PORT=...
#   3. "Address already in use".                         Diagnose: ss -ltnp 'sport = :PORT' -> another PID.
#      Fix: stop THAT process (it is the lab's own blocker), not a random python.
# NEEDS-TOOL: python3, ss, curl (exits 77 if missing). Writes only inside a temporary directory.
set -uo pipefail
for t in python3 ss curl; do command -v "$t" >/dev/null || { echo "$t missing" >&2; exit 77; }; done
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
work=$(mktemp -d)
cleanup() { bash "$here/break-it.sh" --cleanup "$work/lab" >/dev/null 2>&1; [[ -n ${app:-} ]] && kill "$app" 2>/dev/null; rm -rf "$work"; }
trap cleanup EXIT

bash "$here/break-it.sh" "$work/lab" >/dev/null || { echo "FAIL: lab setup" >&2; exit 1; }
cd "$work/lab" || exit 1

# --- fault 1
./start.sh >/dev/null 2>&1; rc=$?
[[ $rc -eq 126 ]] || { echo "FAIL: expected 126, got $rc" >&2; exit 1; }
[[ $(stat -c %A start.sh) == -rw-r--r-- ]] || { echo "FAIL: start.sh mode unexpected" >&2; exit 1; }
chmod u+x start.sh
echo "fault 1 fixed: start.sh was not executable (126)"

# --- fault 2
msg=$(./start.sh 2>&1); rc=$?
[[ $rc -ne 0 && $msg == *"PORT is not set"* ]] || { echo "FAIL: expected PORT message, got: $msg" >&2; exit 1; }
grep -q '^PROT=' app.conf || { echo "FAIL: typo not present" >&2; exit 1; }
sed -i 's/^PROT=/PORT=/' app.conf
echo "fault 2 fixed: app.conf said PROT instead of PORT"

# --- fault 3
msg=$(timeout 5 ./start.sh 2>&1); rc=$?
[[ $rc -ne 0 && $msg == *"in use"* ]] || { echo "FAIL: expected 'in use', got rc=$rc: $msg" >&2; exit 1; }
port=$(sed -n 's/^PORT=//p' app.conf)
holder=$(ss -ltnp "sport = :$port" | grep -o 'pid=[0-9]*' | head -n 1 | cut -d= -f2)
[[ -n $holder && $holder == "$(cat blocker.pid)" ]] || { echo "FAIL: holder '$holder' is not the blocker" >&2; exit 1; }
echo "fault 3: port $port is held by PID $holder: $(ps -o args= -p "$holder" | cut -c1-40)..."
kill "$holder"; sleep 0.5
ss -ltn "sport = :$port" | grep -q LISTEN && { echo "FAIL: port still busy" >&2; exit 1; }
echo "fault 3 fixed: the process holding the port was stopped"

# --- verify the original symptom is gone
./start.sh > start.out 2>&1 & app=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do curl -sf "http://127.0.0.1:$port/" >/dev/null 2>&1 && break; sleep 0.3; done
page=$(curl -sf "http://127.0.0.1:$port/" || true)
echo "page: $page"
[[ $page == '<h1>app is up</h1>' ]] || { echo "FAIL: app does not serve the page" >&2; exit 1; }
echo PASS >&2
