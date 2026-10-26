#!/usr/bin/env bash
# Build a review package for a subagent reviewer.
# Usage: review-pkg.sh <base-ref> [out-file]
# Writes: commit list, diffstat, trailer check, full diff. Prints the out path.
# docs/superpowers (spec, plan, ledger) is left out of the diffstat and diff.
set -euo pipefail

base="${1:?usage: review-pkg.sh <base-ref> [out-file]}"
out="${2:-$(git rev-parse --git-common-dir)/review-pkg-$(git rev-parse --short "$1")-$(git rev-parse --short HEAD).md}"

{
  echo "# Review package: ${base}..HEAD"
  echo
  echo "## Commits"
  git log --format='- %h %s' "${base}..HEAD"
  echo
  echo "## Trailer check"
  want_file="$(git rev-parse --git-common-dir)/claude-trailer"
  if [[ -f "$want_file" ]]; then
    want="$(cat "$want_file")"
    bad=$(git log --format='%h%x00%B%x01' "${base}..HEAD" \
      | awk -v RS='\001' -v want="$want" 'NF && index($0, want)==0 {split($0,a,"\0"); print a[1]}' \
      | tr -d '\n ')
    if [[ -n "$bad" ]]; then echo "MISSING required trailer: $bad"; else echo "ok"; fi
  else
    echo "(no .git/claude-trailer set)"
  fi
  echo
  echo "## Diffstat"
  echo '```'
  git diff --stat "${base}..HEAD" -- . ':!docs/superpowers'
  echo '```'
  echo
  echo "## Diff"
  echo '```diff'
  git diff "${base}..HEAD" -- . ':!docs/superpowers'
  echo '```'
} > "$out"

echo "$out"
