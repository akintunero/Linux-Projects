#!/usr/bin/env bash
# Fixed: %% / ## take the LONGEST match, % / # the shortest; ${#var} is the length.
set -euo pipefail

file="archive.tar.gz"

echo "stem: ${file%%.*}"
echo "ext: ${file##*.}"
echo "length: ${#file}"
