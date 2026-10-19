#!/usr/bin/env bash
# Fixed: export for children, source for the current shell, and extend PATH instead of replacing it.
set -euo pipefail

mkdir -p mybin
printf '#!/bin/sh\necho tool ran\n' > mybin/tool
chmod +x mybin/tool

export DB_HOST=db.local
bash -c 'echo "child sees DB_HOST=[${DB_HOST:-}]"'

printf 'export APP_MODE=prod\n' > setup.sh
source ./setup.sh
echo "APP_MODE is [${APP_MODE:-}]"

PATH="$PWD/mybin:$PATH"
tool
ls mybin
