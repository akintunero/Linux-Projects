#!/usr/bin/env bash
# Day 16 - Hard: cronlint.sh [--system] FILE - validate crontab syntax without installing it.
#   Checks: five time fields (or an @keyword), value ranges, lists, ranges, steps, month/day names,
#   a non-empty command, and unescaped % in the command (cron turns it into a newline).
#   --system: the file is in /etc/cron.d format and has a user name as the sixth field.
# Output: FILE:LINE: message      Exit: 0 clean, 1 problems found, 2 usage.
# Usage: hard.sh [--system] FILE | hard.sh --self-test        Read-only.
set -uo pipefail

# valid_field VALUE MIN MAX [names-regex]
valid_field() {
  local value=$1 min=$2 max=$3 names=${4:-} part range step lo hi
  local num='[0-9]+'
  IFS=, read -ra parts <<<"$value"
  ((${#parts[@]} > 0)) || return 1
  for part in "${parts[@]}"; do
    range=${part%%/*}; step=
    [[ $part == */* ]] && { step=${part#*/}; [[ $step =~ ^[1-9][0-9]*$ ]] || return 1; }
    if [[ $range == '*' ]]; then continue; fi
    # Month/day names are only checked for being valid names; map them to an in-range number.
    if [[ -n $names ]]; then range=$(tr 'A-Z' 'a-z' <<<"$range" | sed -E "s/$names/$min/g"); fi
    if [[ $range =~ ^($num)-($num)$ ]]; then
      lo=${BASH_REMATCH[1]} hi=${BASH_REMATCH[2]}
      ((lo <= hi)) || return 1
    elif [[ $range =~ ^$num$ ]]; then
      lo=$range hi=$range
    else
      return 1
    fi
    ((10#$lo >= min && 10#$hi <= max)) || return 1
  done
}

cronlint() {
  local system=0
  [[ ${1:-} == --system ]] && { system=1; shift; }
  local file=${1:-}
  [[ -f $file ]] || { echo "usage: cronlint [--system] FILE" >&2; return 2; }

  local n=0 bad=0 line f1 f2 f3 f4 f5 rest user cmd
  local months='jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec'
  local days='sun|mon|tue|wed|thu|fri|sat'
  err() { printf '%s:%d: %s\n' "$file" "$n" "$1"; bad=1; }

  while IFS= read -r line || [[ -n $line ]]; do
    n=$((n + 1))
    [[ $line =~ ^[[:space:]]*(#|$) ]] && continue                    # comment or blank
    [[ $line =~ ^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*= ]] && continue   # VAR=value

    if [[ $line =~ ^[[:space:]]*@(reboot|yearly|annually|monthly|weekly|daily|midnight|hourly)[[:space:]]+(.*)$ ]]; then
      rest=${BASH_REMATCH[2]}
    else
      read -r f1 f2 f3 f4 f5 rest <<<"$line"
      if [[ -z ${f5:-} || -z ${rest:-} ]]; then err "expected 5 time fields and a command"; continue; fi
      valid_field "$f1" 0 59        || err "bad minute '$f1'"
      valid_field "$f2" 0 23        || err "bad hour '$f2'"
      valid_field "$f3" 1 31        || err "bad day of month '$f3'"
      valid_field "$f4" 1 12 "$months" || err "bad month '$f4'"
      valid_field "$f5" 0 7 "$days"   || err "bad day of week '$f5'"
    fi

    cmd=$rest
    if ((system)); then
      read -r user cmd <<<"$rest"
      [[ -n $user && -n $cmd ]] || { err "system crontab needs a user name before the command"; continue; }
    fi
    [[ -n $cmd ]] || { err "empty command"; continue; }
    # A % that is not preceded by a backslash is a newline to cron.
    if sed -E 's/\\%//g' <<<"$cmd" | grep -q '%'; then err "unescaped % in command (write \\%)"; fi
  done < "$file"
  return "$bad"
}

self_test() {
  local w out rc; w=$(mktemp -d); trap 'rm -rf "$w"' RETURN
  cat > "$w/good" <<'EOF'
# comment
MAILTO=ops@example.com
PATH=/usr/local/bin:/usr/bin:/bin
*/15 * * * * /usr/local/bin/check.sh
30 2 * * mon-fri /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1
0 3 1 jan,jul * /usr/local/bin/semiannual.sh
0 4 * * 1,3,5 date +\%F
@reboot /usr/local/bin/on-boot.sh
EOF
  out=$(cronlint "$w/good"); rc=$?
  [[ $rc -eq 0 && -z $out ]] || { echo "FAIL good: rc=$rc out=$out" >&2; return 1; }

  cat > "$w/bad" <<'EOF'
60 * * * * too-late-minute
* 24 * * * hour-24
* * 0 * * day-zero
* * * 13 * month-13
* * * * 8 dow-8
5-1 * * * * backwards
* * * * *
*/0 * * * * zero-step
0 4 * * * date +%F
EOF
  out=$(cronlint "$w/bad"); rc=$?
  [[ $rc -eq 1 ]] || { echo "FAIL bad: rc=$rc" >&2; return 1; }
  for needle in "bad minute '60'" "bad hour '24'" "bad day of month '0'" "bad month '13'" \
                "bad day of week '8'" "bad minute '5-1'" "expected 5 time fields" "bad minute '*/0'" "unescaped %"; do
    grep -qF "$needle" <<<"$out" || { echo "FAIL: missing report for: $needle" >&2; echo "$out" >&2; return 1; }
  done

  printf '0 2 * * * root /usr/local/bin/x.sh\n' > "$w/sys_ok"
  printf '0 2 * * * /usr/local/bin/x.sh\n' > "$w/sys_bad"
  cronlint --system "$w/sys_ok" >/dev/null || { echo "FAIL: system ok" >&2; return 1; }
  # Without a user field the first word of the command is taken as the user, leaving no command.
  cronlint --system "$w/sys_bad" >/dev/null && { echo "FAIL: system missing user accepted" >&2; return 1; }
  cronlint "$w/nope" 2>/dev/null; rc=$?
  [[ $rc -eq 2 ]] || { echo "FAIL usage rc=$rc" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else cronlint "$@"; fi
