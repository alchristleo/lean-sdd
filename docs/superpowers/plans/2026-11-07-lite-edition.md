# Plan: lean-sdd-lite edition

Spec: `docs/superpowers/specs/2026-11-07-lite-edition-design.md` (approved 2026-11-07).
Branch: `lite-edition`. Base: `2568986`.

## T1. Generator, manifest, sync check (agent: sdd-implementer, depends-on: none)

Files: `scripts/dev/build-lite.py`, `scripts/dev/lite-edits.md` (format plus one real edit:
`skills/lean-sdd/SKILL.md` line 8 prose), `plugin-lite/` (generated), `.claude-plugin/marketplace.json`,
`.claude-plugin/plugin.json` (version 0.1.6), `test/check.sh` (new `lite` subcommand).

Interfaces:
- `python3 -I scripts/dev/build-lite.py [--edits <file>] [--out <dir>]` (defaults: `scripts/dev/lite-edits.md`,
  `plugin-lite`). Deletes and rebuilds the out dir. Exit 0 on success; exit 1 with
  `<path>: anchor not found exactly once: <first anchor line>` on a bad anchor.
- Copy allowlist: `skills/lean-sdd/SKILL.md`; `skills/asd-ste100/{SKILL.md,LICENSE}`,
  `skills/asd-ste100/{examples,references}/*.md`; `agents/*.md`; `.claude-plugin/icon.png`.
- Writes `plugin-lite/.claude-plugin/plugin.json` (spec D3a) and `plugin-lite/README.md` (spec D8).
- Prefix rewrite (spec D3): `lean-sdd:(<agent names>|<agent>|<name>)` → `lean-sdd-lite:\1`, applied after edits.
- `lite-edits.md` block format:
  ```
  ## skills/lean-sdd/SKILL.md
  <<<<
  exact full text
  ====
  lite text
  >>>>
  ```
- `marketplace.json`: second entry `lean-sdd-lite`, source `./plugin-lite`.

Acceptance tests (`test/check.sh lite`, each prints `ok`/`FAIL` like the other subcommands):
- AC1 allowed types only; AC2 fresh build leaves `git status --porcelain plugin-lite` empty;
  AC3 a temp edits copy with a broken anchor exits non-zero and prints path + anchor line;
  AC5 2 skills, 10 agents, frontmatter name/model/effort match, manifest name, prefix checks;
  AC6 `claude plugin validate --profile directory plugin-lite` rc 0 with no `❯` line, `validate .` rc 0;
  AC8 `git diff main -- skills agents scripts hooks ':!scripts/dev'` empty;
  AC12 versions equal.
- AC4 and AC9 checks are written in T1 too; they are expected to FAIL until T2 (say so in the report).

Constraints: stdlib only; run as `python3 -I`; shellcheck clean for check.sh; no change to full skills/agents.

## T2. Lite edits: inline script steps (agent: sdd-implementer, depends-on: T1)

Files: `scripts/dev/lite-edits.md`, regenerated `plugin-lite/`.

Work: add edit blocks so lite text follows spec D4, D5, D6:
- SKILL.md: step 0 (trailer hook, usage file and `USAGE GUARD`), step 5 ledger (format list moves in as text,
  Edit-tool append), step 6 review package (one fenced `bash` block, the exact command AC9 extracts),
  step 7 seat re-run package, step 8 PR checks and merge (gh 2.4.0-safe, 20-minute limit, stop on no checks,
  lost-commit check), step 9 metrics (count ledger lines) and workflow-lessons wording (no `scripts/`).
- agents: `sdd-implementer.md`, `sdd-implementer-lite.md` (commit line), `sdd-reviewer.md`,
  `sdd-reviewer-lite.md` (no trailer check, no `review-pkg.sh` name).
- asd-ste100 SKILL.md: 2 linter mentions → manual-check wording.
Acceptance: `test/check.sh lite` all `ok` (AC4, AC9 now pass); full edition untouched (AC8).
Constraints: house voice (active voice, one instruction per sentence, no semicolons); keep every other
SKILL.md rule intact; lite text must not mention files lite does not ship.

## T3. Install smoke and README (agent: sdd-implementer-lite, depends-on: T2)

Files: `test/install-smoke.sh`, `README.md`.
- install-smoke: after the full checks, install `lean-sdd-lite` from the same marketplace into the same temp
  config; check 2 skills, 10 agents, no `hooks/`, no `scripts/` in its installPath (AC7).
- README: Install section names both editions (lite = directory, Markdown only); lists what lite drops; says
  install one, not both; "Releasing" gets the rebuild + `test/check.sh lite` step (spec D7).
Acceptance: `test/install-smoke.sh` rc 0; `test/check.sh readme|hero|install|compare|fieldnotes` still ok.

## Backlog

- CI job running `test/check.sh lite` on push.
- Lite README visuals as PNG.

## Ledger
USAGE start 6%
PLAN 3 tasks, T1 -> T2 -> T3 serial
T1 review approve 06e93ca sdd-reviewer 1 nit: AC9 block must stay first review-pkg fence
T1 done 06e93ca sdd-implementer generator, plugin-lite, check.sh lite
T2 fix 0bd8cf6 sdd-reviewer fix-needed 2 must (trailer wording unconditional, wait head-moved before sha missing), 2 should, 2 nit
T2 review approve 10e0c24 sdd-reviewer-lite 1 nit (40-hex note sits in wait step, covered)
T2 done 10e0c24 sdd-implementer inline steps, test/check.sh lite 12 ok
