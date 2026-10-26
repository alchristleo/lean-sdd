# T2 findings: archify SVG export (Decision 11)

Date: 2026-10-26. Archify 3.0.1 (`~/.claude/skills/archify/bin/archify.mjs`), Node 20.19.5, Chromium 1243 from the Playwright cache.

## Verdict

Dark and light SVG export works. Decision 11 stays on SVG pairs. No PNG fallback is needed.

## How export works

Archify has no CLI export command. Export exists only in the HTML viewer (`#btn-export` menu). The menu has `data-format="svg-light"` and `data-format="svg-dark"` items. Each one downloads a single-theme SVG (`serializeSvg(1, { theme })` in the generated HTML). The `svg` item (Auto) produces one SVG with a `prefers-color-scheme` media query. That variant does not fit `<picture>` with two files.

`scripts/dev/export-diagrams.sh` does this in three steps:

1. Run `finalize <type> <candidate> <tmp>.html --quality showcase` with `ARCHIFY_CHROME` set. Without Chrome set, `finalize` exits 2 (browser-check `skipped`).
2. Open the HTML in headless Chromium through `playwright-core`. Click `#btn-export`, then `svg-light`, then again and `svg-dark`.
3. Copy the two downloads to `assets/<name>-light.svg` and `assets/<name>-dark.svg`.

Exact commands (run from the repo root):

```bash
PLAYWRIGHT_CORE=/path/to/node_modules/playwright-core \
  scripts/dev/export-diagrams.sh test/fixtures/probe.workflow.json probe
```

The script takes an optional third argument, the archify type (default `workflow`). It reads `ARCHIFY_BIN`, `PLAYWRIGHT_CORE` (default `$(npm root -g)/playwright-core`) and `CHROME` (default newest `~/.cache/ms-playwright/chromium-*/chrome-linux64/chrome`). The script is dev only. It needs `playwright-core`, which this repo does not ship.

## Results for the probe fixture

| File | Bytes | `<script` | External refs |
|---|---|---|---|
| `probe-light.svg` | 139568 | 0 | none |
| `probe-dark.svg` | 139587 | 0 | none |

- Self-contained: yes. The fonts are embedded as `src: url(data:font/woff2...)` in 3 `@font-face` rules. There is no `@import`, `<link>`, `<image>`, `xlink:href`, or `url(http...)`. About 139 KB of each file is the embedded font data, so every diagram costs at least that.
- The strings `http://www.w3.org/2000/svg` (xmlns) and two JetBrains Mono license URLs appear in comments. A bare `grep http` hits them. Use the precise grep below.
- Light and dark differ: yes, byte-different (19 bytes apart). Both files carry the variable sets for all themes. The root `<svg>` has `data-theme="light"` or `"dark"` and a locked `:root, svg { ... }` block selects one. I rendered both with headless Chromium (`--screenshot`). The light file shows a light grey background with pastel nodes. The dark file shows a navy background with dark nodes.
- Not checked: rendering on github.com through `<img>` in `<picture>`. T6 panel-cdo owns that check.

## Test commands (AC5 shape)

```bash
f=assets/probe-light.svg; g=assets/probe-dark.svg
test -s "$f" && test -s "$g" && ! cmp -s "$f" "$g"
! grep -q '<script' "$f" "$g"
! grep -qE '@import|url\(["'"'"']?https?:|href="https?:|src="https?:|<link ' "$f" "$g"
```

Negative check: inserting `<script>1</script>` before `<svg` in a copy of the light file made `grep -c '<script'` print 1, so the script assertion fires.

## Concerns for later tasks

- The SVG size floor (~139 KB) comes from the embedded fonts. Eight assets give about 1.1 MB.
- The generated HTML sets `diagram_type` per file. T5 must pass the type (`workflow`, `lifecycle`, `sequence`, `architecture`) as the third script argument.
- `finalize` with `--quality showcase` passed on this 4-node fixture on the first draft.
