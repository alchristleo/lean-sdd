# lean-sdd-lite: a Markdown-only edition for the plugin directory

Date: 2026-11-07. Branch: `lite-edition`.

## Goal

Ship `lean-sdd-lite`, a second plugin in this repo that the Claude Code plugin directory accepts
from an unverified organization. The directory refuses every file that is not Markdown, text,
JSON, YAML or a PNG/JPEG/GIF/WebP/ICO image, and it scans only the plugin's source folder
(probe `alchristleo/lean-sdd-probe` 102eba1: "Fetched and unpacked: 3 files", "Meets directory
policy"). The full `lean-sdd` plugin stays as it is on the repo's own marketplace.

## Non-goals

- No change to the full edition's skills, agents, scripts or hooks.
- Lite drops: the commit-trailer hook, the usage guard and status line, `ste-lint.py`, the
  ledger format lint (`sdd-log.sh`) and the deterministic metrics line (`sdd-metrics.sh`).
- No CI job for the sync check in this milestone (Backlog).
- No support for having both editions on at once: both ship skills named `lean-sdd` and
  `asd-ste100`. The README line "install one" is the whole guard.
- The full install also carries `plugin-lite/` (source `./` copies the whole repo). It is not
  under `skills/` or `agents/`, so nothing loads twice; the extra files are accepted.
- Lite has no ledger lint: a malformed ledger line goes unnoticed. Accepted loss.

## Decisions

1. **Layout:** `plugin-lite/` at the repo root, a generated folder that is committed.
   `marketplace.json` lists two plugins: `lean-sdd` (source `./`) and `lean-sdd-lite`
   (source `./plugin-lite`). The directory form asks which plugin to submit (owner, 2026-11-07).
   Alternative rejected: a separate repo (two repos to release, nothing gained, because the probe
   showed the scan stays inside the source folder).
   Rollback: the probe was a one-plugin repo. If the directory rejects `lean-sdd-lite` from this
   two-entry layout (AC10), the rejected alternative, a separate repo built by the same script,
   becomes the plan. `LICENSE` inside `plugin-lite/` is allowed: the refusal text says "A license,
   a readme, `.gitignore`, and the plugin's icon can stay".
2. **Sync:** one source of truth. `scripts/dev/build-lite.py` copies an allowlist of full files
   into `plugin-lite/` and applies `scripts/dev/lite-edits.md`. That file holds anchor/replacement
   pairs per file. The build fails and names the file and anchor when an anchor is not found
   exactly once. The owner chose "generator + markers". This moves the markers out of the full
   files: Claude reads SKILL.md as raw Markdown, so lite text inside HTML comments would reach
   the full edition's model. Shapes considered: inline HTML-comment markers (rejected for that
   reason), anchor/replacement file (chosen).
3. **Agent names:** lite agents are dispatched as `lean-sdd-lite:<name>`. The build rewrites
   only `lean-sdd:<x>` where `<x>` is one of the 10 agent names, `<agent>` or `<name>`. Prose that
   says "`lean-sdd:` agents" (SKILL.md line 8) becomes "`lean-sdd-lite:` agents" through
   `lite-edits.md`. The output never holds `lean-sdd-lite:lean-sdd-lite:`.
3a. **Lite manifest:** the build writes `plugin-lite/.claude-plugin/plugin.json` from the full one
   with `name` = `lean-sdd-lite`, a lite `description`, and `version`, `author`, `license`,
   `homepage`, `repository` copied.
