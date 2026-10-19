#!/usr/bin/env bash
# Day 13 hard: build a deployment tree with exact modes, then verify it against a table.
# Exit 0 if every mode matches, 1 otherwise. Temporary files only; no root needed.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"

declare -A expected=(
    [app/bin]=755
    [app/conf]=750
    [app/conf/app.env]=640
    [app/data]=700
    [app/bin/run.sh]=750
)

install -d -m 755 app/bin
install -d -m 750 app/conf
install -d -m 700 app/data
printf '#!/bin/sh\necho ok\n' | install -m 750 /dev/stdin app/bin/run.sh
echo 'SECRET=1' | install -m 640 /dev/stdin app/conf/app.env
chmod 644 app/conf/app.env            # introduce one deliberate mistake

bad=0
mapfile -t paths <<< "$(printf '%s\n' "${!expected[@]}" | sort)"
for path in "${paths[@]}"; do
    actual="$(stat -c %a -- "$path")"
    if [[ $actual == "${expected[$path]}" ]]; then
        printf 'ok     %-18s %s\n' "$path" "$actual"
    else
        printf 'WRONG  %-18s %s (want %s)\n' "$path" "$actual" "${expected[$path]}"
        bad=$(( bad + 1 ))
    fi
done

cd / && rm -rf -- "$work"
echo "${bad} mismatch(es)"
if (( bad > 0 )); then
    exit 1
fi
