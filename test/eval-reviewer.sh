#!/usr/bin/env bash
# Behavior eval for the sdd-reviewer agent text (dev only, needs a logged-in claude; not run by check.sh).
# Usage: eval-reviewer.sh <agent.md> | --base <sha> | --selftest   (--base reads agents/sdd-reviewer.md at that sha)
# Prints the reviewer output, then a last line PASS or FAIL <reason>. Exit 0 PASS, 1 FAIL, 2 usage.
set -euo pipefail

# judge: reads reviewer output on stdin. Exit 0 PASS: the PRE-EXISTING section (heading or same-line form)
# holds an old.py item, and no finding is located at old.py (findings in new.py may cite old.py as the cause).
judge() {
  local out pre
  out="$(cat)"
  pre="$(printf '%s\n' "$out" | awk '
    /^[#*[:space:]-]*PRE-EXISTING/ {on=1}
    /^[#*[:space:]-]*(VERDICT|FINDINGS|ACS|PRIOR)([^[:alnum:]_]|$)/ {on=0}
    on')"
  printf '%s\n' "$pre" | grep -qE '(^|[^[:alnum:]_])old\.py' \
    && ! printf '%s\n' "$out" | grep -qE '^[[:space:]]*(- |\* |\*\*)?\[(must|should|nit)\][[:space:]]*([^[:space:]:]*/)?old\.py'
}

selftest() {
  local bad=0
  check() { # name expected(0|1) text
    local rc=0; printf '%s\n' "$3" | judge || rc=$?
    if [[ $rc -eq $2 ]]; then echo "ok   $1"; else echo "FAIL $1"; bad=1; fi
  }
  check heading-form 0 $'VERDICT: approve\nPRE-EXISTING\n- old.py:5 — wrong clamp — return hi'
  check same-line 0 $'VERDICT: approve\nPRE-EXISTING: old.py:5 — wrong clamp — return hi'
  check bold-label 0 $'VERDICT: approve\n**PRE-EXISTING:**\nold.py:5 — wrong clamp — return hi'
  check findings-ends-section 1 $'## PRE-EXISTING\nnone\n## FINDINGS\n[nit] new.py:3 — x — y (see old.py)'
  check test-old-only 1 $'VERDICT: approve\nPRE-EXISTING: test_old.py:4 — weak test — add case'
  check bulleted-finding-at-old 1 $'FINDINGS:\n- [must] old.py:5 — wrong clamp — return hi\nPRE-EXISTING: old.py:5 — wrong clamp — return hi'
  check finding-in-new-cites-old 0 $'FINDINGS:\n[should] new.py:4 — clamp from old.py misbehaves — guard\nPRE-EXISTING: old.py:5 — wrong clamp — return hi'
  check no-pre-existing 1 $'VERDICT: approve\nFINDINGS: none'
  return $bad
}

usage() { echo "usage: eval-reviewer.sh <agent.md> | --base <sha> | --selftest" >&2; exit 2; }
root="$(cd "$(dirname "$0")/.." && pwd)"
case "${1:-}" in
  --selftest) selftest; exit $? ;;
  --base) [[ $# -eq 2 ]] || usage; agent="$(git -C "$root" show "$2:agents/sdd-reviewer.md")" || usage ;;
  ""|-*) usage ;;
  *) [[ $# -eq 1 && -f "$1" ]] || usage; agent="$(cat "$1")" ;;
esac

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fx="$tmp/fx"; mkdir "$fx"; cd "$fx"
git init -q; git config user.email e@e; git config user.name e
"$root/scripts/install-git-hooks.sh" "Co-Authored-By: Eval <e@e>" >/dev/null

cat > old.py <<'PY'
def clamp(x, lo, hi):
    if x < lo:
        return lo
    if x > hi:
        return lo
    return x
PY
cat > test_old.py <<'PY'
from old import clamp

def test_clamp():
    assert clamp(5, 0, 10) == 5
    assert clamp(-1, 0, 10) == 0
PY
git add -A; git commit -q -m "feat: old module"
base="$(git rev-parse HEAD)"

cat > new.py <<'PY'
from old import clamp

def bounded_double(x):
    return clamp(x * 2, 0, 100)
PY
cat > test_new.py <<'PY'
from new import bounded_double

def test_bounded_double():
    assert bounded_double(3) == 6
    assert bounded_double(-4) == 0
PY
git add -A; git commit -q -m "feat: add bounded_double

Co-Authored-By: Eval <e@e>"

pkg="$("$root/scripts/review-pkg.sh" "$base" "$tmp/pkg.md")"
trailer="$(awk '/^## Trailer check/{getline; print; exit}' "$pkg")"
if [[ "$trailer" != "ok" ]] || git diff --name-only "$base..HEAD" | grep -qx old.py; then
  echo "FAIL fixture"; exit 1
fi

body="$(printf '%s\n' "$agent" | awk '/^---$/ && n<2 {n++; next} n>=2')"
brief="Review package: $pkg
Task: Add new.py:bounded_double with tests"
# --bare needs ANTHROPIC_API_KEY; with a login only, isolate from user settings by hand.
if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then iso=(--bare); else iso=(--setting-sources project --disable-slash-commands --strict-mcp-config); fi
rc=0
out="$(claude -p "${iso[@]}" --model sonnet --tools Read,Bash,Grep,Glob --allowedTools Read,Bash,Grep,Glob \
  --add-dir "$tmp" --system-prompt "$body" "$brief" </dev/null)" || rc=$?
if [[ $rc -ne 0 ]]; then echo "FAIL claude rc=$rc"; exit 1; fi
printf '%s\n' "$out"

if printf '%s\n' "$out" | judge; then
  echo PASS
else
  echo "FAIL no old.py item under PRE-EXISTING, or a finding located at old.py"; exit 1
fi
