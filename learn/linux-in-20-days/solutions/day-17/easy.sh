#!/usr/bin/env bash
# Day 17 - Easy: generate an Ed25519 key pair in a temporary directory and inspect it.
# The key has NO passphrase because it is a throwaway demo. For real keys use a passphrase
# (omit -N '') and ssh-agent. Nothing is written to ~/.ssh.
# NEEDS-TOOL: ssh-keygen (exits 77 if missing).
set -euo pipefail
command -v ssh-keygen >/dev/null || { echo "ssh-keygen missing" >&2; exit 77; }
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT; cd "$work"

ssh-keygen -q -t ed25519 -N '' -C 'linux20-demo' -f demo_key
stat -c '%a %n' demo_key demo_key.pub
ssh-keygen -lf demo_key.pub                 # fingerprint line: bits, hash, comment, type

# Acceptance checks
[[ $(stat -c %a demo_key) == 600 ]]                           || { echo "FAIL: private key must be 600" >&2; exit 1; }
[[ $(cut -d' ' -f1 demo_key.pub) == ssh-ed25519 ]]            || { echo "FAIL: wrong key type" >&2; exit 1; }
[[ $(ssh-keygen -y -f demo_key | cut -d' ' -f1-2) == "$(cut -d' ' -f1-2 demo_key.pub)" ]] \
                                                              || { echo "FAIL: public key does not match private key" >&2; exit 1; }
ssh-keygen -lf demo_key.pub | grep -q 'SHA256:' || { echo "FAIL: fingerprint" >&2; exit 1; }
echo PASS >&2
