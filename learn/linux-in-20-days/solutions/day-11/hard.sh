#!/usr/bin/env bash
# Day 11 - Hard: userreport.sh [PASSWD [SHELLS]] - audit a passwd-format file.
#   UID0: NAME              extra accounts with UID 0 (only root should have it)
#   DUPLICATE-UID: UID NAMES accounts sharing a UID
#   BAD-SHELL: NAME SHELL   login shell is not listed in the shells file (and is not nologin/false)
# Usage: hard.sh [/etc/passwd [/etc/shells]] | hard.sh --self-test
# Read-only: it only reads the two files.
set -euo pipefail

userreport() {
  local passwd=${1:-/etc/passwd} shells=${2:-/etc/shells}
  [[ -r $passwd && -r $shells ]] || { echo "cannot read input files" >&2; return 2; }

  awk -F: '$3 == 0 && $1 != "root" {print "UID0: " $1}' "$passwd"

  awk -F: '{names[$3] = names[$3] " " $1; n[$3]++}
           END {for (u in n) if (n[u] > 1) print "DUPLICATE-UID: " u names[u]}' "$passwd" | sort

  awk -F: 'NR == FNR { if ($0 !~ /^#/ && $0 != "") ok[$0] = 1; next }
           $7 != "" && !($7 in ok) && $7 !~ /(nologin|false)$/ { print "BAD-SHELL: " $1 " " $7 }' \
      "$shells" "$passwd"
}

self_test() {
  local w out; w=$(mktemp -d); trap 'rm -rf "$w"' RETURN
  cat > "$w/passwd" <<'EOF'
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
alice:x:1000:1000:Alice:/home/alice:/bin/bash
bob:x:1001:1001:Bob:/home/bob:/bin/zsh
mallory:x:0:0:evil:/home/mallory:/bin/bash
twin:x:1001:1002::/home/twin:/bin/sh
EOF
  printf '# valid shells\n/bin/sh\n/bin/bash\n' > "$w/shells"
  out=$(userreport "$w/passwd" "$w/shells")
  # mallory shares UID 0 with root, so it is both a UID0 finding and a duplicate.
  [[ $out == $'UID0: mallory\nDUPLICATE-UID: 0 root mallory\nDUPLICATE-UID: 1001 bob twin\nBAD-SHELL: bob /bin/zsh' ]] \
    || { echo "FAIL: got:"; echo "$out"; return 1; } >&2
  (userreport "$w/none" "$w/shells" 2>/dev/null) && { echo "FAIL: missing file" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else userreport "$@"; fi
