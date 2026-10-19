#!/usr/bin/env bash
# Day 08 medium: generate a config with a here-doc and verify it with a here-string.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"

app="shop"
port=8080

cat > "${app}.conf" <<EOF
# generated config for ${app}
listen_port=${port}
log_file=/var/log/${app}.log
EOF

cat > template.conf <<'EOF'
listen_port=${port}
EOF

echo "--- ${app}.conf"
cat "${app}.conf"
echo "--- template.conf (nothing expanded)"
cat template.conf

content="$(< "${app}.conf")"
if grep -q "^listen_port=8080$" <<< "$content"; then
    echo "check passed: port is 8080"
else
    echo "check FAILED" >&2
    exit 1
fi

cd / && rm -rf -- "$work"