4. **Script steps become inline commands** that work on `gh` 2.4.0 (Ubuntu 22.04's package,
   which has no `gh pr checks --watch` and no `gh pr merge --match-head-commit`):
   - review package: `git log` / `git diff --stat` / `git diff` for `<base>..HEAD` excluding
     `docs/superpowers`, written to
     `$(git rev-parse --path-format=absolute --git-common-dir)/review-pkg-<base>-<head>.md`
     (absolute, so a worktree or a later `cd` does not break it; git ≥ 2.31). No trailer section.
     An empty diff still writes the file, with empty sections.
   - ledger: append one line under the last `## Ledger` heading with the Edit tool. The format
     list moves into SKILL.md as text, with no lint.
   - metrics: Claude counts the ledger lines by type for the retro line.
   - PR checks: wait 15 s, then re-run `gh pr checks <pr>` every 20 s until no line is pending,
     queued or in_progress, for 20 minutes at most. `gh pr checks` exits non-zero when a check
     fails, so the step reads its output, not its exit code. No check lines listed, or a gh error:
     stop and report, do not loop. Record the head sha from
     `gh pr view <pr> --json commits -q '.commits[-1].oid'` (the call `pr-checks-wait.sh` makes on
     gh 2.4.0).
   - merge: compare `git ls-remote origin refs/heads/<branch>` with the recorded sha, then
     `gh pr merge <pr> --merge`, then `git fetch` and `git log --oneline origin/<base>..origin/<branch>`
     must be empty.
5. **Trailers:** lite agents say "commit with a conventional message" and drop the hook and
   trailer-check lines. Claude Code's own attribution still applies.
6. **asd-ste100** ships in lite without `scripts/ste-lint.py`. Its two linter mentions become
   manual-check wording through `lite-edits.md`.
7. **Version:** lite `plugin.json` copies `version` from the full `plugin.json`. Both go to 0.1.6.
   A lite-only fix bumps both; accepted, one version line per repo is simpler to release.
   Release step (README "Releasing"): run `python3 -I scripts/dev/build-lite.py` and
   `test/check.sh lite` before every version bump. The sync check is local only (no CI).
8. Lite ships `plugin-lite/README.md` (short: what it is, install line, what it drops), so the
   validator's install-line check passes.

## Design

```
.claude-plugin/marketplace.json   + lean-sdd-lite entry (source ./plugin-lite)
.claude-plugin/plugin.json        version 0.1.6
scripts/dev/build-lite.py         stdlib Python, run as python3 -I; builds plugin-lite/ from scratch
scripts/dev/lite-edits.md         ## <path> / <<<< anchor / ==== replacement / >>>> blocks
plugin-lite/                      generated, committed:
  .claude-plugin/{plugin.json,icon.png}  README.md
  skills/lean-sdd/SKILL.md        (no CHANGELOG.md)
  skills/asd-ste100/{SKILL.md,LICENSE,examples/*.md,references/*.md}
  agents/*.md                     (10)
test/check.sh lite                ACs 1-6, 8-9, 12
test/install-smoke.sh             + lite install checks (AC7)
README.md                         Install section: both editions, what lite drops
```

## Acceptance criteria

1. Every file under `plugin-lite/` is `.md`, `.json`, `.png` or `LICENSE`. Check: `test/check.sh lite`.
2. `plugin-lite/` equals a fresh build: run `python3 -I scripts/dev/build-lite.py`, then
   `git status --porcelain plugin-lite` is empty. Check: `test/check.sh lite`.
3. A missing anchor fails the build: with a copy of `lite-edits.md` whose anchor text is changed,
   the build exits non-zero and prints the file path and the anchor's first line. Check: `test/check.sh lite`.
4. No reference to a file lite does not ship: `grep -rnE 'CLAUDE_PLUGIN_ROOT|scripts/|hooks/|commit-msg|claude-trailer|usage\.json|USAGE GUARD|ste-lint|statusline' plugin-lite`
   has 0 hits. Check: `test/check.sh lite`.
5. Same parts: lite has 2 skills and 10 agents; each agent's `name`, `model` and `effort` match
   the full agent's. Lite `plugin.json` `name` is `lean-sdd-lite`. 0 `lean-sdd:` hits and 0
   `lean-sdd-lite:lean-sdd-lite:` hits in lite; every `lean-sdd-lite:<x>` in lite SKILL.md is an
   agent file name, `<agent>` or `<name>`. Check: `test/check.sh lite`.
