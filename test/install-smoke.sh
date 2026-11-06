#!/usr/bin/env bash
# AC2 + AC12: clean install exposes 2 skills, 10 agents, no plugin hooks (directory policy:
# command hooks only from Verified orgs), executable scripts, and no commit-msg hook.
# The README settings.json snippet registers the usage guard on UserPromptSubmit and PostToolUse.
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

check "plugin ships no hooks/hooks.json" test ! -e "$DIR/hooks/hooks.json"

check "usage-guard.py executable" test -x "$DIR/hooks/usage-guard.py"

total=$(find "$DIR/scripts" -maxdepth 1 -name '*.sh' 2>/dev/null | wc -l)
nonexec=$(find "$DIR/scripts" -maxdepth 1 -name '*.sh' ! -perm -u+x 2>/dev/null | wc -l)
check "scripts/ exists with at least 1 .sh ($total found)" test -d "$DIR/scripts" -a "$total" -ge 1
check "every scripts/*.sh executable ($nonexec not)" test "$total" -ge 1 -a "$nonexec" -eq 0
check "no .git/hooks/commit-msg after install" test ! -e "$TMP/scratch/.git/hooks/commit-msg"

readme_cmd() { # readme_cmd [event]: status-line command, or the hook command for <event>
  python3 -I -c '
import json, re, sys
t = open(sys.argv[1]).read()
s = json.loads(re.search(r"```json\n(.*?)\n```", t, re.S).group(1))
print(s["hooks"][sys.argv[2]][0]["hooks"][0]["command"] if len(sys.argv) > 2 else s["statusLine"]["command"])' "$ROOT/README.md" "$@"
}

# README status-line command: run it against the install, 96% sample -> cache -> guard.
statusline_guard() {
  local cmd out
  cmd=$(readme_cmd) || return 1
  printf '{"model":{"display_name":"M"},"rate_limits":{"five_hour":{"used_percentage":96}}}' |
    sh -c "$cmd" >/dev/null || return 1
  test -s "$CLAUDE_CONFIG_DIR/state/usage.json" || return 1
  out=$(printf '{"hook_event_name":"UserPromptSubmit","session_id":"s"}' | "$DIR/hooks/usage-guard.py")
  case $out in *"USAGE GUARD"*) return 0 ;; *) return 1 ;; esac
}
check "README status-line command writes the cache and the guard fires" statusline_guard

# README hook commands (run after statusline_guard filled the cache) reach the installed guard.
readme_hook() { # readme_hook <event>
  local cmd out
  cmd=$(readme_cmd "$1") || return 1
  out=$(printf '{"hook_event_name":"%s","session_id":"h-%s"}' "$1" "$1" | sh -c "$cmd") || return 1
  case $out in *"USAGE GUARD"*) return 0 ;; *) return 1 ;; esac
}
check "README hook on UserPromptSubmit fires the guard" readme_hook UserPromptSubmit
check "README hook on PostToolUse fires the guard" readme_hook PostToolUse

# Empty plugin cache: the command must exit 0 and must not run a planted relative script.
statusline_no_fallback() {
  local cmd cfg plant
  cmd=$(readme_cmd) || return 1
  cfg="$TMP/emptycfg"; plant="$TMP/plant"
  mkdir -p "$cfg" "$plant/scripts"
  printf 'import pathlib\npathlib.Path("ran").write_text("x")\n' >"$plant/scripts/statusline-cache.py"
  (cd "$plant" && CLAUDE_CONFIG_DIR="$cfg" sh -c "$cmd" </dev/null >/dev/null 2>&1) || return 1
  test ! -e "$plant/ran"
}
check "README status-line command with an empty cache exits 0 and runs no planted script" statusline_no_fallback

exit "$fail"
