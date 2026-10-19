#!/usr/bin/env bash
# Day 17 hard: checksum a tree in parallel, then detect a changed file.
# Temporary files only.
set -euo pipefail

work="$(mktemp -d)"
mkdir -p "${work}/data/sub"
for i in 1 2 3 4 5 6; do
    echo "content ${i}" > "${work}/data/file${i}.txt"
done
echo "nested" > "${work}/data/sub/deep file.txt"
cd "${work}/data"

snapshot() {
    # -print0/-0 keeps "deep file.txt" in one piece; -P 3 -n 2 hashes 3 batches at a time.
    find . -type f -print0 | xargs -0 -n 2 -P 3 sha256sum | sort -k2
}

snapshot > ../before.sha
echo "hashed $(wc -l < ../before.sha) files in parallel"

echo "--- verify: everything should be OK"
sha256sum -c --quiet ../before.sha && echo "all files match"

echo "--- change one file"
echo "tampered" > file3.txt
status=0
sha256sum -c --quiet ../before.sha 2>&1 || status=$?
echo "verify exit status: ${status}"

echo "--- compare two snapshots without temporary files"
diff <(cut -c1-12,65- ../before.sha) <(snapshot | cut -c1-12,65-) || true

cd / && rm -rf -- "$work"
