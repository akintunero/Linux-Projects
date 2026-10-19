#!/usr/bin/env bash
#
# docker-manager.sh - everyday container operations with a dry-run mode.
#
# Usage: docker-manager.sh [OPTIONS] COMMAND [ARGS]

set -euo pipefail

# shellcheck source=../../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

readonly VERSION="2.0.0"
BACKUP_DIR="${DOCKER_MANAGER_BACKUP_DIR:-./docker-backups}"
# shellcheck disable=SC2034  # read by log() in lib/common.sh
LOG_FILE="${DOCKER_MANAGER_LOG:-}"

DRY_RUN=false
FORCE=false
VERBOSE=false

usage() {
    cat <<EOF
Docker manager $VERSION

Usage: ${0##*/} [OPTIONS] COMMAND [ARGS]

Commands:
  list [FILTER]            List all containers (FILTER e.g. status=exited)
  start NAME...            Start containers
  stop NAME...             Stop containers
  restart NAME...          Restart containers
  remove NAME...           Remove containers (add --force to remove running ones)
  logs NAME [LINES]        Show the last LINES (default 50) log lines
  backup NAME [FILE]       Export a container's filesystem to a tar file
  cleanup                  Remove stopped containers, unused networks, dangling images
  status NAME...           Show state, health and uptime

Options:
  -n, --dry-run            Print the docker commands instead of running them
  -f, --force              Needed to remove running containers
  -v, --verbose            Print each docker command before running it
  -h, --help               Show this help

Environment:
  DOCKER_MANAGER_BACKUP_DIR   Where 'backup' writes (default: ./docker-backups)
  DOCKER_MANAGER_LOG          Optional log file

Examples:
  ${0##*/} list status=exited
  ${0##*/} --dry-run remove old-api old-worker
  ${0##*/} logs web 200
EOF
}

# docker_cmd ARGS... - run docker, honouring --dry-run and --verbose
docker_cmd() {
    # Like `set -x`, the trace goes to stderr so stdout stays machine-readable.
    if [[ "$DRY_RUN" == true ]]; then
        printf '+ docker %s\n' "$*" >&2
        return 0
    fi
    if [[ "$VERBOSE" == true ]]; then
        printf '+ docker %s\n' "$*" >&2
    fi
    docker "$@"
}

check_docker() {
    [[ "$DRY_RUN" == true ]] && return 0
    require_cmd docker
    docker info >/dev/null 2>&1 ||
        die "Cannot talk to the Docker daemon (is it running? are you in the 'docker' group?)" 3
}

need_names() {
    (($# > 0)) || die "At least one container name is required" 2
    local name
    for name in "$@"; do
        # Docker's own rule for container names and IDs.
        [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]] || die "Invalid container name '$name'" 2
    done
}

# for_each ACTION PAST_TENSE NAME... - run `docker ACTION NAME` for each name
for_each() {
    local action="$1" past="$2" name failed=()
    shift 2
    local extra=()
    if [[ "$action" == rm && "$FORCE" == true ]]; then extra=(-f); fi
    for name in "$@"; do
        if docker_cmd "$action" "${extra[@]+"${extra[@]}"}" "$name" >/dev/null; then
            if [[ "$DRY_RUN" == false ]]; then ok "$past: $name"; fi
            log INFO "$past $name"
        else
            err "Failed to $action: $name"
            log ERROR "failed $action $name"
            failed+=("$name")
        fi
    done
    if ((${#failed[@]} > 0)); then
        err "${#failed[@]} failed: ${failed[*]}"
        return 1
    fi
}

cmd_list() {
    local filter="${1:-}"
    local fmt='table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}'
    if [[ -n "$filter" ]]; then
        docker_cmd ps -a --filter "$filter" --format "$fmt"
    else
        docker_cmd ps -a --format "$fmt"
    fi
}

cmd_logs() {
    local name="${1:-}" lines="${2:-50}"
    need_names "$name"
    is_positive_int "$lines" || die "LINES must be a positive integer" 2
    docker_cmd logs --tail "$lines" "$name"
}

cmd_status() {
    need_names "$@"
    local name
    for name in "$@"; do
        docker_cmd inspect --format \
            '{{.Name}}: {{.State.Status}} (started {{.State.StartedAt}}) health={{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}' \
            "$name"
    done
}

cmd_backup() {
    local name="${1:-}" file="${2:-}"
    need_names "$name"
    [[ -n "$file" ]] || file="$BACKUP_DIR/${name}_$(date +%Y%m%d_%H%M%S).tar"
    if [[ "$DRY_RUN" == true ]]; then
        printf '+ docker export %s > %s\n' "$name" "$file" >&2
        return 0
    fi
    mkdir -p "$(dirname "$file")"
    if docker export "$name" >"$file"; then
        ok "Exported $name to $file"
    else
        rm -f -- "$file"
        die "Export of '$name' failed"
    fi
}

cmd_cleanup() {
    warn "This removes stopped containers, unused networks and dangling images."
    docker_cmd system prune -f
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
            -v | --verbose)
                VERBOSE=true
                shift
                ;;
            -h | --help)
                usage
                exit 0
                ;;
            -*)
                err "Unknown option $1"
                usage >&2
                exit 1
                ;;
            *) break ;;
        esac
    done

    if (($# == 0)); then
        err "A command is required"
        usage >&2
        exit 1
    fi

    local command="$1"
    shift
    case "$command" in
        list | start | stop | restart | remove | logs | backup | cleanup | status) ;;
        *) die "Unknown command '$command' (try --help)" 1 ;;
    esac

    check_docker
    case "$command" in
        list) cmd_list "$@" ;;
        start)
            need_names "$@"
            for_each start "Started" "$@"
            ;;
        stop)
            need_names "$@"
            for_each stop "Stopped" "$@"
            ;;
        restart)
            need_names "$@"
            for_each restart "Restarted" "$@"
            ;;
        remove)
            need_names "$@"
            for_each rm "Removed" "$@"
            ;;
        logs) cmd_logs "$@" ;;
        backup) cmd_backup "$@" ;;
        cleanup) cmd_cleanup ;;
        status) cmd_status "$@" ;;
    esac
}

main "$@"
