#!/usr/bin/env bash
# Install the trailer-normalizing commit-msg hook into the current repo
# and record the required trailer.
# Usage: install-git-hooks.sh "<trailer>[\n<trailer>...]"  (one trailer per line, e.g. Co-Authored-By + Claude-Session)
set -euo pipefail
trailer="${1:?usage: install-git-hooks.sh '<Co-Authored-By trailer>'}"
gitdir="$(git rev-parse --git-common-dir)"
hooks="$gitdir/hooks"
if hp="$(git config core.hooksPath)"; then
  [[ "$hp" == /* ]] || hp="$(git rev-parse --show-toplevel)/$hp"
  hp="$(realpath -m "$hp")"
  case "$hp/" in
    "$(realpath "$gitdir")"/*) hooks="$hp" ;;
    *) echo "refusing: core.hooksPath ($hp) is outside the git dir; install the hook by hand" >&2; exit 1 ;;
  esac
fi
mkdir -p "$hooks"
src="$(dirname "$0")/git-hooks/commit-msg"
dst="$hooks/commit-msg"
# sha256 of the unmarked hook shipped before the marker existed; treat it as ours.
legacy=c10fdac1f41f9568e11f7ccaaf43e605fb4be340f304872442cd0e066db51c90
if [[ -e "$dst" ]] && ! cmp -s "$src" "$dst" && ! grep -qx '# lean-sdd commit-msg hook' "$dst" \
   && [[ "$(sha256sum "$dst" | cut -d' ' -f1)" != "$legacy" ]]; then
  echo "refusing: $dst exists and differs; merge by hand" >&2
  exit 1
fi
cp "$src" "$dst"
chmod +x "$dst"
printf '%s\n' "$trailer" > "$gitdir/claude-trailer"
echo "installed $dst; trailer: $trailer"
