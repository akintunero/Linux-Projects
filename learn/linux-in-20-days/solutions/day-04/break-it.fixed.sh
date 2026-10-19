#!/usr/bin/env bash
# Day 04 - Break it, fixed. Bugs were:
#   1. `umask 000` creates world-writable files (666) and directories (777) -> use 022.
#   2. `chmod -R 644 site` removes the x bit from directories, so nothing inside can be entered.
#   3. It also removes x from deploy.sh, so it can no longer be executed.
# Fix: directories 755, files 644, scripts 755. Use find so each type gets its own mode.
# Safe: temporary directory only.
set -euo pipefail
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

umask 022
mkdir -p site/bin site/css
printf '#!/bin/sh\necho deploy\n' > site/bin/deploy.sh
echo "body{}" > site/css/main.css

find site -type d -exec chmod 755 {} +
find site -type f -exec chmod 644 {} +
chmod 755 site/bin/deploy.sh

site/bin/deploy.sh
ls site/css

[[ $(stat -c %a site/css) == 755 && $(stat -c %a site/css/main.css) == 644 ]] || { echo FAIL >&2; exit 1; }
echo PASS >&2
