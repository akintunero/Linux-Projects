#!/usr/bin/env bash
# Day 17 - Hard: sshcheck.sh CONFIG ALIAS [key=value ...] - ask ssh what a host alias RESOLVES to
# (ssh -G never connects) and compare with what you intended; warn about risky client settings.
#   ok:    user=deploy       matches
#   FAIL:  port=2222 (got 22)
#   WARN:  stricthostkeychecking=no
# Exit: 0 all expectations met, 1 an expectation failed, 2 usage / ssh could not parse the file.
# Usage: hard.sh CONFIG ALIAS user=deploy port=2222 | hard.sh --self-test        Read-only, no network.
# NEEDS-TOOL: ssh (exits 77 if missing).
set -uo pipefail

sshcheck() {
  local cfg=${1:-} alias=${2:-}; shift 2 2>/dev/null || true
  [[ -f $cfg && -n $alias ]] || { echo "usage: sshcheck CONFIG ALIAS [key=value ...]" >&2; return 2; }
  local resolved; resolved=$(ssh -F "$cfg" -G "$alias" 2>/dev/null) || { echo "ssh could not parse $cfg" >&2; return 2; }

  local rc=0 exp key want got
  for exp in "$@"; do
    key=${exp%%=*}; want=${exp#*=}
    # ssh -G prints lowercase key names; some keys repeat (identityfile), so any matching line counts.
    if awk -v k="$(tr 'A-Z' 'a-z' <<<"$key")" -v w="$want" '$1 == k { sub(/^[^ ]+ /, ""); if ($0 == w) f = 1 } END { exit !f }' <<<"$resolved"; then
      echo "ok:    $key=$want"
    else
      got=$(awk -v k="$(tr 'A-Z' 'a-z' <<<"$key")" '$1 == k { sub(/^[^ ]+ /, ""); print; exit }' <<<"$resolved")
      echo "FAIL:  $key=$want (got ${got:-nothing})"; rc=1
    fi
  done

  grep -qx 'stricthostkeychecking false' <<<"$resolved" && echo "WARN:  stricthostkeychecking=no (host key is not verified)"
  grep -qx 'forwardagent yes' <<<"$resolved"           && echo "WARN:  forwardagent=yes (a compromised server can use your agent)"
  grep -qx 'passwordauthentication yes' <<<"$resolved" && true   # default; informational only
  return "$rc"
}

self_test() {
  command -v ssh >/dev/null || { echo "ssh missing" >&2; exit 77; }
  local w out rc; w=$(mktemp -d); trap 'rm -rf "$w"' RETURN
  cat > "$w/good" <<'EOF'
Host web
    HostName 192.0.2.10
    User deploy
    Port 2222
    ForwardAgent yes
    StrictHostKeyChecking no

Host *
    User nobody
EOF
  cat > "$w/wrongorder" <<'EOF'
Host *
    User nobody
    Port 22

Host web
    HostName 192.0.2.10
    User deploy
    Port 2222
EOF
  out=$(sshcheck "$w/good" web user=deploy port=2222 hostname=192.0.2.10); rc=$?
  [[ $rc -eq 0 && $out == *"ok:    user=deploy"* && $out == *"WARN:  forwardagent=yes"* && $out == *"WARN:  stricthostkeychecking=no"* ]] \
    || { echo "FAIL good: rc=$rc out=$out" >&2; return 1; }
  out=$(sshcheck "$w/wrongorder" web user=deploy port=2222); rc=$?
  [[ $rc -eq 1 && $out == *"FAIL:  user=deploy (got nobody)"* && $out == *"FAIL:  port=2222 (got 22)"* ]] \
    || { echo "FAIL wrongorder: rc=$rc out=$out" >&2; return 1; }
  printf 'Host x\n    Prot 22\n' > "$w/typo"
  sshcheck "$w/typo" x user=a >/dev/null 2>&1; rc=$?
  [[ $rc -eq 2 ]] || { echo "FAIL typo rc=$rc" >&2; return 1; }
  sshcheck 2>/dev/null; rc=$?
  [[ $rc -eq 2 ]] || { echo "FAIL usage rc=$rc" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else sshcheck "$@"; fi
