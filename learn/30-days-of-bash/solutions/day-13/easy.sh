#!/usr/bin/env bash
# Day 13 easy: create a secrets file that only its owner can read and write.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"

touch secrets.env
chmod 600 secrets.env

mode="$(stat -c %a secrets.env)"
echo "secrets.env mode: ${mode}"
if [[ $mode == 600 ]]; then
    echo "OK: private to the owner"
fi
stat -c '%A' secrets.env

cd / && rm -rf -- "$work"
