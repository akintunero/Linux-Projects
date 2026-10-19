#!/usr/bin/env bash
# Day 11 - Medium: list "human" accounts (UID 1000-59999) with their shell from a passwd-format file.
# Usage: medium.sh [PASSWD_FILE]    (default /etc/passwd). Read-only.
set -euo pipefail

humans() {
  # Fields: name:password:UID:GID:comment:home:shell
  awk -F: '$3 >= 1000 && $3 < 60000 {print $1, $3, $7}' "${1:-/etc/passwd}"
}

if [[ ${1:-} == --self-test ]]; then
  w=$(mktemp -d); trap 'rm -rf "$w"' EXIT
  cat > "$w/passwd" <<'EOF'
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
alice:x:1000:1000:Alice:/home/alice:/bin/bash
bob:x:1001:1001:Bob:/home/bob:/bin/zsh
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
EOF
  out=$(humans "$w/passwd")
  [[ $out == $'alice 1000 /bin/bash\nbob 1001 /bin/zsh' ]] || { echo "FAIL: $out" >&2; exit 1; }
  echo PASS >&2
else
  humans "$@"
fi
