#!/usr/bin/env bash
# Day 21 hard: find brute-force SSH attempts in an auth log and report offenders.
# Read-only: it analyses a sample log it creates itself.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/auth.log" <<'EOF'
Oct 10 03:12:01 srv sshd[811]: Failed password for root from 203.0.113.50 port 51122 ssh2
Oct 10 03:12:03 srv sshd[811]: Failed password for root from 203.0.113.50 port 51124 ssh2
Oct 10 03:12:06 srv sshd[813]: Failed password for invalid user admin from 203.0.113.50 port 51130 ssh2
Oct 10 03:14:40 srv sshd[820]: Accepted publickey for ada from 192.0.2.10 port 40022 ssh2
Oct 10 03:15:12 srv sshd[825]: Failed password for deploy from 198.51.100.9 port 60011 ssh2
Oct 10 03:15:15 srv sshd[826]: Failed password for invalid user test from 198.51.100.9 port 60013 ssh2
Oct 10 03:16:02 srv sshd[830]: Failed password for ada from 192.0.2.10 port 40050 ssh2
Oct 10 03:16:44 srv CRON[900]: session opened for user root
EOF

re='Failed password for (invalid user )?([A-Za-z0-9_.-]+) from ([0-9.]+) port'
declare -A attempts users
threshold=3

while IFS= read -r line; do
    if [[ $line =~ $re ]]; then
        ip="${BASH_REMATCH[3]}"
        attempts[$ip]=$(( ${attempts[$ip]:-0} + 1 ))
        users[$ip]+="${BASH_REMATCH[2]} "
    fi
done < "${work}/auth.log"

mapfile -t ips <<< "$(printf '%s\n' "${!attempts[@]}" | sort)"
printf '%-16s %-9s %s\n' "SOURCE" "ATTEMPTS" "USERS TRIED"
for ip in "${ips[@]}"; do
    printf '%-16s %-9d %s\n' "$ip" "${attempts[$ip]}" "${users[$ip]% }"
done

echo "--- offenders (>= ${threshold} attempts)"
for ip in "${ips[@]}"; do
    if (( attempts[$ip] >= threshold )); then
        echo "BLOCK CANDIDATE: $ip"
    fi
done

rm -rf -- "$work"
