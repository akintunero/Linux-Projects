#!/usr/bin/env bash
#
# disk-space-usage.sh - show which subdirectories use the most disk space.
#
# Usage: disk-space-usage.sh [OPTIONS] [DIRECTORY]

set -euo pipefail

# shellcheck source=../../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

readonly VERSION="3.0.0"
readonly DEFAULT_EXCLUDES=(/proc /sys /dev /run)

OUTPUT_FORMAT="human" # human | bytes | kb | mb | gb
MAX_DEPTH=1           # how many directory levels below DIRECTORY to list
TOP_N=0               # 0 = show everything
REPORT_FILE=""        # empty = do not write a report
VERBOSE=false
START_DIR="."
EXCLUDES=("${DEFAULT_EXCLUDES[@]}")
DU_HAS_BYTES=false # GNU du can report exact bytes (-b); BSD/macOS du cannot
du -sb . >/dev/null 2>&1 && DU_HAS_BYTES=true

usage() {
    cat <<EOF
Disk Space Usage Analyzer $VERSION

Usage: ${0##*/} [OPTIONS] [DIRECTORY]

Lists the subdirectories of DIRECTORY (default: .) from largest to smallest.

Options:
  -f, --format FORMAT   human (default), bytes, kb, mb or gb
  -d, --depth N         Levels of subdirectories to list (default: 1)
  -n, --top N           Only show the N largest entries
  -x, --exclude DIR     Skip DIR (repeatable; defaults: ${DEFAULT_EXCLUDES[*]})
  -o, --output FILE     Also save the report to FILE
  -v, --verbose         Show a progress bar while scanning
  -h, --help            Show this help

Examples:
  ${0##*/}                  # largest folders in the current directory
  ${0##*/} -n 5 /var        # top five under /var
  ${0##*/} -f mb -d 2 ~     # sizes in MB, two levels deep
EOF
}

# dir_bytes DIR - total size of DIR in bytes (apparent size where supported)
dir_bytes() {
    local dir="$1" out size
    # `|| true`: du exits non-zero when it meets an unreadable subdirectory
    # but still prints the total for everything it could read.
    if [[ "$DU_HAS_BYTES" == true ]]; then
        out=$(du -sb -- "$dir" 2>/dev/null || true)
        size="${out%%$'\t'*}"
    else
        out=$(du -sk -- "$dir" 2>/dev/null || true)
        size=$((${out%%$'\t'*} * 1024))
    fi
    printf '%s\n' "${size:-0}"
}

# format_size BYTES - render BYTES in $OUTPUT_FORMAT
format_size() {
    local bytes="$1"
    case "$OUTPUT_FORMAT" in
        bytes) printf '%s' "$bytes" ;;
        kb) awk -v b="$bytes" 'BEGIN { printf "%.2f", b / 1024 }' ;;
        mb) awk -v b="$bytes" 'BEGIN { printf "%.2f", b / 1048576 }' ;;
        gb) awk -v b="$bytes" 'BEGIN { printf "%.2f", b / 1073741824 }' ;;
        human)
            awk -v b="$bytes" 'BEGIN {
                split("B KB MB GB TB", u, " ")
                i = 1
                while (b >= 1024 && i < 5) { b /= 1024; i++ }
                if (i == 1) printf "%d %s", b, u[i]; else printf "%.2f %s", b, u[i]
            }'
            ;;
    esac
}

format_unit() {
    case "$OUTPUT_FORMAT" in
        bytes) printf ' bytes' ;;
        kb) printf ' KB' ;;
        mb) printf ' MB' ;;
        gb) printf ' GB' ;;
    esac
}

