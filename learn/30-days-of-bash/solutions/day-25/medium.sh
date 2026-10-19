#!/usr/bin/env bash
# Day 25 medium: make a script testable with a main guard, then test it by sourcing it.
# Works in a temporary directory.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/temperature.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# c_to_f CELSIUS : integer Fahrenheit, rounded
c_to_f() {
    local c="$1"
    echo $(( (c * 9 + (c >= 0 ? 2 : -2)) / 5 + 32 ))
}

main() {
    (( $# == 1 )) || { echo "usage: temperature.sh CELSIUS" >&2; exit 2; }
    echo "$1 C = $(c_to_f "$1") F"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
EOF

echo "--- executed: main runs"
bash "${work}/temperature.sh" 100

echo "--- sourced: only the function is loaded"
(
    source "${work}/temperature.sh"
    echo "no output from sourcing"
    for c in -40 0 37 100; do
        echo "c_to_f ${c} = $(c_to_f "$c")"
    done
)

status=0
bash "${work}/temperature.sh" 2>/dev/null || status=$?
echo "no argument -> exit ${status}"

rm -rf -- "$work"
