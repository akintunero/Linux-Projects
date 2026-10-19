#!/usr/bin/env bash
# Day 18 - Break it (BUGGY on purpose). This script only PRINTS the command it would run; it does not
# start a container, so it is safe anywhere. Fix the three problems in the command.
# Goal: run a web image for local development: reachable only from this machine on port 8080,
# using a version-pinned image, as an unprivileged container that is removed when it stops,
# with the project's ./data directory mounted read-only.
image=docker.io/library/nginx:latest
echo podman run -d --privileged -p 8080:80 -v "$PWD/data:/usr/share/nginx/html" "$image"
