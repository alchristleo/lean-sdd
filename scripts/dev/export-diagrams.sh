#!/usr/bin/env bash
# Dev only. Export one archify candidate as assets/<name>-light.svg and assets/<name>-dark.svg.
# Usage: scripts/dev/export-diagrams.sh <candidate.json> <name> [type]
# Needs: node, archify (ARCHIFY_BIN), playwright-core (PLAYWRIGHT_CORE), Chromium (CHROME).
# This script passes CHROME to archify as ARCHIFY_CHROME, so set CHROME, not ARCHIFY_CHROME.
set -euo pipefail

cand=${1:?usage: export-diagrams.sh <candidate.json> <name> [type]}
name=${2:?usage: export-diagrams.sh <candidate.json> <name> [type]}
type=${3:-workflow}
root=$(cd "$(dirname "$0")/../.." && pwd)
archify=${ARCHIFY_BIN:-$HOME/.claude/skills/archify/bin/archify.mjs}
export PLAYWRIGHT_CORE=${PLAYWRIGHT_CORE:-$(npm root -g)/playwright-core}
export CHROME=${CHROME:-$(ls -d "$HOME"/.cache/ms-playwright/chromium-*/chrome-linux64/chrome 2>/dev/null | tail -n 1)}

[ -f "$PLAYWRIGHT_CORE/package.json" ] || {
  echo "export-diagrams: playwright-core not found at '$PLAYWRIGHT_CORE'. Set PLAYWRIGHT_CORE to its directory." >&2
  exit 1
}
[ -x "$CHROME" ] || {
  echo "export-diagrams: Chromium not found at '$CHROME'. Set CHROME to a Chromium executable." >&2
  exit 1
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$root/assets"

ARCHIFY_CHROME=$CHROME node "$archify" finalize "$type" "$cand" "$tmp/$name.html" --quality showcase >&2

node - "$tmp/$name.html" "$tmp" <<'EOF'
const { chromium } = require(process.env.PLAYWRIGHT_CORE);
(async () => {
  const [html, out] = process.argv.slice(2);
  const browser = await chromium.launch({ executablePath: process.env.CHROME });
  const page = await browser.newPage({ acceptDownloads: true });
  await page.goto('file://' + html);
  for (const theme of ['light', 'dark']) {
    await page.click('#btn-export');
    const [dl] = await Promise.all([
      page.waitForEvent('download'),
      page.click(`#export-menu button[data-format="svg-${theme}"]`),
    ]);
    await dl.saveAs(`${out}/${theme}.svg`);
  }
  await browser.close();
})().catch((e) => { console.error(e); process.exit(1); });
EOF

for theme in light dark; do
  cp "$tmp/$theme.svg" "$root/assets/$name-$theme.svg"
done
