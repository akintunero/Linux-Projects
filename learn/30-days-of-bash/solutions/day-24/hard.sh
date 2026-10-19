#!/usr/bin/env bash
# Day 24 hard: a menu-driven backup helper that also works unattended.
#   interactive:      choices come from a select menu
#   non-interactive:  ACTION=create|list|quit  (no questions asked)
# Everything happens in a temporary directory; the "typing" comes from here-strings.
set -euo pipefail

work="$(mktemp -d)"
mkdir -p "${work}/data" "${work}/backups"
echo "important" > "${work}/data/file.txt"
trap 'rm -rf -- "$work"' EXIT

do_create() {
    local name="backup-$1.tar.gz"
    tar -czf "${work}/backups/${name}" -C "$work" data
    echo "created ${name}"
}
do_list() {
    echo "backups:"
    local f
    for f in "${work}"/backups/*.tar.gz; do
        [[ -e $f ]] && echo "  ${f##*/}"
    done
    return 0
}

menu() {
    local counter=0
    PS3="Action: "
    select choice in "create backup" "list backups" "quit"; do
        case "$choice" in
            "create backup") counter=$(( counter + 1 )); do_create "$counter" ;;
            "list backups")  do_list ;;
            "quit")          echo "bye"; return 0 ;;
            *)               echo "invalid choice '${REPLY}'" ;;
        esac
    done
}

main() {
    if [[ -n ${ACTION:-} ]]; then                 # unattended mode
        case "$ACTION" in
            create) do_create "auto" ;;
            list)   do_list ;;
            *)      echo "unknown ACTION '${ACTION}'" >&2; return 2 ;;
        esac
    else
        menu
    fi
}

echo "=== interactive session (typed: 9, 1, 1, 2, 3) ==="
main <<< $'9\n1\n1\n2\n3' 2>&1
echo "=== unattended: ACTION=create then ACTION=list ==="
ACTION=create main
ACTION=list main
status=0
ACTION=bogus main 2>/dev/null || status=$?
echo "unknown action -> exit ${status}"
