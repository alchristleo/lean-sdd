#!/usr/bin/env bash
# Behavior eval for the sdd-reviewer agent text (dev only, needs a logged-in claude; not run by check.sh).
# Usage: eval-reviewer.sh <agent.md> | --base <sha>   (--base reads agents/sdd-reviewer.md at that sha)
# Prints the reviewer output, then a last line PASS or FAIL <reason>. Exit 0 PASS, 1 FAIL, 2 usage.
set -euo pipefail

usage() { echo "usage: eval-reviewer.sh <agent.md> | --base <sha>" >&2; exit 2; }
root="$(cd "$(dirname "$0")/.." && pwd)"
case "${1:-}" in
  --base) [[ $# -eq 2 ]] || usage; agent="$(git -C "$root" show "$2:agents/sdd-reviewer.md")" || usage ;;
  ""|-*) usage ;;
  *) [[ $# -eq 1 && -f "$1" ]] || usage; agent="$(cat "$1")" ;;
esac

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fx="$tmp/fx"; mkdir "$fx"; cd "$fx"
git init -q; git config user.email e@e; git config user.name e
"$root/scripts/install-git-hooks.sh" "Co-Authored-By: Eval <e@e>" >/dev/null

cat > old.py <<'PY'
def ratio(a, b):
    return a / b
PY
cat > test_old.py <<'PY'
from old import ratio

def test_ratio():
    assert ratio(6, 3) == 2
PY
git add -A; git commit -q -m "feat: old module"
base="$(git rev-parse HEAD)"

cat > new.py <<'PY'
from old import ratio

def double_ratio(a, b):
    return ratio(a, b) * 2
PY
cat > test_new.py <<'PY'
from new import double_ratio

def test_double_ratio():
    assert double_ratio(9, 3) == 6
    assert double_ratio(-3, 1) == -6
PY
git add -A; git commit -q -m "feat: add double_ratio

Co-Authored-By: Eval <e@e>"

pkg="$("$root/scripts/review-pkg.sh" "$base" "$tmp/pkg.md")"
trailer="$(awk '/^## Trailer check/{getline; print; exit}' "$pkg")"
if [[ "$trailer" != "ok" ]] || git diff --name-only "$base..HEAD" | grep -qx old.py; then
  echo "FAIL fixture"; exit 1
fi

body="$(printf '%s\n' "$agent" | awk '/^---$/ && n<2 {n++; next} n>=2')"
brief="Review package: $pkg
Task: Add new.py:double_ratio with tests"
# --bare needs ANTHROPIC_API_KEY; with a login only, isolate from user settings by hand.
if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then iso=(--bare); else iso=(--setting-sources project --disable-slash-commands --strict-mcp-config); fi
out="$(claude -p "${iso[@]}" --model sonnet --tools Read,Bash,Grep,Glob --allowedTools Read,Bash,Grep,Glob \
  --add-dir "$tmp" --system-prompt "$body" "$brief" </dev/null)"
printf '%s\n' "$out"

if printf '%s\n' "$out" | grep -E 'PRE-EXISTING:' | grep -q 'old\.py' \
   && ! printf '%s\n' "$out" | grep -E '\[(must|should|nit)\]' | grep -q 'old\.py'; then
  echo PASS
else
  echo "FAIL no PRE-EXISTING old.py line, or old.py flagged as a finding"; exit 1
fi
