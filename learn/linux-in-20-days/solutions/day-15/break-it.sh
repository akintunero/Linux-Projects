#!/usr/bin/env bash
# Day 15 - Break it (BUGGY on purpose). Writes bad.service into a scratch directory and verifies it.
# Fix the unit text below until `systemd-analyze --user verify` prints nothing and exits 0.
# It does not install or start anything. NEEDS-TOOL: systemd-analyze.
dir=$(mktemp -d)
cat > "$dir/bad.service" <<'EOF'
[Unit]
Description=Nightly report

[Service]
Type=oneshot
ExecStart=report.sh --daily
Restrat=on-failure
Restart=always

[Install]
WantedBy=default.target
EOF
systemd-analyze --user verify "$dir/bad.service"
echo "verify exit status: $?"
rm -rf "$dir"
