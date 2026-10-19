#!/usr/bin/env bash
# Day 06 - Hard: logsummary.sh [FILE|-] - status-code counts and the top 3 clients of an access log.
# Usage: hard.sh access.log | hard.sh - < access.log | hard.sh --self-test
# Safe: read-only.
set -euo pipefail

summarise() {
  local src=${1:--} tmp
  # Buffer to a temp file so stdin input can be read twice.
  tmp=$(mktemp); trap 'rm -f "$tmp"' RETURN
  if [[ $src == - ]]; then cat > "$tmp"
  elif [[ -r $src ]]; then cp -- "$src" "$tmp"
  else echo "cannot read: $src" >&2; return 2; fi

  # Field 8 is the status, field 1 the client address (common-log style, no timezone).
  echo "== status codes =="
  awk '{print $8}' "$tmp" | sort | uniq -c | sort -k2n | awk '{print $2, $1}'
  echo "== top clients =="
  cut -d' ' -f1 "$tmp" | sort | uniq -c | sort -k1,1nr -k2,2 | head -n 3 | awk '{print $2, $1}'
}

self_test() {
  local w out; w=$(mktemp -d); trap 'rm -rf "$w"' RETURN
  cat > "$w/log" <<'EOF'
203.0.113.5 - - [10/Oct/2026:13:55:36] "GET /index.html HTTP/1.1" 200 1043
198.51.100.7 - - [10/Oct/2026:13:55:40] "GET /missing.png HTTP/1.1" 404 209
203.0.113.5 - - [10/Oct/2026:13:56:01] "POST /login HTTP/1.1" 302 404
192.0.2.44 - - [10/Oct/2026:13:57:12] "GET /index.html HTTP/1.1" 200 1043
198.51.100.7 - - [10/Oct/2026:13:57:30] "GET /about.html HTTP/1.1" 200 2310
203.0.113.5 - - [10/Oct/2026:13:58:02] "GET /api/data HTTP/1.1" 500 87
192.0.2.44 - - [10/Oct/2026:13:58:45] "GET /missing.css HTTP/1.1" 404 209
203.0.113.5 - - [10/Oct/2026:14:01:10] "GET /index.html HTTP/1.1" 200 1043
EOF
  out=$(summarise "$w/log")
  grep -qx '404 2' <<<"$out"            || { echo "FAIL: 404 count" >&2; return 1; }
  grep -qx '203.0.113.5 4' <<<"$out"    || { echo "FAIL: top client" >&2; return 1; }
  [[ $(summarise - < "$w/log") == "$out" ]] || { echo "FAIL: stdin differs" >&2; return 1; }
  (summarise "$w/none" 2>/dev/null) && { echo "FAIL: missing file accepted" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else summarise "$@"; fi
