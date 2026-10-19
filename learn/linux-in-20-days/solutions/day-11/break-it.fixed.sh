#!/usr/bin/env bash
# Day 11 - Break it, fixed. Prints the plan; executes nothing. Bugs were:
#   1. `usermod -G group user` REPLACES all supplementary groups (user loses sudo, docker...) -> -aG.
#   2. `NOPASSWD: ALL` hands out unrestricted root -> allow one command only, validate with visudo -cf,
#      and a sudoers drop-in must be mode 0440.
#   3. `chmod 777 /home/user` lets everybody read and write the home directory -> 750 (or 700).
# Variables are quoted. Self-test: break-it.fixed.sh --self-test
set -euo pipefail

plan() {
  local user=$1 group=$2
  printf '%s\n' \
    "useradd -m -s /bin/bash -- '$user'" \
    "usermod -aG '$group' -- '$user'" \
    "echo '$user ALL=(root) NOPASSWD: /usr/bin/systemctl restart myapp' > /etc/sudoers.d/$user" \
    "chmod 0440 /etc/sudoers.d/$user" \
    "visudo -cf /etc/sudoers.d/$user" \
    "chmod 750 /home/$user"
}

if [[ ${1:-} == --self-test ]]; then
  out=$(plan alice devs)
  grep -q 'usermod -aG' <<<"$out"          || { echo "FAIL: -aG" >&2; exit 1; }
  ! grep -q '777' <<<"$out"                || { echo "FAIL: 777" >&2; exit 1; }
  ! grep -q 'NOPASSWD: ALL' <<<"$out"      || { echo "FAIL: unrestricted sudo" >&2; exit 1; }
  grep -q 'chmod 0440' <<<"$out"           || { echo "FAIL: sudoers mode" >&2; exit 1; }
  grep -q 'visudo -cf' <<<"$out"           || { echo "FAIL: no validation" >&2; exit 1; }
  echo PASS >&2
else
  plan "${1:-alice}" "${2:-devs}"
fi