is_excluded() {
    local dir="$1" pattern
    for pattern in "${EXCLUDES[@]}"; do
        [[ "$dir" == "$pattern" || "$dir" == "$pattern"/* ]] && return 0
    done
    return 1
}

show_progress() {
    local current="$1" total="$2"
    local pct=$((current * 100 / total)) filled=$((current * 40 / total))
    printf '\rProgress: [%-40s] %3d%%' "$(printf '%*s' "$filled" '' | tr ' ' '#')" "$pct"
}

parse_args() {
    while (($# > 0)); do
        case "$1" in
            -h | --help)
                usage
                exit 0
                ;;
            -f | --format)
                OUTPUT_FORMAT="${2:?--format needs a value}"
                shift 2
                ;;
            -d | --depth)
                MAX_DEPTH="${2:?--depth needs a value}"
                shift 2
                ;;
            -n | --top)
                TOP_N="${2:?--top needs a value}"
                shift 2
                ;;
            -x | --exclude)
                EXCLUDES+=("${2:?--exclude needs a value}")
                shift 2
                ;;
            -o | --output)
                REPORT_FILE="${2:?--output needs a value}"
                shift 2
                ;;
            -v | --verbose)
                VERBOSE=true
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                err "Unknown option $1"
                usage >&2
                exit 1
                ;;
            *)
                START_DIR="$1"
                shift
                ;;
        esac
    done
}

validate() {
    case "$OUTPUT_FORMAT" in
        human | bytes | kb | mb | gb) ;;
        *) die "Invalid format '$OUTPUT_FORMAT' (use human, bytes, kb, mb or gb)" 2 ;;
    esac
    is_positive_int "$MAX_DEPTH" || die "--depth must be a positive integer" 2
    [[ "$TOP_N" =~ ^[0-9]+$ ]] || die "--top must be a non-negative integer" 2
    [[ -d "$START_DIR" ]] || die "Directory '$START_DIR' does not exist or is not accessible"
    require_cmd du awk find sort
}

main() {
    parse_args "$@"
    validate

    info "Disk Space Usage Analyzer $VERSION"
    msg "Analyzing directory: $START_DIR"
    msg "Maximum depth: $MAX_DEPTH"
    msg "Output format: $OUTPUT_FORMAT"
    msg ""

    local subdirs=() dir
    while IFS= read -r -d '' dir; do
        is_excluded "$dir" || subdirs+=("$dir")
    done < <(find "$START_DIR" -mindepth 1 -maxdepth "$MAX_DEPTH" -type d -print0 2>/dev/null)

    if ((${#subdirs[@]} == 0)); then
        msg "No subdirectories found in $START_DIR"
        return 0
    fi

    # Collect "bytes<TAB>path" lines, then sort largest first.
    local rows=() size i=0 total=${#subdirs[@]}
    for dir in "${subdirs[@]}"; do
        i=$((i + 1))
        if [[ "$VERBOSE" == true ]]; then show_progress "$i" "$total"; fi
        size=$(dir_bytes "$dir")
        rows+=("$size"$'\t'"$dir")
    done
    if [[ "$VERBOSE" == true ]]; then printf '\n'; fi

    local sorted
    sorted=$(printf '%s\n' "${rows[@]}" | sort -t$'\t' -k1,1nr)
    if ((TOP_N > 0)); then
        sorted=$(head -n "$TOP_N" <<<"$sorted")
    fi

    local total_bytes
    total_bytes=$(dir_bytes "$START_DIR")

    local unit
    unit=$(format_unit)
    local line bytes path files dirs report=""
    while IFS=$'\t' read -r bytes path; do
        # `|| true`: find exits non-zero on unreadable directories.
        files=$( (find "$path" -type f 2>/dev/null || true) | wc -l | tr -d ' ')
        dirs=$( (find "$path" -mindepth 1 -type d 2>/dev/null || true) | wc -l | tr -d ' ')
        line="$(printf 'Directory: %s\nSize: %s%s\nFiles: %s\nDirectories: %s\n' \
            "$path" "$(format_size "$bytes")" "$unit" "$files" "$dirs")"
        report+="$line"$'\n\n'
    done <<<"$sorted"
    printf '%s' "$report"

    info "Summary Report"
    msg "=============="
    msg "Total Size: $(format_size "$total_bytes")$unit"
    msg "Entries Listed: $(wc -l <<<"$sorted" | tr -d ' ')"
    msg "Excluded: ${EXCLUDES[*]}"

    if [[ -n "$REPORT_FILE" ]]; then
        {
            printf 'Disk Space Usage Report\n'
            printf '======================\n'
            printf 'Generated: %s\n' "$(date)"
            printf 'Directory: %s\n' "$START_DIR"
            printf 'Total Size: %s%s\n\n' "$(format_size "$total_bytes")" "$unit"
            printf 'Detailed Breakdown:\n==================\n'
            printf '%s' "$report"
        } >"$REPORT_FILE"
        ok "Report saved to: $REPORT_FILE"
    fi
}

main "$@"
