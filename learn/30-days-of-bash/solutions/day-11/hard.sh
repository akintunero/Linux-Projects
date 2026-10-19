#!/usr/bin/env bash
# Day 11 hard: set_option FILE KEY VALUE - idempotent config updater.
# Replaces "key=..." (even if commented out) or appends it. Temporary files only.
set -euo pipefail

set_option() {
    local file="$1" key="$2" value="$3"
    if grep -qE "^#?[[:space:]]*${key}=" "$file"; then
        sed -i -E "s|^#?[[:space:]]*${key}=.*|${key}=${value}|" "$file"
    else
        printf '%s=%s\n' "$key" "$value" >> "$file"
    fi
}

work="$(mktemp -d)"
conf="${work}/app.conf"
printf '# settings\nport=8080\n#log_level=info\n' > "$conf"

set_option "$conf" port 9090           # replace existing
set_option "$conf" log_level debug     # uncomment and change
set_option "$conf" workers 4           # append new
cp "$conf" "${work}/after-first-run"

set_option "$conf" port 9090           # run again: nothing should change
set_option "$conf" log_level debug
set_option "$conf" workers 4

cat "$conf"
if cmp -s "$conf" "${work}/after-first-run"; then
    echo "idempotent: second run changed nothing"
fi

rm -rf -- "$work"
