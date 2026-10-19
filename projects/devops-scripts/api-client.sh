#!/usr/bin/env bash
#
# api-client.sh - a small REST client around curl and jq, with response caching.
#
# Usage: api-client.sh [OPTIONS] URL

set -euo pipefail

# shellcheck source=../../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

readonly VERSION="2.0.0"
readonly CONFIG_FILE="${API_CLIENT_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/linux-projects/api-client.conf}"
readonly CACHE_DIR="${API_CLIENT_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/linux-projects/api-client}"

# Settings (overridable from the config file, the environment or options)
API_KEY="${API_KEY:-}"
TIMEOUT=30
CACHE_TTL=300
USE_CACHE=false
OUTPUT_FORMAT="pretty"
VERBOSE=false
METHOD="GET"
HEADERS=()
DATA=""
URL=""

usage() {
    cat <<EOF
Generic REST API client $VERSION

Usage: ${0##*/} [OPTIONS] URL

Options:
  -m, --method METHOD    GET (default), POST, PUT, PATCH, DELETE
  -H, --header HEADER    Extra header, e.g. 'Accept: application/json' (repeatable)
  -d, --data JSON        Request body (must be valid JSON; implies Content-Type)
  -t, --timeout SECONDS  Connection timeout (default: 30)
  -c, --cache            Cache successful GET responses for ${CACHE_TTL}s
  -f, --format FORMAT    pretty (default), compact, table or raw
  -v, --verbose          Print the request that is being made
  -h, --help             Show this help

Authentication:
  Put the token in the API_KEY environment variable. It is sent as
  'Authorization: Bearer \$API_KEY'. There is deliberately no --key option:
  command-line arguments are visible to other users via 'ps'.

Optional config file ($CONFIG_FILE), plain KEY=VALUE lines:
  TIMEOUT=10
  CACHE_TTL=600

Examples:
  ${0##*/} https://api.github.com/repos/torvalds/linux
  ${0##*/} -c -f table https://api.github.com/repos/torvalds/linux
  ${0##*/} -m POST -d '{"name":"demo"}' https://httpbin.org/post
EOF
}

# load_config - read TIMEOUT / CACHE_TTL from the config file without sourcing it
load_config() {
    [[ -f "$CONFIG_FILE" ]] || return 0
    local key value
    while IFS='=' read -r key value; do
        case "$key" in
            TIMEOUT | CACHE_TTL)
                value="${value//\"/}"
                is_positive_int "$value" && printf -v "$key" '%s' "$value"
                ;;
            *) ;;
        esac
    done <"$CONFIG_FILE"
}

validate_url() {
    [[ "$1" =~ ^https?://[^[:space:]]+$ ]] || die "Invalid URL '$1' (must start with http:// or https://)" 2
}

validate_json() {
    printf '%s' "$1" | jq -e . >/dev/null 2>&1 || die "--data is not valid JSON" 2
}

cache_path() {
    printf '%s/%s' "$CACHE_DIR" "$(hash_string "$METHOD:$URL:$DATA")"
}

# cache_fresh FILE - true when FILE exists and is younger than CACHE_TTL
cache_fresh() {
    [[ -f "$1" ]] || return 1
    local age=$(($(date +%s) - $(file_mtime "$1")))
    ((age < CACHE_TTL))
}

# request - perform the HTTP request; body on stdout, status line on stderr
request() {
    local args=(--silent --show-error --location --max-time "$((TIMEOUT * 2))"
        --connect-timeout "$TIMEOUT" --request "$METHOD" --write-out '\n%{http_code}')

    local header
    for header in "${HEADERS[@]+"${HEADERS[@]}"}"; do
        args+=(--header "$header")
    done
    if [[ -n "$API_KEY" ]]; then
        args+=(--header "Authorization: Bearer $API_KEY")
    fi
    if [[ -n "$DATA" ]]; then
        args+=(--header "Content-Type: application/json" --data "$DATA")
    fi

    if [[ "$VERBOSE" == true ]]; then
        # Never echo the Authorization header.
        info "> $METHOD $URL" >&2
    fi
    log INFO "$METHOD $URL"

    local raw http_code body
    # validate_url guarantees $URL starts with http(s)://, so it cannot be mistaken for an option.
    raw=$(curl "${args[@]}" "$URL") || die "Request failed (network error or timeout)" 4
    http_code="${raw##*$'\n'}"
    body="${raw%$'\n'*}"

    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        [[ "$VERBOSE" == true ]] && ok "HTTP $http_code" >&2
        printf '%s' "$body"
    else
        err "HTTP $http_code"
        [[ "$VERBOSE" == true ]] && printf '%s\n' "$body" >&2
        return 1
    fi
}

format_output() {
    local body="$1"
    if [[ "$OUTPUT_FORMAT" == raw ]] || ! printf '%s' "$body" | jq -e . >/dev/null 2>&1; then
        # Not JSON (or raw requested): print as-is.
        printf '%s\n' "$body"
        return 0
    fi
    case "$OUTPUT_FORMAT" in
        pretty) printf '%s' "$body" | jq . ;;
        compact) printf '%s' "$body" | jq -c . ;;
        table) printf '%s' "$body" | jq -r 'if type == "object" then to_entries[] | "\(.key): \(.value)" else .[] | tostring end' ;;
    esac
}

parse_args() {
    while (($# > 0)); do
        case "$1" in
            -m | --method)
                METHOD="$(printf '%s' "${2:?--method needs a value}" | tr '[:lower:]' '[:upper:]')"
                shift 2
                ;;
            -H | --header)
                HEADERS+=("${2:?--header needs a value}")
                shift 2
                ;;
            -d | --data)
                DATA="${2:?--data needs a value}"
                shift 2
                ;;
            -t | --timeout)
                TIMEOUT="${2:?--timeout needs a value}"
                shift 2
                ;;
            -c | --cache)
                USE_CACHE=true
                shift
                ;;
            -f | --format)
                OUTPUT_FORMAT="${2:?--format needs a value}"
                shift 2
                ;;
            -v | --verbose)
                VERBOSE=true
                shift
                ;;
            -h | --help)
                usage
                exit 0
                ;;
            --)
                shift
                URL="${1:-}"
                break
                ;;
            -*)
                err "Unknown option $1"
                usage >&2
                exit 1
                ;;
            *)
                [[ -z "$URL" ]] || die "Multiple URLs given" 2
                URL="$1"
                shift
                ;;
        esac
    done
}

