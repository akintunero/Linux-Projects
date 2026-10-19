#!/usr/bin/env bash
# Day 20 easy: write five crontab lines to a file and sanity-check their shape.
# This does NOT install anything into your real crontab.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/crontab.txt" <<'EOF'
# m  h    dom mon dow  command
30   2    *   *   *    /opt/jobs/backup.sh >> /var/log/backup.log 2>&1
*/15 9-17 *   *   1-5  /opt/jobs/check.sh
0    0    1   *   *    /opt/jobs/monthly-report.sh
0    3    *   *   0    /opt/jobs/cleanup.sh
@reboot                /opt/jobs/start.sh
EOF

bad=0
while IFS= read -r line; do
    case "$line" in ''|'#'*) continue ;; esac
    read -ra words <<< "$line"
    if [[ ${words[0]} == @* ]]; then
        need=2
    else
        need=6
    fi
    if (( ${#words[@]} >= need )); then
        echo "ok:  ${line}"
    else
        echo "BAD: ${line}"
        bad=$(( bad + 1 ))
    fi
done < "${work}/crontab.txt"

echo "${bad} bad line(s)"
rm -rf -- "$work"
(( bad == 0 ))
