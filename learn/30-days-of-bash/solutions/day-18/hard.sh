#!/usr/bin/env bash
# Day 18 hard: load a .env file safely (no eval, no source), and never print secret values.
# Temporary files only.
set -euo pipefail

load_env() {
    local file="$1" line key value loaded=0
    while IFS= read -r line || [[ -n $line ]]; do
        line="${line#"${line%%[![:space:]]*}"}"          # trim leading whitespace
        case "$line" in ''|'#'*) continue ;; esac        # skip blanks and comments
        if [[ $line != *=* ]]; then
            echo "skip (no '='): ${line}" >&2
            continue
        fi
        key="${line%%=*}"
        value="${line#*=}"
        case "$key" in
            ''|[0-9]*|*[!A-Za-z0-9_]*)
                echo "skip (bad name): ${key}" >&2
                continue
                ;;
        esac
        if [[ $value == \"*\" || $value == \'*\' ]]; then
            value="${value:1:${#value}-2}"               # strip one pair of quotes
        fi
        export "${key}=${value}"
        loaded=$(( loaded + 1 ))
        case "$key" in
            *PASSWORD*|*SECRET*|*TOKEN*|*KEY*) echo "loaded ${key}=****" ;;
            *)                                 echo "loaded ${key}=${value}" ;;
        esac
    done < "$file"
    echo "${loaded} variable(s) loaded"
}

work="$(mktemp -d)"
cat > "${work}/app.env" <<'EOF'
# application settings
APP_NAME="Shop Front"
APP_PORT=8080
DB_PASSWORD='s3cr3t value'

BAD NAME=oops
1ST=nope
JUST_TEXT
EOF

load_env "${work}/app.env"
echo "--- the values are really in the environment"
bash -c 'echo "child: APP_NAME=[${APP_NAME}] APP_PORT=[${APP_PORT}]"'
rm -rf -- "$work"
