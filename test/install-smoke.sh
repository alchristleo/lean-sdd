#!/usr/bin/env bash
# AC2 + AC12: clean install exposes 2 skills, 10 agents, the usage-guard hook on
# UserPromptSubmit and PostToolUse, executable scripts, and no commit-msg hook.
# Usage: test/install-smoke.sh [marketplace-source]   (default: this repo)
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SRC=${1:-$ROOT}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export CLAUDE_CONFIG_DIR="$TMP/config"
mkdir -p "$CLAUDE_CONFIG_DIR" "$TMP/scratch"

fail=0
check() { # check <description> <command...>
  desc=$1; shift
  if "$@"; then echo "ok   $desc"; else echo "FAIL $desc"; fail=1; fi
}

git -C "$TMP/scratch" init -q || { echo "usage error: git init failed"; exit 2; }
cd "$TMP/scratch" || exit 2
claude plugin install --marketplace "$SRC" lean-sdd >"$TMP/install.log" 2>&1 || {
  echo "usage error: install failed"; cat "$TMP/install.log"; exit 2; }

DIR=$(python3 -I -c '
import json, sys
d = json.load(open(sys.argv[1]))
print(d["plugins"]["lean-sdd@lean-sdd"][0]["installPath"])' "$CLAUDE_CONFIG_DIR/plugins/installed_plugins.json") || {
  echo "usage error: no installPath"; exit 2; }

skills=$(find "$DIR/skills" -mindepth 2 -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l)
agents=$(find "$DIR/agents" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l)
check "2 skills (found $skills)" test "$skills" -eq 2
check "10 agents (found $agents)" test "$agents" -eq 10

hook_ok() { # hook_ok <event>
  python3 -I -c '
import json, sys
h = json.load(open(sys.argv[1]))["hooks"].get(sys.argv[2], [])
sys.exit(0 if any("usage-guard.py" in x["command"] for g in h for x in g["hooks"]) else 1)' "$DIR/hooks/hooks.json" "$1"
}
check "usage-guard on UserPromptSubmit" hook_ok UserPromptSubmit
check "usage-guard on PostToolUse" hook_ok PostToolUse

check "usage-guard.py executable" test -x "$DIR/hooks/usage-guard.py"

total=$(find "$DIR/scripts" -maxdepth 1 -name '*.sh' 2>/dev/null | wc -l)
nonexec=$(find "$DIR/scripts" -maxdepth 1 -name '*.sh' ! -perm -u+x 2>/dev/null | wc -l)
check "scripts/ exists with at least 1 .sh ($total found)" test -d "$DIR/scripts" -a "$total" -ge 1
check "every scripts/*.sh executable ($nonexec not)" test "$total" -ge 1 -a "$nonexec" -eq 0
check "no .git/hooks/commit-msg after install" test ! -e "$TMP/scratch/.git/hooks/commit-msg"

exit "$fail"
