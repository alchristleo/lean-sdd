# Plan: reviewer convergence + CI/hook trust boundary

Spec: `docs/superpowers/specs/2026-11-10-reviewer-convergence-design.md` (approved 2026-11-10).
Branch: `reviewer-convergence`. Base: `ec33714`. Merge held until the lite 0.1.6 directory review result (spec Non-goals).

T1 and T2 share no files and have no depends-on: **parallel group A**.

## T1. Agent output, SKILL steps 1/6/7, drop lite AC8, regenerate lite (agent: sdd-implementer-lite, depends-on: none)

Files: `agents/sdd-reviewer.md`, `agents/sdd-reviewer-lite.md`, `agents/panel-correctness.md`, `agents/panel-design.md`,
`agents/panel-security.md`, `agents/panel-cdo.md`, `skills/lean-sdd/SKILL.md`, `test/check.sh`, `plugin-lite/` (generated only).

Contract (spec Decisions 1, 2, 5, 6, 8, 9):
- In each of the 6 agents, edit only the `## Output` section:
  - FINDINGS format line becomes `` FINDINGS: one per line as `[must|should|nit] file:line — problem (also: file:line, …) — fix` ``, plus one sentence: the `(also: …)` part lists other places in the change with the same mistake, and is left out when there are none.
  - New line after FINDINGS (and after ACS where present): `` PRE-EXISTING: one per line as `file:line — problem — fix` `` for problems on lines the diff does not touch; they never make VERDICT fix-needed; omit if none.
- `agents/sdd-reviewer-lite.md` only, in `## Output`: `` PRIOR: one per line as `<earlier finding> — fixed|open` `` when the brief lists earlier findings (a re-review); in a re-review, new FINDINGS only on lines the fix diff changed.
- `skills/lean-sdd/SKILL.md`:
  - step 1 trust-boundary parenthesis: append `CI workflows, release and install scripts, git hooks, agent hooks or permissions` (this exact phrase).
  - step 6: the re-review brief lists the earlier findings (phrase `earlier findings`); a `PRE-EXISTING` line goes to the plan's Backlog with no fix round (one line containing `PRE-EXISTING` … `Backlog`).
  - step 7 triage: `PRE-EXISTING` lines from seats go to the Backlog, not the fix wave, and count in `TRIAGE … backlog=<n>` (one line containing `PRE-EXISTING` … `Backlog`).
- `test/check.sh`: delete the `# AC8` block (3 lines plus the verdict) and change the `lite` header comment from `(AC1-6, 8, 9, 12)` to `(AC1-6, 9, 12)`.
- Then `python3 -I scripts/dev/build-lite.py` and commit `plugin-lite/`.

Constraints: do not edit any line quoted as an anchor in `scripts/dev/lite-edits.md` (agents/sdd-reviewer.md: `(from review-pkg.sh)`, `, trailer check line in the package.`; agents/sdd-reviewer-lite.md: `nothing outside its scope changed, trailer check is ok.` and the `.git/claude-trailer` paragraph). No version bump. No other file.

Acceptance tests: spec AC1–AC7 commands, all green; `test/check.sh lite` shows `rc=0`.

## T2. Reviewer behavior eval script (agent: sdd-implementer, depends-on: none)

Files: `test/eval-reviewer.sh` (new), `test/fixtures/eval-reviewer/` (new, if fixture files are needed).

Interface: `test/eval-reviewer.sh <agent.md>` or `test/eval-reviewer.sh --base <sha>` (reads `agents/sdd-reviewer.md` at that sha via `git show`). Prints the reviewer output, then a last line `PASS` or `FAIL <reason>`. Exit 0 on PASS, 1 on FAIL, 2 on usage error.

Behavior (spec Decision 7):
- Builds a temp fixture git repo: commit 1 has a small module with an obvious old bug in file `old.py` (for example a function that divides without a zero check, used by a test); commit 2 (the "task") adds a correct, tested function in a different file `new.py` and touches nothing in `old.py`. Installs the real trailer hook (`scripts/install-git-hooks.sh "<trailer>"`) in the fixture so the package's trailer check reads `ok`.
- Runs the real `scripts/review-pkg.sh <commit1>` in the fixture to make the package.
- Strips YAML frontmatter from the agent file; runs `claude -p --bare --model sonnet --system-prompt "<body>" "<brief>"` with cwd = the fixture repo. Brief: package path + task text "Add new.py:<fn> with tests". Tools limited to what a reviewer needs (Read, Bash, Grep, Glob).
- PASS iff some `PRE-EXISTING:` line names `old.py` and no `[must|should|nit]` line names `old.py`.
- Never called from `test/check.sh` (needs login).

Acceptance tests:
- `bash -n test/eval-reviewer.sh`; usage error exits 2.
- `test/eval-reviewer.sh --base bd62e10` runs end to end and prints a verdict line (expected FAIL: old text has no PRE-EXISTING line). Paste its output into the report.
- Fixture check: the generated package's trailer section reads `ok` and its diff does not touch `old.py` (assert inside the script before calling claude; `FAIL fixture` otherwise).

## After group A (coordinator)

- Merge T1, T2 in plan order; run spec AC1–AC7.
- Spec AC8: `for i in 1 2 3; do test/eval-reviewer.sh agents/sdd-reviewer.md; done` → 3× PASS; baseline output to the ledger.
- Coord: `skills/lean-sdd/CHANGELOG.md` line `2026-11-10 agents/sdd-reviewer*.md + panel-*.md + SKILL.md 1/6/7: …` with the evidence from the spec and the eval numbers (spec AC9). Regenerate lite if needed (CHANGELOG is not copied to lite; check AC2).
- Milestone panel: panel-correctness only (prompt/docs change, < 300 lines non-test code, no trust boundary, no audience-facing change). It owns spec AC10.

## Backlog

- REVIEW.md: reviewers read a project REVIEW.md if present (digest 2026-11-10, post B).
- Mod ledger band for the full plugin (current task, fix rounds, usage) (digest 2026-11-10, post C).
- PR body headings Testing / Risk / How to revert (cut by owner 2026-11-10).
- Rule pruning on model change (cut by owner 2026-11-10).

## Ledger

USAGE start 16
PLAN ec33714 reviewer-convergence plan written, spec approved by owner
T1 review approve 749aeaf sdd-reviewer-lite AC1-7 green; should: PRIOR open has no stated VERDICT effect (owner call pending)
T2 coord f11a480 owner-requested fixture change: new.py calls old.py bug; baseline still FAIL, old reviewer names test_new.py not old.py
T1 coord d8c1813 owner rule: open earlier must/should blocks, open nit does not; lite regen, check lite 0 FAIL
T2 done f11a480 sdd-reviewer approve; parser and fixture checked with fake claude
MERGE 46daae0 T1+T2 merged; check lite 0 FAIL, readme+fieldnotes ok
