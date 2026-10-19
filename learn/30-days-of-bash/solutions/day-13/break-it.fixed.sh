#!/usr/bin/env bash
# Fixed: give scripts the execute bit (not 777), and directories need x to be entered.
set -euo pipefail

echo 'echo "deploy ok"' > deploy.sh
chmod 755 deploy.sh
./deploy.sh

mkdir -p reports
touch reports/q1.txt
chmod 700 reports
cat reports/q1.txt && echo "read q1.txt"

stat -c '%a %n' deploy.sh
