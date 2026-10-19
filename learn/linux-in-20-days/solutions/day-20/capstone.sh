#!/usr/bin/env bash
# Day 20 - Capstone, user-mode edition: run a small web service under systemd, check it, back it up on a
# timer with a verified restore, then break it on purpose and watch it recover.
#   Stage 1: service up and health-checked            (Days 10, 12, 15)
#   Stage 2: + timer-driven backup, restore verified  (Days 14, 16)
#   Stage 3: + failure drill: kill -9, auto-restart, down detection (Days 13, 15, 19)
# Usage: capstone.sh --stage 1|2|3 | capstone.sh --self-test (= stage 3)
# Uses `systemctl --user` (no root), 127.0.0.1 only, a temporary directory, and removes everything it
# creates (units named linux20-cap-*). Exit 77 when a user systemd manager or python3/curl is missing.
# NEEDS-TOOL: systemd user manager, python3, curl, tar, sha256sum.
set -uo pipefail

for t in python3 curl tar sha256sum systemctl journalctl; do command -v "$t" >/dev/null || { echo "$t missing" >&2; exit 77; }; done
[[ $(systemctl --user is-system-running 2>/dev/null) =~ ^(running|degraded)$ ]] || { echo "no systemd user manager" >&2; exit 77; }

stage=3
case ${1:-} in
  --stage) stage=${2:-}; [[ $stage =~ ^[123]$ ]] || { echo "stage must be 1, 2 or 3" >&2; exit 2; } ;;
  --self-test|"") stage=3 ;;
  *) echo "usage: capstone.sh --stage 1|2|3" >&2; exit 2 ;;
esac

work=$(mktemp -d)
udir=$HOME/.config/systemd/user
svc=linux20-cap-web.service
bak=linux20-cap-backup.service
tim=linux20-cap-backup.timer
fail() { echo "FAIL: $*" >&2; exit 1; }
cleanup() {
  systemctl --user stop "$tim" "$svc" "$bak" 2>/dev/null
  systemctl --user reset-failed "$svc" "$bak" 2>/dev/null
  rm -f "$udir/$svc" "$udir/$bak" "$udir/$tim"
  systemctl --user daemon-reload
  rm -rf "$work"
}
trap cleanup EXIT
mkdir -p "$udir" "$work/site" "$work/backups"

port=$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')
echo '<h1>capstone</h1>' > "$work/site/index.html"

# ---- health check: exit 0 up, 2 down (monitoring convention: 2 = critical)
cat > "$work/healthcheck.sh" <<EOF
#!/usr/bin/env bash
if curl -sf -m 3 --connect-timeout 2 -o /dev/null "http://127.0.0.1:$port/"; then echo "OK web is up"; exit 0; fi
echo "CRITICAL web is down"; exit 2
EOF
chmod 755 "$work/healthcheck.sh"
wait_healthy() { for _ in $(seq 1 30); do "$work/healthcheck.sh" >/dev/null && return 0; sleep 0.3; done; return 1; }

# ---- stage 1: the service
cat > "$udir/$svc" <<EOF
[Unit]
Description=Linux in 20 days capstone web

[Service]
ExecStart=$(command -v python3) -m http.server $port --bind 127.0.0.1 --directory $work/site
Restart=on-failure
RestartSec=1

[Install]
WantedBy=default.target
EOF
systemd-analyze --user verify "$udir/$svc" || fail "unit does not verify"
systemctl --user daemon-reload
systemctl --user start "$svc" || fail "service did not start"
wait_healthy || fail "service never became healthy"
"$work/healthcheck.sh"
[[ $(curl -s "http://127.0.0.1:$port/") == '<h1>capstone</h1>' ]] || fail "wrong page"
[[ $stage -ge 2 ]] || { echo PASS >&2; exit 0; }

# ---- stage 2: backup on a timer, with restore test
cat > "$work/backup.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
archive="$work/backups/site-\$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "\$archive" -C "$work" site
sha256sum "\$archive" > "\$archive.sha256"
sha256sum -c "\$archive.sha256" >/dev/null
rm -rf "$work/restore" && mkdir "$work/restore"
tar -xzf "\$archive" -C "$work/restore"
diff -r "$work/site" "$work/restore/site"
echo "backup ok: \$archive"
EOF
chmod 755 "$work/backup.sh"
cat > "$udir/$bak" <<EOF
[Unit]
Description=Linux in 20 days capstone backup

[Service]
Type=oneshot
ExecStart=$work/backup.sh
EOF
cat > "$udir/$tim" <<EOF
[Unit]
Description=Capstone backup timer

[Timer]
OnActiveSec=1s

[Install]
WantedBy=timers.target
EOF
systemd-analyze --user verify "$udir/$bak" "$udir/$tim" || fail "backup units do not verify"
systemctl --user daemon-reload
systemctl --user start "$tim"
ok=0; for _ in $(seq 1 60); do
  compgen -G "$work/backups/site-*.tar.gz" >/dev/null && { ok=1; break; }; sleep 0.5
done
((ok)) || fail "timer never produced an archive"
( cd "$work/backups" && sha256sum -c ./*.sha256 >/dev/null ) || fail "checksum"
diff -r "$work/site" "$work/restore/site" || fail "restore differs"
echo "backup verified by restore"
[[ $stage -ge 3 ]] || { echo PASS >&2; exit 0; }

# ---- stage 3: failure drill
systemctl --user kill -s KILL "$svc"
r=0; for _ in $(seq 1 30); do
  r=$(systemctl --user show -p NRestarts --value "$svc"); ((r >= 1)) && break; sleep 0.3
done
((r >= 1)) || fail "service was not restarted after kill -9"
wait_healthy || fail "service unhealthy after restart"
echo "recovered after kill -9 (NRestarts=$r)"
journalctl --user -u "$svc" --no-pager -o cat 2>/dev/null | grep -qi 'killed\|SIGKILL\|Scheduled restart\|Main process exited' \
  || fail "journal has no trace of the crash"
systemctl --user stop "$svc"
"$work/healthcheck.sh" >/dev/null; rc=$?
[[ $rc -eq 2 ]] || fail "health check should exit 2 when down, got $rc"
echo "health check reports CRITICAL (exit 2) while stopped"
echo PASS >&2
