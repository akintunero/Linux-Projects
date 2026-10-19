#!/usr/bin/env bash
# Day 01 hard: environment check. Exit 0 if every tool is present, 1 otherwise.
tools=(bash git awk sed grep)
missing=0

printf '%-8s %s\n' "TOOL" "STATUS"
for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf '%-8s %s\n' "$tool" "OK"
    else
        printf '%-8s %s\n' "$tool" "MISSING"
        missing=$((missing + 1))
    fi
done

if (( missing > 0 )); then
    echo "$missing tool(s) missing" >&2
    exit 1
fi
echo "All tools present."
