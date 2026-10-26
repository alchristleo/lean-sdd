# Plan: lean-sdd open-source release

Spec: `docs/superpowers/specs/2026-10-26-lean-sdd-oss-design.md` (approved 2026-10-26).
Sources to port (read only): `~/.claude/skills/lean-sdd/`, `~/.claude/agents/*.md` (the 10 listed in the
spec), `~/.claude/scripts/{install-git-hooks,pr-checks-wait,pr-merge,review-pkg,sdd-log,sdd-metrics}.sh`,
`~/.claude/scripts/git-hooks/commit-msg`, `~/.claude/scripts/statusline.py`, `~/.claude/hooks/usage-guard.py`,
`~/.claude/skills/asd-ste100/`, `~/.claude/skills/archify/` (tool, not shipped).

## Parallel group 1 (settling prototypes, no shared files)

### T1 Plugin prototype: settles Decisions 2 and 14
- agent: sdd-implementer (runs Claude Code plugin tooling)
- depends-on: none
- files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `hooks/hooks.json`,
  `test/install-smoke.sh`, `docs/superpowers/t1-findings.md`, plus throwaway probe files under `test/fixtures/probe-plugin/`.
- Work: build a minimal probe plugin (1 skill whose body prints `${CLAUDE_PLUGIN_ROOT}`, 1 agent, 1 script,
  1 hook) and install it under a temp `CLAUDE_CONFIG_DIR`. Record answers, each with the command and its output:
  1. Is `${CLAUDE_PLUGIN_ROOT}` substituted in skill and agent bodies? In `hooks.json` commands?
  2. Exec bit kept on scripts in the plugin cache?
  3. Name a plugin agent needs as `subagent_type` (`lean-sdd:<agent>` or bare)? Check via `claude -p` with
     the agent tool, or say INCONCLUSIVE with what was tried.
  4. Does `dependencies` on `superpowers@<its marketplace>` with `allowCrossMarketplaceDependenciesOn` install and load?
  5. Can one command add the marketplace and install? Does `claude plugin details --json` exist?
  6. Does an isolated `CLAUDE_CONFIG_DIR` keep the user's real config untouched?
- Real manifests: `plugin.json` name `lean-sdd`, version `0.1.0`, MIT, description from spec Decision 1;
  `marketplace.json` name `lean-sdd`, one entry, source `./`; `hooks.json` registers
  `"${CLAUDE_PLUGIN_ROOT}"/hooks/usage-guard.py` on UserPromptSubmit and PostToolUse (shape per finding 1).
- `test/install-smoke.sh`: AC2 + AC12 checks (spec), local path, temp `CLAUDE_CONFIG_DIR`, cleans up.
  Runs red until T4 lands the skill/agents; that is expected.
- Tests: `claude plugin validate --strict .` exits 0 (AC1). `test/install-smoke.sh` runs to the assertion
  step (not a usage error) and fails only on missing skill/agent counts.
- Constraint: never touch the real `~/.claude`. Remove probe fixtures before commit; keep findings doc.

