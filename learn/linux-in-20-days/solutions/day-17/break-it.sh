#!/usr/bin/env bash
# Day 17 - Break it (BUGGY on purpose). Edit the config text below, then run the script.
# It never connects anywhere: `ssh -G` only prints the settings ssh WOULD use.
# Goal: "ssh web" must mean  deploy@192.0.2.10 port 2222  with a local forward  8080 -> localhost:80,
# and `ssh -G` must print no errors.
# NEEDS-TOOL: ssh.
dir=$(mktemp -d)
cat > "$dir/config" <<'EOF'
Host *
    User nobody
    ServerAliveInterval 30

Host web
    HostName 192.0.2.10
    User deploy
    Port 2222
    LocalForward 8080:localhost:80
    Prot 2222
EOF
ssh -F "$dir/config" -G web | grep -E '^(hostname|user|port|localforward) '
rm -rf "$dir"
