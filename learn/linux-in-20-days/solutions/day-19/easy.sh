#!/usr/bin/env bash
# Day 19 - Easy: read an exit status and a file mode instead of guessing.
# Builds the lab from break-it.sh in a temporary directory, shows that "Permission denied" is exit 126,
# proves the cause with stat, fixes exactly one thing, and records a three-line diagnosis note.
# NEEDS-TOOL: python3 (exits 77 if missing). Writes only inside a temporary directory.
set -uo pipefail
command -v python3 >/dev/null || { echo "python3 missing" >&2; exit 77; }
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
work=$(mktemp -d)
trap 'bash "$here/break-it.sh" --cleanup "$work/lab" >/dev/null 2>&1; rm -rf "$work"' EXIT

bash "$here/break-it.sh" "$work/lab" >/dev/null || { echo "FAIL: lab setup" >&2; exit 1; }
cd "$work/lab" || exit 1

./start.sh >/dev/null 2>&1; rc=$?                       # 1. observe: what exactly happens?
echo "exit status: $rc"
mode=$(stat -c '%A %n' start.sh)                        # 2. gather facts before changing anything
echo "mode: $mode"
[[ $rc -eq 126 && $mode == "-rw-r--r-- start.sh" ]] || { echo "FAIL: unexpected symptom rc=$rc mode=$mode" >&2; exit 1; }

chmod u+x start.sh                                      # 3. change ONE thing
./start.sh >/dev/null 2>&1; rc2=$?                      # 4. verify: did the symptom change?
echo "exit status after chmod: $rc2"
[[ $rc2 -ne 126 ]] || { echo "FAIL: still 126" >&2; exit 1; }

cat > diagnosis.txt <<EOF
symptom: ./start.sh exits $rc (Permission denied)
cause:   start.sh has mode rw-r--r-- (no execute bit)
fix:     chmod u+x start.sh   (next error is now: exit $rc2, a different problem)
EOF
cat diagnosis.txt
[[ $(wc -l < diagnosis.txt) -eq 3 ]] || { echo "FAIL: note must be 3 lines" >&2; exit 1; }
echo PASS >&2
