# Reviewer convergence + CI/hook trust boundary

## Goal

Reduce fix rounds. A reviewer no longer blocks a task for bugs in code the task did not change, a finding lists every place the same mistake appears in the change, and a re-review gives a verdict on the earlier findings instead of finding new nits. Also add CI workflows, release/install scripts, git hooks and agent hooks/permissions to the scope-gate trust-boundary list.

Source: feed-watch digest 2026-11-10, post B ("How the Claude Code team does code review"). Local evidence: `docs/superpowers/plans/2026-10-26-oss-release.md` retro `fix_rounds=5` for 6 tasks; `docs/superpowers/plans/2026-11-07-lite-edition.md:72` sent a pre-existing finding to the Backlog by hand.

## Non-goals

- PR template headings and rule pruning (cut by the owner).
- REVIEW.md support and a mod ledger band (Backlog).
- No change to `sdd-metrics.sh`, `sdd-log.sh` or the ledger formats.
- No version bump and no merge while lite 0.1.6 is in directory review (owner decision). The merge and the bump to 0.1.7 come after the review result.

## Decisions (owner, 2026-11-10)

1. Untouched-line problems go on a separate output line, `PRE-EXISTING: file:line — problem — fix`, not a fourth severity tag. They never set VERDICT to fix-needed, and the coordinator moves them to the Backlog. Rejected shape: `[pre-existing]` inside FINDINGS (needs a fourth PANEL count).
2. Same-mistake sites: an optional `(also: file:line, …)` before the fix, only when the same mistake appears elsewhere in the change. Rejected: a mandatory `class:` field.
3. Remove the stale lite check AC8 ("full edition unchanged") from `test/check.sh`. AC2 (lite equals a fresh build) already covers lite drift.
4. Add a small behavior eval: one fixture repo, reviewer runs with the old and new agent text.
5. Lite edition: regenerated with `scripts/dev/build-lite.py` and the result committed. No line anchored in `scripts/dev/lite-edits.md` is edited; new agent text goes in the `## Output` section only, away from the anchored first paragraph.
6. `PRE-EXISTING` items count in `TRIAGE … backlog=<n>`. No ledger or metrics change.
7. Eval: 3 runs with the new `sdd-reviewer.md` must all pass; 1 baseline run with the agent text at `bd62e10` (pinned sha, not `main`, so it survives the merge). The script strips frontmatter, pins `--model sonnet`, runs `claude -p --bare` in a temp cwd, and builds the package with the real `review-pkg.sh` in a fixture repo that has the trailer hook installed. It needs login, so it never runs inside `test/check.sh`.
8. Scope of agent edits: the 6 reviewer/panel agents only. `sdd-implementer*`, `spec-converge` and `exec-seat` are unchanged on purpose. All re-reviews already use `sdd-reviewer-lite` (SKILL.md step 6), so the re-review mode lives there only.
9. AC8 removal reason: with the merge held, `main` differs from the branch by design, so a "full edition equals main" check can't pass on any feature branch. The check.sh header comment listing the lite ACs is updated with it.

## Design

- `agents/sdd-reviewer.md`, `agents/sdd-reviewer-lite.md`, `agents/panel-{correctness,design,security,cdo}.md`: Output section gets the `PRE-EXISTING:` line (omit if none) and the `(also: …)` rule on the FINDINGS format.
- `agents/sdd-reviewer-lite.md`: re-review mode. When the brief lists earlier findings, output one `PRIOR: <finding> — fixed|open` line each, and report new findings only on lines the fix diff changed.
- `skills/lean-sdd/SKILL.md`: step 1 trust list adds the four items; step 6 re-review brief carries the earlier findings, and `PRE-EXISTING` lines go to the Backlog with no fix round; step 7 triage says the same for panel seats.
- `test/check.sh`: AC8 block removed. New `test/eval-reviewer.sh <agent.md>` (dev only, not shipped in lite): builds the fixture repo, writes a review package, runs `claude -p` with the agent text as system prompt, and prints the output.
- `skills/lean-sdd/CHANGELOG.md`: one line with the evidence above and the eval result.

## Acceptance criteria

ACs 1–5 run on both editions: `for R in . plugin-lite; do … done` with each path prefixed by `$R/`.

