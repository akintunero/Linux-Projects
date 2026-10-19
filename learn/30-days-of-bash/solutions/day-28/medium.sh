#!/usr/bin/env bash
# Day 28 medium: audit user accounts from passwd/shadow-format files (fixtures, read-only).
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/passwd" <<'EOF'
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
ada:x:1000:1000:Ada:/home/ada:/bin/bash
grace:x:1001:1001:Grace:/home/grace:/bin/zsh
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
toor:x:0:0:second root:/root:/bin/sh
svc-app:x:1002:1002:app:/srv/app:/bin/false
EOF
cat > "${work}/shadow" <<'EOF'
root:$6$hash:19000:0:99999:7:::
ada:$6$hash:19000:0:99999:7:::
grace::19000:0:99999:7:::
svc-app:!:19000:0:99999:7:::
EOF

echo "human accounts (UID >= 1000 with a real login shell):"
awk -F: '$3 >= 1000 && $7 !~ /(nologin|false)$/ { printf "  %-8s uid=%s shell=%s\n", $1, $3, $7 }' "${work}/passwd"

echo "accounts with UID 0 (should be only root):"
awk -F: '$3 == 0 { print "  " $1 }' "${work}/passwd"
extra="$(awk -F: '$3 == 0 && $1 != "root" { n++ } END { print n + 0 }' "${work}/passwd")"
(( extra == 0 )) || echo "WARNING: ${extra} extra UID 0 account(s)"

echo "accounts with an EMPTY password field in shadow:"
awk -F: '$2 == "" { print "  " $1 }' "${work}/shadow"

rm -rf -- "$work"
