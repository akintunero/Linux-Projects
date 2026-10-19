#!/usr/bin/env bash
# Fixed: wait for the background jobs and read their status from wait, not from $?.
set -euo pipefail

(sleep 0.3; echo finished > result.txt) &
first=$!
wait "$first"
cat result.txt

(sleep 0.1; exit 3) &
second=$!
status=0
wait "$second" || status=$?
echo "job exit status: ${status}"
echo "all done"
