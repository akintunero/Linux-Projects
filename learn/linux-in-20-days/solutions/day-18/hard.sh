#!/usr/bin/env bash
# Day 18 - Hard: imgaudit.sh IMAGE - report three things worth checking before you run an image:
#   user:   WARN if the image runs as root (empty, root or 0)
#   tag:    WARN if the reference is untagged or :latest (not reproducible)
#   ports:  list of exposed ports (information)
# Exit: 0 no warnings, 1 warnings, 2 usage or image not found.
# Usage: hard.sh IMAGE | hard.sh --self-test      (CTR=docker works too; the inspect template is identical)
# NEEDS-TOOL: podman (or CTR=...) - exits 77 if missing. Read-only for IMAGE; the self-test builds
# and removes two tiny images on BASE_IMAGE.
set -uo pipefail
CTR=${CTR:-podman}
BASE_IMAGE=${BASE_IMAGE:-docker.io/library/alpine:3.20}

imgaudit() {
  local image=${1:-} warn=0 user ports last
  [[ -n $image ]] || { echo "usage: imgaudit IMAGE" >&2; return 2; }
  user=$("$CTR" image inspect --format '{{.Config.User}}' "$image" 2>/dev/null) || { echo "image not found: $image" >&2; return 2; }
  ports=$("$CTR" image inspect --format '{{.Config.ExposedPorts}}' "$image" 2>/dev/null)

  case ${user%%:*} in
    ''|root|0) echo "WARN: runs as root (set USER in the Containerfile)"; warn=1 ;;
    *)         echo "ok:   runs as '$user'" ;;
  esac

  last=${image##*/}
  if [[ $last != *:* || $last == *:latest ]]; then echo "WARN: image reference '$image' is not pinned to a version tag"; warn=1
  else echo "ok:   pinned tag '${last#*:}'"; fi

  echo "info: exposed ports: ${ports:-none}"
  return "$warn"
}

self_test() {
  command -v "$CTR" >/dev/null || { echo "$CTR not installed" >&2; exit 77; }
  local w rc out; w=$(mktemp -d)
  local good=localhost/linux20-d18-good:1 bad=localhost/linux20-d18-bad
  trap '"$CTR" rmi -f "$good" "$bad" >/dev/null 2>&1; rm -rf "$w"' RETURN
  printf 'FROM %s\nRUN echo "app:x:10001:10001::/home/app:/bin/sh" >> /etc/passwd\nUSER 10001\nEXPOSE 8000\n' "$BASE_IMAGE" > "$w/good"
  printf 'FROM %s\n' "$BASE_IMAGE" > "$w/bad"
  "$CTR" build -q -t "$good" -f "$w/good" "$w" >/dev/null || { echo "build failed" >&2; return 1; }
  "$CTR" build -q -t "$bad"  -f "$w/bad"  "$w" >/dev/null || { echo "build failed" >&2; return 1; }

  out=$(imgaudit "$good"); rc=$?
  [[ $rc -eq 0 && $out == *"runs as '10001'"* && $out == *"8000"* ]] || { echo "FAIL good: rc=$rc out=$out" >&2; return 1; }
  out=$(imgaudit "$bad"); rc=$?
  [[ $rc -eq 1 && $out == *"runs as root"* && $out == *"not pinned"* ]] || { echo "FAIL bad: rc=$rc out=$out" >&2; return 1; }
  imgaudit localhost/does-not-exist:1 >/dev/null 2>&1; rc=$?
  [[ $rc -eq 2 ]] || { echo "FAIL missing image rc=$rc" >&2; return 1; }
  echo PASS >&2
}

if [[ ${1:-} == --self-test ]]; then self_test; else imgaudit "$@"; fi
