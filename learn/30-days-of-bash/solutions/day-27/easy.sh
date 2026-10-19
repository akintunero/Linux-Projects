#!/usr/bin/env bash
# Day 27 easy: run a child script and report its stdout, stderr and exit status separately.
set -euo pipefail

work="$(mktemp -d)"
cat > "${work}/report.sh" <<'EOF'
#!/usr/bin/env bash
echo "42 files processed"
echo "warning: 2 files skipped" >&2
exit 4
EOF

run_and_report() {
    local script="$1" out status=0
    out="$(bash "$script" 2>"${work}/stderr.txt")" || status=$?
    echo "stdout: ${out}"
    echo "stderr: $(< "${work}/stderr.txt")"
    echo "exit status: ${status}"
    return "$status"
}

status=0
run_and_report "${work}/report.sh" || status=$?
case "$status" in
    0) echo "result: success" ;;
    4) echo "result: finished with skipped files" ;;
    *) echo "result: failure" ;;
esac

rm -rf -- "$work"