1. All 6 reviewer/panel agents define the `PRE-EXISTING:` output line. Check: `for R in . plugin-lite; do for a in sdd-reviewer sdd-reviewer-lite panel-correctness panel-design panel-security panel-cdo; do grep -q '^PRE-EXISTING:' "$R/agents/$a.md" || echo "MISS $R/$a"; done; done` prints nothing.
2. All 6 FINDINGS format lines carry the optional also-list. Check: `for R in . plugin-lite; do for a in sdd-reviewer sdd-reviewer-lite panel-correctness panel-design panel-security panel-cdo; do grep -q 'also: file:line' "$R/agents/$a.md" || echo "MISS $R/$a"; done; done` prints nothing.
3. Re-review mode exists in the lite reviewer and step 6 tells the coordinator to pass the earlier findings. Check: `for R in . plugin-lite; do grep -q '^PRIOR:' $R/agents/sdd-reviewer-lite.md && sed -n '/^## 6\./,/^## 7\./p' $R/skills/lean-sdd/SKILL.md | grep -q 'earlier findings' || echo "MISS $R"; done` prints nothing.
4. Steps 6 and 7 send `PRE-EXISTING` lines to the Backlog. Check: `for R in . plugin-lite; do for s in 6 7; do sed -n "/^## $s\./,/^## $((s+1))\./p" $R/skills/lean-sdd/SKILL.md | grep -q 'PRE-EXISTING.*Backlog' || echo "MISS $R step $s"; done; done` prints nothing.
5. The step 1 trust list names the four new items. Check: `for R in . plugin-lite; do sed -n '/^## 1\./,/^## 2a/p' $R/skills/lean-sdd/SKILL.md | grep -q 'CI workflows, release and install scripts, git hooks, agent hooks or permissions' || echo "MISS $R"; done` prints nothing.
6. Lite edition stays submittable: every lite check passes (including the directory-profile validation and versions equal), AC8 is gone. Check: `test/check.sh lite; echo rc=$?` shows `rc=0`, no `FAIL` line and no `AC8` line; `grep -n 'AC8' test/check.sh` prints nothing.
7. Other check modes still pass. Check: `for m in readme fieldnotes; do test/check.sh $m || echo "FAIL $m"; done` prints no `FAIL`.
8. Eval: with the new `sdd-reviewer.md`, the fixture's old bug appears on a `PRE-EXISTING:` line and not in FINDINGS, in 3 of 3 runs. The baseline run uses the agent text at `bd62e10` and is recorded as is. Check: `for i in 1 2 3; do test/eval-reviewer.sh agents/sdd-reviewer.md; done` prints `PASS` 3 times (the script prints `PASS` when the PRE-EXISTING section, same-line or heading form, holds an `old.py` item and no finding is located at `old.py`; findings located in new code may cite `old.py` as the cause). Rule changed after the first fixture-2 results, owner decision 2026-11-10; the earlier rule's runs are in the ledger; `test/eval-reviewer.sh --base bd62e10` output is pasted into the ledger.
9. CHANGELOG line added. Check: `grep -q '^2026-11-10 ' skills/lean-sdd/CHANGELOG.md && echo ok` prints `ok`.
10. The re-review behavior reads clearly to a coordinator who did not write it. `check: seat panel-correctness`.

## Status (converged 2026-11-10)

Base `main` (bd62e10), branch HEAD ddcd539. No earlier status table in this spec.

| # | Criterion | Verdict | Evidence |
|---|-----------|---------|----------|
| 1 | PRE-EXISTING line in 6 agents x 2 editions | VERIFIED | AC1 loop printed nothing |
| 2 | also-list in 6 FINDINGS formats x 2 editions | VERIFIED | AC2 loop printed nothing |
| 3 | Re-review mode (PRIOR) and step 6 "earlier findings" | VERIFIED | AC3 loop printed nothing |
| 4 | Steps 6 and 7 send PRE-EXISTING to Backlog | VERIFIED | AC4 loop printed nothing |
| 5 | Step 1 trust list names four new items | VERIFIED | AC5 loop printed nothing |
| 6 | Lite check passes, AC8 gone | VERIFIED | `test/check.sh lite` rc=0, 0 FAIL, 0 AC8 lines; `grep -n AC8 test/check.sh` empty |
| 7 | readme and fieldnotes modes pass | VERIFIED | loop printed no `FAIL` |
| 8 | Eval: new reviewer 3/3 PASS, baseline recorded | VERIFIED (ledger) | Not re-run (needs login, costs usage; deviation by instruction). Ledger: `COORD eval rerun 1aa8f73: baseline FAIL, new sdd-reviewer 3/3 PASS`; `git diff 1aa8f73 HEAD -- agents/sdd-reviewer.md` empty; `test/eval-reviewer.sh --selftest` all ok |
| 9 | CHANGELOG line | VERIFIED | `grep ... && echo ok` printed `ok` |
| 10 | Re-review wording reads clearly (`check: seat panel-correctness`) | INCONCLUSIVE | Seat failed twice (`SEAT correctness fail aa19160`, `SEAT correctness fail 1aa8f73`); wording changed after (5266903, 2131ce0, 35fc4ce) with no seat pass. Owner checks at merge gate; pending `SEAT owner pass <ref> AC10` |

Deviations: AC8 judged from the ledger, not re-run. AC10 not seat-verified; owner decision to judge at the merge gate.
