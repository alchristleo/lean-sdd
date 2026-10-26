#!/usr/bin/env bash
# Local acceptance checks. Usage: test/check.sh <guard>
# guard (AC11): status-line sample -> cache -> usage-guard hook, in a temp state dir.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)

guard() {
  local tmp out fail=0
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  export CLAUDE_CONFIG_DIR="$tmp"
  for pct in 96 10; do
    rm -rf "$tmp/state"
    printf '{"model":{"display_name":"M"},"rate_limits":{"five_hour":{"used_percentage":%s}}}' "$pct" |
      "$ROOT/scripts/statusline-cache.py" >/dev/null
    out=$(printf '{"hook_event_name":"UserPromptSubmit","session_id":"s"}' | "$ROOT/hooks/usage-guard.py")
    if [ "$pct" -eq 96 ]; then
      case $out in *"USAGE GUARD"*) echo "ok   96% prints USAGE GUARD" ;; *) echo "FAIL 96% printed: $out"; fail=1 ;; esac
    elif [ -z "$out" ]; then
      echo "ok   10% prints nothing"
    else
      echo "FAIL 10% printed: $out"; fail=1
    fi
  done
  return "$fail"
}

case ${1:-} in
  guard) guard ;;
  *) echo "usage: test/check.sh guard" >&2; exit 2 ;;
esac
