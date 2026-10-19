#!/usr/bin/env bash
# Day 01 - Hard: sysinfo.sh - kernel, distro id, and the package manager to use.
# Usage: hard.sh            (reads /etc/os-release)
#        OS_RELEASE=file hard.sh   (read a different file, used for testing)
# Safe: read-only. Run the self-test with: hard.sh --self-test
set -euo pipefail

sysinfo() {
  local file=${OS_RELEASE:-/etc/os-release}
  [[ -r $file ]] || { echo "cannot read $file" >&2; return 2; }

  local ID="" ID_LIKE=""
  # shellcheck disable=SC1090
  . "$file"

  local family=" ${ID} ${ID_LIKE} " pm
  case $family in
    *" debian "*|*" ubuntu "*)                   pm=apt ;;
    *" rhel "*|*" fedora "*|*" centos "*)        pm=dnf ;;
    *) echo "unknown distribution family: '${ID}'" >&2; return 1 ;;
  esac
  printf 'kernel=%s\ndistro=%s\npackage_manager=%s\n' "$(uname -r)" "$ID" "$pm"
}

self_test() {
  local dir; dir=$(mktemp -d); trap 'rm -rf "$dir"' RETURN
  printf 'ID=debian\n'                       > "$dir/debian"
  printf 'ID=ubuntu\nID_LIKE=debian\n'       > "$dir/ubuntu"
  printf 'ID=fedora\n'                       > "$dir/fedora"
  printf 'ID=rocky\nID_LIKE="rhel centos fedora"\n' > "$dir/rocky"
  printf 'ID=arch\n'                         > "$dir/arch"

  local f want got
  for pair in debian:apt ubuntu:apt fedora:dnf rocky:dnf; do
    f=${pair%%:*}; want=${pair##*:}
    got=$(OS_RELEASE="$dir/$f" sysinfo | sed -n 's/^package_manager=//p')
    [[ $got == "$want" ]] || { echo "FAIL: $f gave '$got', want $want" >&2; return 1; }
  done
  if OS_RELEASE="$dir/arch" sysinfo >/dev/null 2>&1; then
    echo "FAIL: arch should be rejected" >&2; return 1
  fi
  echo "PASS" >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else sysinfo; fi
