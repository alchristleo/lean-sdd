#!/usr/bin/env bash
# Merge a PR only if its remote head is the sha the checks passed on (works with gh versions
# lacking --match-head-commit / headRefOid), then check that no branch commit was left behind.
# Usage: pr-merge.sh <pr> <sha>   (sha = the 40-hex "head" line pr-checks-wait.sh printed)
# Exit 0 merged and nothing lost; 1 head moved or sha malformed; 2 merge failed; 3 lost commits printed.
set -uo pipefail
pr="${1:?usage: pr-merge.sh <pr> <sha>}"; want="${2:?usage: pr-merge.sh <pr> <sha>}"
if ! [[ "$want" =~ ^[0-9a-f]{40}$ ]]; then
  echo "sha must be 40 hex characters, got: $want" >&2; exit 1
fi
branch="$(gh pr view "$pr" --json headRefName -q .headRefName)" || exit 2
base="$(gh pr view "$pr" --json baseRefName -q .baseRefName)" || exit 2
check_head() {
  head="$(git ls-remote origin "refs/heads/$branch" | cut -f1)"
  if [[ "$head" != "$want" ]]; then
    echo "head of $branch is ${head:-missing}, not $want: re-run pr-checks-wait.sh" >&2; exit 1
  fi
}
check_head
git fetch -q origin || exit 2
check_head  # re-read right before the merge, after the fetch
gh pr merge "$pr" --merge || exit 2
git fetch -q origin
lost="$(git log --oneline "origin/$base..origin/$branch")"
if [[ -n "$lost" ]]; then echo "lost work, land it on $base:"; echo "$lost"; exit 3; fi
echo "merged $pr ($branch@${head:0:7}) into $base; nothing lost"
