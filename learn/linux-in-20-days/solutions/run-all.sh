#!/usr/bin/env bash
# Run every reference solution that is safe without root and report PASS/FAIL.
# Usage: bash run-all.sh [day-NN ...]     (default: all days)
#
# Conventions:
#   * A script whose header contains NEEDS-ROOT is skipped (read it, run it in a VM).
#   * A script that needs an optional tool exits 77 when the tool is missing -> reported as SKIP.
#   * break-it.sh and files named setup*/lab-* are teaching material, not tests.
#   * Scripts with a --self-test mode are run in that mode.
set -uo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
days=("$@")
((${#days[@]})) || mapfile -t days < <(cd "$here" && ls -d day-*/ | tr -d /)

errfile=$(mktemp); trap 'rm -f "$errfile"' EXIT
pass=0 fail=0 skip=0
for day in "${days[@]}"; do
  for script in "$here/$day"/*.sh; do
    name=$day/$(basename "$script")
    case $name in
      */break-it.sh|*/setup*.sh|*/lab-*.sh) continue ;;
    esac
    if grep -q 'NEEDS-ROOT' "$script"; then
      printf 'SKIP  %s (needs root)\n' "$name"; skip=$((skip + 1)); continue
    fi
    args=()
    grep -q -- '--self-test' "$script" && args=(--self-test)
    timeout 120 bash "$script" "${args[@]}" >/dev/null 2>"$errfile"
    rc=$?
    case $rc in
      0)  printf 'PASS  %s\n' "$name"; pass=$((pass + 1)) ;;
      77) printf 'SKIP  %s (tool missing)\n' "$name"; skip=$((skip + 1)) ;;
      *)  printf 'FAIL  %s (exit %d)\n' "$name" "$rc"; sed 's/^/        /' "$errfile"; fail=$((fail + 1)) ;;
    esac
  done
done
printf '\n%d passed, %d failed, %d skipped\n' "$pass" "$fail" "$skip"
((fail == 0))
