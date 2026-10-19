#!/usr/bin/env bash
# Day 25 easy: move shared helpers into a library and source it relative to the script itself.
# Works in a temporary directory.
set -euo pipefail

work="$(mktemp -d)"
mkdir -p "${work}/lib" "${work}/elsewhere"

cat > "${work}/lib/common.sh" <<'EOF'
log()  { printf '[%s] %s\n' "$1" "${*:2}" >&2; }
die()  { log ERROR "$*"; exit 1; }
EOF

cat > "${work}/tool.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/lib/common.sh"
log INFO "tool started"
[[ ${1:-} == fail ]] && die "asked to fail"
echo "tool finished"
EOF

echo "--- run from the script directory"
(cd "$work" && bash tool.sh 2>&1)
echo "--- run from a different directory"
(cd "${work}/elsewhere" && bash ../tool.sh 2>&1)
echo "--- a failing run"
status=0
bash "${work}/tool.sh" fail 2>&1 || status=$?
echo "exit status: ${status}"

rm -rf -- "$work"
