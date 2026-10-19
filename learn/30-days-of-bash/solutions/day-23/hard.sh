#!/usr/bin/env bash
# Day 23 hard: install a pre-commit hook that blocks trailing whitespace and obvious secrets.
# Works only inside a throwaway repository.
set -euo pipefail
export GIT_AUTHOR_NAME="Demo" GIT_AUTHOR_EMAIL="demo@example.com"
export GIT_COMMITTER_NAME="Demo" GIT_COMMITTER_EMAIL="demo@example.com"

work="$(mktemp -d)"
git init -q -b main "${work}/repo"
cd "${work}/repo"

cat > .git/hooks/pre-commit <<'EOF'
#!/usr/bin/env bash
# Reject commits that add trailing whitespace or a line like  password=...
set -euo pipefail
status=0
added="$(git diff --cached -U0 --no-color | grep -E '^\+[^+]' || true)"

if grep -nE '^\+.*[[:space:]]+$' <<< "$added" >/dev/null; then
    echo "pre-commit: trailing whitespace in staged changes" >&2
    status=1
fi
if grep -niE '^\+.*(password|secret|api_key)[[:space:]]*=' <<< "$added" >/dev/null; then
    echo "pre-commit: possible secret in staged changes" >&2
    status=1
fi
exit "$status"
EOF
chmod +x .git/hooks/pre-commit

try_commit() {                                 # try_commit MESSAGE
    if git commit -q -m "$1"; then
        echo "committed: $1"
    else
        echo "REJECTED:  $1"
    fi
}

printf 'name = shop\n' > app.conf
git add app.conf
try_commit "add config"

printf 'name = shop\nport = 8080 \n' > app.conf       # note the trailing space
git add app.conf
try_commit "add port (trailing space)"

printf 'name = shop\nport = 8080\npassword = hunter2\n' > app.conf
git add app.conf
try_commit "add password"

printf 'name = shop\nport = 8080\n' > app.conf        # fixed
git add app.conf
try_commit "add port"

echo "--- commits that made it in"
git log --format='  %s' --reverse

cd / && rm -rf -- "$work"
