#!/usr/bin/env bash
# Day 19 - Hard: triage.sh [--section NAME] - a read-only snapshot to run FIRST when "something is wrong".
# Sections: load memory disk units errors ports top.  Missing tools print "n/a" instead of failing.
# Usage: hard.sh | hard.sh --section disk | hard.sh --self-test
# Exit: 0 ok, 2 unknown section. It writes nothing and changes nothing.
set -uo pipefail

sec_load()   { echo "cpus: $(nproc)"; echo "load (1/5/15 min): $(cut -d' ' -f1-3 /proc/loadavg)"; }
sec_memory() { free -m | awk 'NR == 1 || /^Mem:|^Swap:/'; }
sec_disk()   {
  df -hP -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null | awk 'NR == 1 || $5+0 >= 0' | head -n 8
  echo "inodes:"; df -iP / | awk 'NR == 2 {print "  / uses " $5 " of inodes"}'
}
sec_units()  {
  if command -v systemctl >/dev/null && systemctl is-system-running >/dev/null 2>&1 || command -v systemctl >/dev/null; then
    local n; n=$(systemctl --failed --no-legend --no-pager 2>/dev/null | wc -l)
    echo "failed units: $n"; systemctl --failed --no-legend --no-pager 2>/dev/null | head -n 5
  else echo "n/a (no systemd)"; fi
}
sec_errors() {
  if command -v journalctl >/dev/null; then
    journalctl -b -p err -n 5 --no-pager -q 2>/dev/null | cut -c1-120 | sed 's/^/  /'
    [[ ${PIPESTATUS[0]} -eq 0 ]] || echo "  n/a (cannot read the journal; are you in the systemd-journal or adm group?)"
  else echo "n/a (no journalctl)"; fi
}
sec_ports()  { if command -v ss >/dev/null; then ss -ltn 2>/dev/null | awk 'NR == 1 || NR <= 11'; else echo "n/a (no ss)"; fi; }
sec_top()    { ps -eo pid,pcpu,pmem,comm --sort=-pcpu | head -n 4; }

triage() {
  local only=
  if [[ ${1:-} == --section ]]; then only=${2:-}; fi
  local all=(load memory disk units errors ports top) s found=0
  for s in "${all[@]}"; do
    [[ -z $only || $only == "$s" ]] || continue
    found=1
    echo "== $s =="
    "sec_$s"
  done
  ((found)) || { echo "unknown section: $only (choose from: ${all[*]})" >&2; return 2; }
}

self_test() {
  local w out rc start end; w=$(mktemp -d); trap 'rm -rf "$w"' RETURN
  start=$SECONDS
  out=$(cd "$w" && triage); rc=$?
  end=$SECONDS
  [[ $rc -eq 0 ]] || { echo "FAIL: rc=$rc" >&2; return 1; }
  for s in load memory disk units errors ports top; do
    grep -qx "== $s ==" <<<"$out" || { echo "FAIL: section $s missing" >&2; return 1; }
  done
  ((end - start <= 10)) || { echo "FAIL: too slow ($((end - start)) s)" >&2; return 1; }
  [[ $(triage --section load | wc -l) -eq 3 ]] || { echo "FAIL: --section load should print 3 lines" >&2; return 1; }
  triage --section nonsense >/dev/null 2>&1; rc=$?
  [[ $rc -eq 2 ]] || { echo "FAIL: unknown section rc=$rc" >&2; return 1; }
  [[ -z $(ls -A "$w") ]] || { echo "FAIL: wrote files" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else triage "$@"; fi
