#!/usr/bin/env bash
# Day 11 easy: change one setting in a config file, keep a backup, show the difference.
set -euo pipefail

work="$(mktemp -d)"
cd "$work"
printf 'port=8080\ndebug=true\nname=shop\n' > app.conf

sed -i.bak 's/^debug=.*/debug=false/' app.conf

echo "--- diff (old vs new)"
diff app.conf.bak app.conf || true
echo "--- new file"
cat app.conf

cd / && rm -rf -- "$work"
