#!/usr/bin/env bash
# Day 15 - Break it, fixed. Bugs were:
#   1. `Restart=always` is not allowed with Type=oneshot ("Refusing"). A one-shot job that should be
#      retried uses Restart=on-failure.
#   2. `Restrat=` is a typo: systemd ignores unknown keys with only a warning, so the retry never
#      happened. Always run `systemd-analyze verify`.
#   3. `ExecStart=report.sh` is not an absolute path: ExecStart must start with the full path of the program.
# NEEDS-TOOL: systemd-analyze (exits 77 if missing). Writes only to a temporary directory.
set -euo pipefail
command -v systemd-analyze >/dev/null || { echo "systemd-analyze missing" >&2; exit 77; }
dir=$(mktemp -d); trap 'rm -rf "$dir"' EXIT

cat > "$dir/report.sh" <<'EOF'
#!/bin/sh
echo "report done"
EOF
chmod 755 "$dir/report.sh"

cat > "$dir/good.service" <<EOF
[Unit]
Description=Nightly report

[Service]
Type=oneshot
ExecStart=$dir/report.sh --daily
Restart=on-failure
RestartSec=30

[Install]
WantedBy=default.target
EOF

out=$(systemd-analyze --user verify "$dir/good.service" 2>&1) && rc=0 || rc=$?
echo "verify exit status: $rc"
[[ -z $out && $rc -eq 0 ]] || { echo "FAIL: verify said: $out" >&2; exit 1; }
echo PASS >&2
