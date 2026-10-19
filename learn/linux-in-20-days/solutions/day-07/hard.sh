#!/usr/bin/env bash
# Day 07 - Hard: confset.sh FILE KEY VALUE - set KEY=VALUE in a config file.
#   * replaces an existing active "KEY=..." line (never a commented "#KEY=..." line)
#   * appends the line when KEY is missing
#   * keeps FILE.bak, and VALUE may contain / & and other characters special to sed
# Usage: hard.sh FILE KEY VALUE | hard.sh --self-test
# Safe: edits FILE in place after making FILE.bak.
set -euo pipefail

confset() {
  local file=${1:?usage: confset FILE KEY VALUE} key=${2:?key} value=${3?value}
  [[ -f $file ]] || { echo "not a file: $file" >&2; return 2; }
  [[ $key =~ ^[A-Za-z_][A-Za-z0-9_.-]*$ ]] || { echo "bad key: $key" >&2; return 2; }
  cp -p -- "$file" "$file.bak"
  if grep -q "^${key}=" "$file"; then
    # awk does the replacement, so VALUE needs no sed escaping; ENVIRON avoids -v backslash processing.
    K=$key V=$value awk -F= 'BEGIN{OFS="="; k=ENVIRON["K"]; v=ENVIRON["V"]} $1 == k {print k, v; next} {print}' \
      "$file.bak" > "$file"
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
}

self_test() {
  local w; w=$(mktemp -d); trap 'rm -rf "$w"' RETURN
  printf '#port=1\nport=80\nroot=/var/www\n' > "$w/c"
  confset "$w/c" root /srv/site/a\&b
  grep -qxF 'root=/srv/site/a&b' "$w/c"       || { echo "FAIL: replace" >&2; return 1; }
  grep -qxF '#port=1' "$w/c"                  || { echo "FAIL: comment touched" >&2; return 1; }
  grep -qxF 'root=/var/www' "$w/c.bak"        || { echo "FAIL: backup" >&2; return 1; }
  confset "$w/c" user www-data
  [[ $(tail -n 1 "$w/c") == user=www-data ]]  || { echo "FAIL: append" >&2; return 1; }
  (confset "$w/nope" a b 2>/dev/null)         && { echo "FAIL: missing file" >&2; return 1; }
  (confset "$w/c" 'a b' c 2>/dev/null)        && { echo "FAIL: bad key" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else confset "$@"; fi
