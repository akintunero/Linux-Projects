#!/usr/bin/env bash
# Day 18 - Easy: run a throwaway container that prints a line and is removed afterwards.
# Uses Podman by default. CTR=docker and BASE_IMAGE=<local image> let you try it with Docker; the
# commands used here are identical in both. No root needed with rootless Podman.
# NEEDS-TOOL: podman (or CTR=...) - exits 77 if missing. Pulls BASE_IMAGE if it is not present locally.
set -euo pipefail
CTR=${CTR:-podman}
BASE_IMAGE=${BASE_IMAGE:-docker.io/library/alpine:3.20}     # fully qualified: no short-name prompt
command -v "$CTR" >/dev/null || { echo "$CTR not installed" >&2; exit 77; }

out=$("$CTR" run --rm "$BASE_IMAGE" echo "hello from a container")   # --rm: delete the container on exit
echo "$out"

[[ $out == "hello from a container" ]] || { echo "FAIL: unexpected output" >&2; exit 1; }
# --rm worked if no container with that image was left behind
leftover=$("$CTR" ps -a --filter "ancestor=$BASE_IMAGE" --filter status=exited --format '{{.ID}}' | wc -l)
[[ $leftover -eq 0 ]] || { echo "FAIL: exited container left behind" >&2; exit 1; }
echo PASS >&2
