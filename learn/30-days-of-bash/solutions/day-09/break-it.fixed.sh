#!/usr/bin/env bash
# Fixed: quote "${files[@]}", use ${#files[@]} for the count, and declare -A for string keys.
set -euo pipefail

files=("my file.txt" b.txt)

for f in "${files[@]}"; do
    echo "item: $f"
done

echo "count: ${#files[@]}"

declare -A ports=([http]=80 [https]=443)
echo "http is ${ports[http]}"
echo "entries: ${#ports[@]}"