6. `claude plugin validate --profile directory plugin-lite` exits 0 and prints no `❯` advisory
   line; `claude plugin validate .` still exits 0. (`validate .` checks only the root plugin; the
   lite marketplace entry is covered by AC7.) Check: `test/check.sh lite`.
7. A clean `claude plugin install --marketplace <repo> lean-sdd-lite` exposes 2 skills, 10 agents,
   no `hooks/` and no `scripts/` dir. The full install's checks keep passing. Check: `test/install-smoke.sh`.
8. Full edition unchanged: `git diff main -- skills agents scripts hooks ':!scripts/dev'` is empty.
   Check: `test/check.sh lite`.
9. The lite review-package command, extracted from lite SKILL.md's fenced block and run in a temp repo
   with 2 commits, writes a file holding the commit subjects, a diffstat and the diff, and leaves
   out `docs/superpowers`, at an absolute path. Run once more from a subdirectory: same path.
   The lite PR commands use no `--watch` and no `--match-head-commit`, and the PR-checks step
   names a 20-minute limit and a stop on "no checks".
   Check: `test/check.sh lite`.
10. The directory accepts `lean-sdd-lite` at the branch head: the check shows "Meets directory
    policy" and "Security scan passed". `check: owner at gate`.
11. The README tells a directory visitor which edition to install and what lite drops, in the
    house voice. `check: seat cdo`.
12. Lite `plugin.json` version equals full `plugin.json` version (0.1.6). Check: `test/check.sh lite`.

## Security notes

No new trust boundary. Lite runs the same `git`/`gh` commands the full scripts run, typed by
Claude instead of read from a script.

## Status (converged 2026-11-07)

Branch head 552c32b, base main. No earlier status table.

| # | Criterion | Verdict | Evidence |
|---|-----------|---------|----------|
| 1 | Only .md/.json/.png/LICENSE | VERIFIED | `test/check.sh lite`: `ok AC1 allowed file types only` |
| 2 | plugin-lite equals fresh build | VERIFIED | `test/check.sh lite`: `ok AC2 plugin-lite equals a fresh build` |
| 3 | Missing anchor fails build | VERIFIED | `test/check.sh lite`: `ok AC3 broken anchor fails and names path and anchor` |
| 4 | No reference to unshipped files | VERIFIED | `test/check.sh lite`: `ok AC4 ...` |
| 5 | Same parts, names, prefixes | VERIFIED | `test/check.sh lite`: `ok AC5 2 skills, 10 agents...` and `ok AC5 prefix checks` |
| 6 | directory validate 0, no advisory; `validate .` 0 | VERIFIED | `test/check.sh lite`: `ok AC6 directory profile passes with no advisory`, `ok AC6 validate . passes` |
| 7 | Clean install exposes 2 skills, 10 agents, no hooks/scripts | VERIFIED | `D=$(mktemp -d); git clone -q . "$D"; test/install-smoke.sh "$D"`: `ok lite: 2 skills`, `ok lite: 10 agents`, `ok lite: no hooks/ dir`, `ok lite: no scripts/ dir`; full-install checks ok |
| 8 | Full edition unchanged | VERIFIED | `git diff main -- skills agents scripts hooks ':!scripts/dev' \| wc -l` = 0; `ok AC8` |
| 9 | Review-package block and PR commands | VERIFIED | `test/check.sh lite`: both `ok AC9` lines |
| 10 | Directory accepts lean-sdd-lite | NOT VERIFIED (accepted) | Owner chose to merge before the directory resubmit result. Resubmit `lean-sdd-lite` from main after the merge. |
| 11 | README tells visitor which edition, in house voice | VERIFIED | Owner yes at the merge gate (`SEAT owner pass 0fe25a4 AC11`), after coord fix b672aca. |
| 12 | Lite version equals full version | VERIFIED | `test/check.sh lite`: `ok AC12 versions equal` |

Deviations: none. AC7 was run with the clone form given by the coordinator (`install-smoke.sh <clone>`), not bare `test/install-smoke.sh`.
Open findings: none. Two out-of-scope items went to Backlog (`COORD review approve 6ad3518`).
