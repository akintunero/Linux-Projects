#!/usr/bin/env bash
# Day 20 - Break it (BUGGY on purpose). Fix the unit text until `verify` is silent and exit status is 0.
# The unit is meant to run a web server for ~/site as a USER service that restarts after crashes and
# starts at login. It never installs or starts anything.
# NEEDS-TOOL: systemd-analyze.
dir=$(mktemp -d)
cat > "$dir/web.service" <<'EOF'
[Unit]
Description=Capstone web

[Service]
ExecStart=python3 -m http.server 8080 --bind 127.0.0.1
Restart=always
RestartSec=1
Type=oneshot

[Install]
WantedBy=multi-user.target
EOF
systemd-analyze --user verify "$dir/web.service"
echo "verify exit status: $?"
rm -rf "$dir"