main() {
    parse_args "$@"
    [[ -n "$URL" ]] || {
        err "URL is required"
        usage >&2
        exit 1
    }

    case "$METHOD" in
        GET | POST | PUT | PATCH | DELETE) ;;
        *) die "Unsupported method '$METHOD'" 2 ;;
    esac
    case "$OUTPUT_FORMAT" in
        pretty | compact | table | raw) ;;
        *) die "Unknown format '$OUTPUT_FORMAT'" 2 ;;
    esac
    is_positive_int "$TIMEOUT" || die "--timeout must be a positive integer" 2
    validate_url "$URL"
    require_cmd curl jq
    [[ -z "$DATA" ]] || validate_json "$DATA"
    load_config

    # Only idempotent reads are cached.
    local cache_file="" body
    if [[ "$USE_CACHE" == true && "$METHOD" == GET ]]; then
        mkdir -p "$CACHE_DIR"
        cache_file="$(cache_path)"
        if cache_fresh "$cache_file"; then
            [[ "$VERBOSE" == true ]] && info "(cache hit)" >&2
            format_output "$(cat "$cache_file")"
            return 0
        fi
    fi

    body=$(request) || exit 1
    if [[ -n "$cache_file" ]]; then
        printf '%s' "$body" >"$cache_file"
    fi
    format_output "$body"
}

main "$@"
