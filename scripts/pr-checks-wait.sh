#!/usr/bin/env bash
# Wait for a PR's checks to finish (works with gh versions lacking --watch).
# Usage: pr-checks-wait.sh <pr> [timeout-seconds, default 1200]
# Exit 0 when nothing is pending and nothing failed; 1 on a failed check; 2 on timeout;
# 3 when gh errors or lists no checks. Prints the head sha it waited on.
set -uo pipefail
pr="${1:?usage: pr-checks-wait.sh <pr> [timeout]}"
deadline=$(( $(date +%s) + ${2:-1200} ))
sleep 15  # let checks register after a push
while :; do
  out="$(gh pr checks "$pr" 2>&1)"; rc=$?
  sha="$(gh pr view "$pr" --json commits -q '.commits[-1].oid' 2>/dev/null)"
  if ! grep -qE $'\t(pass|fail|pending|queued|in_progress|skipping|cancelled|timed_out|action_required)\t' <<<"$out"; then
    echo "$out"; echo "head ${sha:-unknown}: gh pr checks rc=$rc, no checks listed" >&2; exit 3
  fi
  if ! grep -qE $'\t(pending|queued|in_progress)\t' <<<"$out"; then
    echo "$out"; echo "head ${sha:-unknown}"
    grep -qE $'\t(fail|cancelled|timed_out|action_required)\t' <<<"$out" && exit 1
    exit 0
  fi
  (( $(date +%s) >= deadline )) && { echo "$out"; echo "head ${sha:-unknown}: timeout" >&2; exit 2; }
  sleep 20
done
