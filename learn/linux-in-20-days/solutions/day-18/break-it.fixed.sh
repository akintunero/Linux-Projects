#!/usr/bin/env bash
# Day 18 - Break it, fixed. Prints the command; starts nothing. Bugs were:
#   1. `-p 8080:80` publishes on ALL interfaces (0.0.0.0): anyone on the network can reach it.
#      Bind to loopback: `-p 127.0.0.1:8080:80`.
#   2. `:latest` changes under you. Pin a version tag (a digest is even better).
#   3. `--privileged` switches off almost all container isolation and a web server does not need it.
#      Also: the volume should be read-only (`:ro`), and on SELinux systems (Fedora, RHEL, Rocky)
#      bind mounts need a label option (`z` or `Z`), written together as `:ro,Z`. `--rm` removes the
#      container on exit so stopped containers do not pile up.
set -euo pipefail

build_command() {
  local image=docker.io/library/nginx:1.27-alpine
  printf '%s ' podman run -d --rm --name linux20-web -p 127.0.0.1:8080:80 \
    -v "$PWD/data:/usr/share/nginx/html:ro,Z" "$image"
  echo
}

if [[ ${1:-} == --self-test ]]; then
  cmd=$(build_command)
  grep -q -- '-p 127.0.0.1:8080:80' <<<"$cmd" || { echo "FAIL: not bound to loopback" >&2; exit 1; }
  ! grep -q ':latest' <<<"$cmd"               || { echo "FAIL: unpinned image" >&2; exit 1; }
  ! grep -q -- '--privileged' <<<"$cmd"       || { echo "FAIL: privileged" >&2; exit 1; }
  grep -q ':ro,Z' <<<"$cmd"                   || { echo "FAIL: volume not read-only/labelled" >&2; exit 1; }
  grep -q -- '--rm' <<<"$cmd"                 || { echo "FAIL: no --rm" >&2; exit 1; }
  echo PASS >&2
else
  build_command
fi
