#!/usr/bin/env bash
# Day 01 - Break it, fixed. Bugs were:
#   1. `source /etc/os-releas` - typo, and it ignored $OS_RELEASE.
#   2. `[ $ID_LIKE = ... ]` - unquoted and unset on Debian/Fedora -> "unary operator expected".
#   3. Logic: Debian itself has no ID_LIKE=debian, and "else" assumed dnf for everything.
# Safe: read-only. Self-test: break-it.fixed.sh --self-test
set -euo pipefail

detect() {
  local ID="" ID_LIKE=""
  # shellcheck disable=SC1090
  . "${OS_RELEASE:-/etc/os-release}"
  case " ${ID} ${ID_LIKE} " in
    *" debian "*|*" ubuntu "*)            echo apt ;;
    *" rhel "*|*" fedora "*)              echo dnf ;;
    *) echo "unknown" >&2; return 1 ;;
  esac
}

if [[ ${1:-} == --self-test ]]; then
  d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
  printf 'ID=debian\n' > "$d/deb"; printf 'ID=fedora\n' > "$d/fed"
  [[ $(OS_RELEASE=$d/deb detect) == apt ]] && [[ $(OS_RELEASE=$d/fed detect) == dnf ]] \
    && echo PASS >&2
else
  detect
fi
