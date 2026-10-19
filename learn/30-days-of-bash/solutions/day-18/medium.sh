#!/usr/bin/env bash
# Day 18 medium: install a personal tool into a private bin directory and put it on PATH.
# Temporary files only; nothing in your real home or PATH is changed.
set -euo pipefail

work="$(mktemp -d)"
mkdir -p "${work}/bin"
cat > "${work}/bin/hello-tool" <<'EOF'
#!/usr/bin/env bash
echo "hello from my own tool"
EOF
chmod 755 "${work}/bin/hello-tool"

if command -v hello-tool >/dev/null; then
    echo "found already?"
else
    echo "before: hello-tool is not on PATH"
fi

export PATH="${work}/bin:${PATH}"           # prepend, keep the old PATH
hello-tool
echo "after: found as $(command -v hello-tool | sed "s#${work}#WORK#")"

# Remove it again: rebuild PATH without our entry.
PATH="${PATH#"${work}/bin:"}"
if command -v hello-tool >/dev/null; then
    echo "still found"
else
    echo "removed from PATH again"
fi

rm -rf -- "$work"
