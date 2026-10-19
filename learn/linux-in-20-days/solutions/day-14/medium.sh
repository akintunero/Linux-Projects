#!/usr/bin/env bash
# Day 14 - Medium: prove a backup works by restoring it elsewhere and comparing, and show that a
# damaged archive is detected by its checksum.
# Safe: temporary directory only.
set -euo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

mkdir -p site/css
echo "<h1>home</h1>" > site/index.html
echo "body{}" > site/css/main.css
tar -czf site.tar.gz site
sha256sum site.tar.gz > site.tar.gz.sha256

mkdir restore
tar -xzf site.tar.gz -C restore
diff -r site restore/site && echo "restore identical"

printf 'garbage' >> site.tar.gz                  # simulate a damaged copy
if sha256sum -c site.tar.gz.sha256 >/dev/null 2>&1; then
  echo "FAIL: damage not detected" >&2; exit 1
fi
echo "damage detected by checksum"
echo PASS >&2