### T2 Archify export prototype: settles Decision 11
- agent: sdd-implementer (runs node tooling)
- depends-on: none
- files: `docs/superpowers/t2-findings.md`, `scripts/dev/export-diagrams.sh` (dev only, not shipped in
  the plugin's runtime paths), `test/fixtures/probe.workflow.json`.
- Work: with `~/.claude/skills/archify/bin/archify.mjs`, finalize one tiny workflow candidate, export SVG in
  light and dark theme. Record: exact export commands, whether each SVG is self-contained (no external
  fonts or scripts; GitHub strips `<script>` and blocks external refs in `<img>` SVG), byte sizes, whether
  light and dark differ. If dark SVG export is impossible, try PNG pairs and record it.
- `export-diagrams.sh <candidate.json> <name>` writes `assets/<name>-light.<ext>` and `assets/<name>-dark.<ext>`.
- Tests: running the script on the fixture yields 2 non-empty, byte-different files with no `<script` and
  no `http` font/stylesheet ref (grep).

### T3 Comparison research: fills Decision 13
- agent: sdd-implementer (web research)
- depends-on: none
- files: `docs/comparison-research.md`
- Work: for obra/superpowers, github/spec-kit and plain Claude Code (no workflow skill), answer each
  feature row in spec Decision 13 as yes / no / partial with a URL to the exact doc or file, read today.
  lean-sdd column cites `SKILL.md` lines from `~/.claude/skills/lean-sdd/SKILL.md`. Add the Trade-offs list
  (≥ 4 cons, each sourced). Unanswerable cell → `unverified` + what was tried.
- Constraint: facts only. No cost, speed or quality claims. Quote the doc sentence behind each "no".
- Tests: file has 4 tool columns, ≥ 8 rows, every non-lean-sdd cell has a URL, check date line present.

## Group 2 (after T1)

### T4 Port and generalize skill, agents, scripts, hook
- agent: sdd-implementer
- depends-on: T1 (path shape, agent naming)
- files: `skills/lean-sdd/{SKILL.md,CHANGELOG.md}`, `skills/asd-ste100/**` (vendored as-is with LICENSE),
  `agents/*.md` (10), `scripts/*.sh` (6), `scripts/git-hooks/commit-msg`, `hooks/usage-guard.py`,
  `scripts/statusline-cache.py`, `test/check.sh` (subcommand `guard` only; T6 adds the rest).
- Work: copy, then apply spec Decisions 2 (per T1 findings), 4 (exact rewrites listed), 5 (step 0 runs the
  trailer hook only when the user opted in; README says how), 6 (`statusline-cache.py` = cache-writing part
  of `statusline.py`, no badge/plugin globbing; state path `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/state`),
  8 (one CHANGELOG header line), 9 (no GUIDE.md). Scripts call siblings via `$(dirname "$0")`.
  Agent names in SKILL.md per T1 finding 3. The STE lint path in the implementer agents points at the bundled skill.
- Constraint: Decision 4 changes wording only. Every rule keeps its meaning (AC15). No other edits.
- Tests: AC3, AC4 commands exit 0 here and their positive controls hit on the originals; AC10
  `shellcheck` clean; AC11 `test/check.sh guard` prints `USAGE GUARD` from a 96% sample, prints nothing
  at 10%; AC1 `claude plugin validate --strict .`; `test/install-smoke.sh` passes (AC2, AC12).

## Group 3 (after T2, T4)

### T5 Four diagrams
- agent: sdd-implementer
- depends-on: T2 (export method), T4 (final agent names and file layout)
- files: `docs/diagrams/{workflow,lifecycle,sequence,architecture}.json`, `assets/*-{light,dark}.*` (8).
- Content (from the ported SKILL.md, not invented):
  - workflow: T triage → 0 → 1 → (2a, optional) → 2 → 3 [spec gate] → 4 → 5 → 6 → 7 → 8 [merge gate] → 9; Small exits after T.
  - lifecycle: one task: planned → building → review → fix (≤ 2 rounds) → done | blocked.
  - sequence: coordinator ↔ implementer, reviewer, panel seats, spec-converge; the coordinator reads reports, not diffs.
  - architecture: what the plugin installs (skill, agents, scripts, hook, status-line cache) and who calls what.
- Each candidate passes archify `finalize --quality showcase`; exports via `scripts/dev/export-diagrams.sh`.
- Tests: 8 files exist, non-empty, pairs differ, no `<script`/external refs (same grep as T2).

## Group 4 (after T3, T5)

### T6 README, notices, checks
- agent: sdd-implementer
- depends-on: T3, T5
- files: `README.md`, `LICENSE` (MIT, copyright alchristleo 2026), `THIRD_PARTY_NOTICES.md` (asd-ste100 MIT
  text + Dustin Yuchen Teng; archify credit tt-a1i, diagrams made with it), `test/check.sh` (add `readme`,
  `hero`, `compare`, `install` subcommands).
- Layout: spec Decisions 1, 10, 13, 14 exactly. Install block = the one-liner (or the single command if T1
  found one), then `/plugin` in-session variant, then needed-when prerequisites table (superpowers, gh at
  merge only, status line for the guard, browser tool for panel-cdo only). Comparison table from
  `docs/comparison-research.md` with `unverified` rows dropped. Proof = 4 CHANGELOG lines with line refs.
  Field-notes `<details>` in Proof from `docs/field-notes.md` (spec Decision 15). Origin section links github.com/alchristleo/agentic-warden. Small task note: "nothing happens, by design".
- Constraint: every number or claim traces to the CHANGELOG, SKILL.md, or the research file (AC13).
  No badges, no emoji, ≤ 3 alerts, no cost claims (AC7, AC8).
- Tests: AC5, AC6, AC7, AC8, AC9, AC16, AC18, AC19 commands exit 0.

## Step 7 panel briefs (for the coordinator)
- panel-correctness (opus, trust boundary): AC15, plus hook/script behavior.
- panel-security (opus): hook input handling, script quoting, trailer hook opt-in, `pr-merge.sh` head check.
- panel-cdo: AC13, AC14, AC16 (cells vs sources), AC19 (values vs sdd-metrics). Reader + reference bar from spec AC14. GitHub rendering
  check: push to a private scratch repo only on owner's yes, else render locally and say so.
- panel-design: skip unless new non-test code ≥ ~300 lines (mostly ported docs).

## Backlog
- Measured A/B vs superpowers (unlocks a cost claim).
- GitHub Pages with interactive archify HTML; animated trace GIF; demo video; recorded first run.
- Preflight script (superpowers, gh auth, fresh usage cache, hook registered).
- Eval suite (`claude plugin eval`), CONTRIBUTING, launch posts (topics, superpowers community, blog, Discord).
- Day-30 success thresholds (CEO paper).
- install-smoke: two cached versions, assert `sort -V` picks the higher; README wording "highest version number".
- Plugin icon (validate ICON warning).
- Sequence diagram: trim empty lane space under the last message.
- Upgrade archify 3.0.1 -> 3.2.0 and re-export (owner call).

## Ledger
USAGE start 12
PLAN 6 tasks, group1 T1 T2 T3 parallel
COORD spec Decision 15 + AC19 field notes, owner request
T2 done 31a0fa0 sdd-implementer SVG pairs ok, 139KB each embedded fonts, export via playwright-core
T3 done c227a8a sdd-implementer 12 rows 5 cons, quotes via WebFetch summaries, spec-kit agent count conflict
T3 fix c227a8a sdd-reviewer fix-needed worktree cell, header claim, fabricated quote marks
T1 done 38dc789 sdd-implementer shape A holds, agents lean-sdd:<name>, single-command install exists, superpowers dep needs official marketplace
T2 review approve 31a0fa0 sdd-reviewer should: AC5 checks into script (folded into T5), nits: playwright-core path msg
T1 fix 38dc789 sdd-reviewer fix-needed findings lack commands, smoke checks vacuous on missing scripts/hook
T3 fix 51af2e9 sdd-reviewer-lite fix-needed header claims spot-check done
T3 coord 61555a4 header wording matches Notes (spot-check scope)
T1 fix 4b319e2 sdd-reviewer-lite fix-needed findings commands elided, hook evidence no command
T3 review fail 61555a4 sdd-reviewer-lite coord header claims 10 confirmed with no repo source; past 2-round cap
T3 coord 29e2c9c header restates Notes scope only (owner allowed past cap)
T1 review fail bd11d7c sdd-reviewer-lite findings doc not self-contained (env exports, dep copies); past cap
T3 review fail 29e2c9c sdd-reviewer-lite header line 3 scope vs Notes subset; past cap
COORD retro: review-pkg diff incomplete twice (T1 4b319e2-bd11d7c, T1 38dc789 pkg stale)
DISMISSED T1 bd11d7c + T3 29e2c9c remaining doc-polish findings, owner accepted as-is (internal prototype record; AC16 re-verifies comparison)
T1 done bd11d7c sdd-implementer merged (owner accepted)
T3 done 29e2c9c sdd-implementer merged (owner accepted)
MERGE group1 aa0331d validate strict ok, install-smoke red as expected until T4
T4 done 948ce56 sdd-implementer smoke 8/8, guard ok, AC3/4 clean; removed vendored asd-ste100 README; trailer opt-in mechanism undefined
T4 review approve 948ce56 sdd-reviewer nits: opt-in trigger, role-name note, -buildvcs Go example, notices README omitted
T4 coord 7fe5edb opt-in trigger, role-name note, neutral build-flag example
T4 review approve 5b5ce5a sdd-reviewer-lite coord fixes ok; nit: Decision 5 wording vs opt-in trigger
T5 done 432f5cf sdd-implementer 4 diagrams finalize ok, 8 assets ~150KB, snake workflow layout, lifecycle/sequence not eyeballed
T5 review approve 432f5cf sdd-reviewer nits: arch missing statusline writer node, lifecycle edge crossing, dead cards (to panel)
T6 done f651c8d sdd-implementer README + checks all green, 8 mutation proofs; statusline path pins version; archify upstream Apache-2.0 vs local MIT
T6 fix f651c8d sdd-reviewer fix-needed statusline path pins version, archify license wording, plain=1 anchors
COORD spec AC2 wording single-command install (T6 review nit)
T6 done dcd76ea sdd-reviewer-lite approve fix round; nits to Backlog
PANEL design skipped new non-test code < 300 lines (ported scripts, vendored lint)
PANEL security 82eb17f must=1 should=3 nit=2
PANEL correctness 82eb17f must=0 should=2 nit=6
SEAT correctness pass 82eb17f AC1
SEAT correctness pass 82eb17f AC2
SEAT correctness pass 82eb17f AC3
SEAT correctness pass 82eb17f AC4
SEAT correctness pass 82eb17f AC10
SEAT correctness pass 82eb17f AC11
SEAT correctness pass 82eb17f AC12
SEAT correctness pass 82eb17f AC15
PANEL cdo 82eb17f must=0 should=5 nit=4
SEAT cdo pass 82eb17f AC13
SEAT cdo fail 82eb17f AC14 small diagram text, arch writer node, scorecard tone
SEAT cdo pass 82eb17f AC16
SEAT cdo fail 82eb17f AC19 releases row phase 2 only
TRIAGE fixed=19 dismissed=4 backlog=1
DISMISSED lifecycle crossing, diagram cards, sequence lane space (backlog), statusline code-block scroll; owner approved
COORD owner: rewrite author email to noreply before push; scrub /home/ paths in docs, AC3 extended
