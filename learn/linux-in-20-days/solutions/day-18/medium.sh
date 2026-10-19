#!/usr/bin/env bash
# Day 18 - Medium: build a small image from a Containerfile that runs as a NON-root user, run it,
# and remove the image afterwards.
# CTR=docker and BASE_IMAGE=<local image> let you try it with Docker (the build file syntax is the same).
# NEEDS-TOOL: podman (or CTR=...) - exits 77 if missing. Builds on BASE_IMAGE (pulled if absent).
set -euo pipefail
CTR=${CTR:-podman}
BASE_IMAGE=${BASE_IMAGE:-docker.io/library/alpine:3.20}
command -v "$CTR" >/dev/null || { echo "$CTR not installed" >&2; exit 77; }
work=$(mktemp -d)
tag=localhost/linux20-d18-medium:1
cleanup() { "$CTR" rmi -f "$tag" >/dev/null 2>&1 || true; rm -rf "$work"; }
trap cleanup EXIT
cd "$work"

echo "served by a container" > hello.txt
cat > Containerfile <<EOF
FROM $BASE_IMAGE
# Create an unprivileged user without distro-specific tools by appending a passwd entry.
RUN echo "app:x:10001:10001::/home/app:/bin/sh" >> /etc/passwd
COPY hello.txt /srv/hello.txt
USER 10001
CMD ["cat", "/srv/hello.txt"]
EOF

"$CTR" build -q -t "$tag" -f Containerfile . >/dev/null
msg=$("$CTR" run --rm "$tag")
uid=$("$CTR" run --rm "$tag" id -u)
echo "message: $msg"
echo "uid inside: $uid"

[[ $msg == "served by a container" ]] || { echo "FAIL: message" >&2; exit 1; }
[[ $uid == 10001 ]]                  || { echo "FAIL: container runs as uid $uid, expected 10001" >&2; exit 1; }
echo PASS >&2
