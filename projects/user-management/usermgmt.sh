#!/usr/bin/env bash
#
# usermgmt.sh - manage Linux users and groups from one validated CLI.
#
# Replaces the twelve single-purpose scripts that used to live in this folder.
# Run with --dry-run first to see exactly which commands would be executed.

set -euo pipefail

# shellcheck source=../../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

DRY_RUN=false
PASSWORD_STDIN=false
FORCE=false

usage() {
    cat <<EOF
Usage: ${0##*/} [--dry-run] [--force] COMMAND [ARGS]

User commands:
  create-user NAME [--shell SHELL] [--no-home] [--password-stdin]
  delete-user NAME [--keep-home]
  set-password NAME [--password-stdin]
  lock-user NAME
  unlock-user NAME
  set-expiry NAME YYYY-MM-DD        ("never" removes the expiry)
  set-home NAME /new/home [--move]
  list-users                        (accounts with UID >= 1000)

Group commands:
  create-group NAME
  delete-group NAME
  add-to-group USER GROUP
  list-groups USER

Options:
  -n, --dry-run       Print the commands instead of running them (no root needed)
  -f, --force         Allow changes to system accounts (UID < 1000)
  -h, --help          Show this help

Passwords are never accepted as command-line arguments (they would show up in
'ps' and shell history). Use the interactive prompt or --password-stdin:

  printf '%s\n' "\$PASSWORD" | sudo ${0##*/} create-user alice --password-stdin

Most commands need root. Test them in a VM or container, not on a live server.
EOF
}

# run CMD ARGS... - execute, or just print when --dry-run is set
run() {
    if [[ "$DRY_RUN" == true ]]; then
        printf '+ %s\n' "$*"
    else
        "$@"
    fi
}

check_privileges() {
    [[ "$DRY_RUN" == true ]] || require_root
}

user_exists() { id -u "$1" >/dev/null 2>&1; }
group_exists() { getent group "$1" >/dev/null 2>&1; }

# need_username NAME - validate syntax, refuse root
need_username() {
    valid_username "${1:-}" || die "Invalid username '${1:-}' (lowercase letters, digits, - and _; max 32)" 2
    [[ "$1" != "root" ]] || die "Refusing to operate on root" 2
}

# need_existing_user NAME - the account must exist (skipped in dry-run)
need_existing_user() {
    need_username "${1:-}"
    [[ "$DRY_RUN" == true ]] && return 0
    user_exists "$1" || die "User '$1' does not exist"
    if [[ "$FORCE" != true && "$(id -u "$1")" -lt 1000 ]]; then
        die "'$1' is a system account (UID < 1000); use --force to override" 3
    fi
}

need_group() {
    valid_username "${1:-}" || die "Invalid group name '${1:-}'" 2
}

# read_password - one line from stdin, or an interactive hidden prompt
read_password() {
    local pw
    if [[ "$PASSWORD_STDIN" == true ]]; then
        IFS= read -r pw || die "No password supplied on stdin" 2
    else
        [[ -t 0 ]] || die "No terminal to prompt on; use --password-stdin" 2
        IFS= read -r -s -p "Password: " pw
        printf '\n' >&2
    fi
    [[ -n "$pw" ]] || die "Password must not be empty" 2
    printf '%s' "$pw"
}

# apply_password NAME - set a password without it appearing in a process list
apply_password() {
    local name="$1"
    if [[ "$DRY_RUN" == true ]]; then
        printf '+ chpasswd   # "%s:<password read from %s>"\n' "$name" \
            "$([[ "$PASSWORD_STDIN" == true ]] && echo stdin || echo prompt)"
        return 0
    fi
    local pw
    pw=$(read_password)
    printf '%s:%s\n' "$name" "$pw" | chpasswd
}

cmd_create_user() {
    local name="${1:-}" shell="/bin/bash" create_home=(-m)
    need_username "$name"
    shift || true
    while (($# > 0)); do
        case "$1" in
            --shell)
                shell="${2:?--shell needs a value}"
                shift 2
                ;;
            --no-home)
                create_home=(-M)
                shift
                ;;
            --password-stdin)
                PASSWORD_STDIN=true
                shift
                ;;
            *) die "Unknown option '$1' for create-user" 2 ;;
        esac
    done
    [[ "$shell" == /* ]] || die "Shell must be an absolute path" 2
    [[ "$DRY_RUN" == true ]] || ! user_exists "$name" || die "User '$name' already exists"
    check_privileges
    run useradd "${create_home[@]}" -s "$shell" -- "$name"
    if [[ "$PASSWORD_STDIN" == true || -t 0 ]]; then
        apply_password "$name"
    else
        warn "No password set for '$name' (account has no usable password)"
    fi
    ok "User '$name' created"
}

cmd_delete_user() {
    local name="${1:-}" remove_home=(-r)
    need_existing_user "$name"
    shift || true
    [[ "${1:-}" == "--keep-home" ]] && remove_home=()
    check_privileges
    warn "Deleting '$name'${remove_home[*]:+ and their home directory}"
    run userdel "${remove_home[@]}" -- "$name"
    ok "User '$name' deleted"
}

cmd_set_password() {
    local name="${1:-}"
    need_existing_user "$name"
    shift || true
    [[ "${1:-}" == "--password-stdin" ]] && PASSWORD_STDIN=true
    check_privileges
    apply_password "$name"
    ok "Password changed for '$name'"
}

cmd_lock_user() {
    need_existing_user "${1:-}"
    check_privileges
    run usermod -L -- "$1"
    ok "Account '$1' locked (undo: unlock-user $1)"
}

cmd_unlock_user() {
    need_existing_user "${1:-}"
    check_privileges
    run usermod -U -- "$1"
    ok "Account '$1' unlocked"
}

cmd_set_expiry() {
    local name="${1:-}" date_str="${2:-}"
    need_existing_user "$name"
    if [[ "$date_str" == "never" ]]; then
        date_str=""
    else
        [[ "$date_str" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || die "Expiry must be YYYY-MM-DD or 'never'" 2
        if date -d "$date_str" >/dev/null 2>&1 || date -j -f '%Y-%m-%d' "$date_str" >/dev/null 2>&1; then
            :
        else
            die "'$date_str' is not a valid date" 2
        fi
    fi
    check_privileges
    run usermod -e "$date_str" -- "$name"
    ok "Expiry for '$name' set to ${date_str:-never}"
}

cmd_set_home() {
    local name="${1:-}" new_home="${2:-}" move=()
    need_existing_user "$name"
    [[ "$new_home" == /* ]] || die "New home must be an absolute path" 2
    [[ "${3:-}" == "--move" ]] && move=(-m)
    check_privileges
    run usermod "${move[@]}" -d "$new_home" -- "$name"
    ok "Home directory for '$name' set to $new_home"
}

cmd_list_users() {
    msg "Regular users (UID >= 1000):"
    getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 { printf "%-20s uid=%s home=%s shell=%s\n", $1, $3, $6, $7 }' | sort
}

cmd_create_group() {
    need_group "${1:-}"
    [[ "$DRY_RUN" == true ]] || ! group_exists "$1" || die "Group '$1' already exists"
    check_privileges
    run groupadd -- "$1"
    ok "Group '$1' created"
}

cmd_delete_group() {
    need_group "${1:-}"
    [[ "$DRY_RUN" == true ]] || group_exists "$1" || die "Group '$1' does not exist"
    check_privileges
    run groupdel -- "$1"
    ok "Group '$1' deleted"
}

cmd_add_to_group() {
    local name="${1:-}" group="${2:-}"
    need_existing_user "$name"
    need_group "$group"
    [[ "$DRY_RUN" == true ]] || group_exists "$group" || die "Group '$group' does not exist"
    check_privileges
    # -a (append) is essential: without it usermod REPLACES all supplementary groups.
    run usermod -a -G "$group" -- "$name"
    ok "User '$name' added to group '$group'"
}

cmd_list_groups() {
    need_username "${1:-}"
    [[ "$DRY_RUN" == true ]] || user_exists "$1" || die "User '$1' does not exist"
    msg "Groups for user '$1':"
    id -nG -- "$1" | tr ' ' '\n' | sort
}

main() {
    while (($# > 0)); do
        case "$1" in
            -n | --dry-run)
                DRY_RUN=true
                shift
                ;;
            -f | --force)
                FORCE=true
                shift
                ;;
            -h | --help)
                usage
                exit 0
                ;;
            *) break ;;
        esac
    done

    if (($# == 0)); then
        usage >&2
        exit 1
    fi

    local command="$1"
    shift
    case "$command" in
        create-user) cmd_create_user "$@" ;;
        delete-user) cmd_delete_user "$@" ;;
        set-password) cmd_set_password "$@" ;;
        lock-user) cmd_lock_user "$@" ;;
        unlock-user) cmd_unlock_user "$@" ;;
        set-expiry) cmd_set_expiry "$@" ;;
        set-home) cmd_set_home "$@" ;;
        list-users) cmd_list_users ;;
        create-group) cmd_create_group "$@" ;;
        delete-group) cmd_delete_group "$@" ;;
        add-to-group) cmd_add_to_group "$@" ;;
        list-groups) cmd_list_groups "$@" ;;
        *) die "Unknown command '$command' (try --help)" 1 ;;
    esac
}

main "$@"
