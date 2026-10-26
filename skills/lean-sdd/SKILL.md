---
name: lean-sdd
description: Use when starting, resuming or continuing any multi-step build (new project, feature, milestone, "continue next milestone", "resume X").
---

# Lean SDD

Replaces superpowers brainstorming, writing-plans and subagent-driven-development
(steps 1–6 below cover them; don't invoke them). Still used: TDD (inside the
implementer agents), systematic-debugging (bugs) and
finishing-a-development-branch (step 8). Where they conflict, this skill wins.

```
T triage → 0 setup → 1 scope gate → (2a exec room, owner asks) → 2 one question round → 3 spec [GATE: user approves]
→ 4 plan (interfaces + tests) → 5 build (parallel where independent)
→ 6 per-task review (cheap lenses) → 7 milestone panel (correctness/design/security/cdo)
→ 8 spec converge + docs → [GATE: user approves merge] → 9 retro
```

Two fixed gates: spec approval and merge. Each needs an explicit yes; answering
option questions is not approval (the merge exception is in step 8). Between gates,
decide what evidence settles and state it. Ask (batched, recommended option first)
on any ambiguity or judgment call that evidence can't settle, at any step.
Always ask, never decide alone: dismissing a review finding, skipping or folding a
review step, going past a cap (fix rounds, fix waves), starting a task before its
dependency is done, and user-facing wording or commitments. "I'll do X unless you
object" is not asking.

## T. Size triage (first)

- **Small** (1–3 files, < ~150 lines, no new trust boundary, e.g. "complete one existing file",
  practice exercises, a bug fix): skip this skill. Do the work directly with the
  the project's coding rules + TDD/verification. No spec, no plan, no subagents.
- **Large** (everything else: a feature, a milestone, any trust boundary): full flow. A
  one-feature build gets a short spec (≤ 1 page); the step-7 conditional seats scale the panel.
Say the size you picked in one line. Trust boundary or size unclear → Large.

## 0. Setup (once per repo / branch)

- Trailer hook, only if the user asked for commit trailers, in this session or in the project's CLAUDE.md (otherwise skip it; never install it unasked), so subagent commits never need rewriting:
  `"${CLAUDE_PLUGIN_ROOT}"/scripts/install-git-hooks.sh "<trailer lines from the system attribution reminder, one per line>"`
  Re-run at every session start and whenever the attribution reminder changes (it can change mid-session).
- Usage: `cat "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/state/usage.json"` (written by the status line). Pause threshold 95%
  unless the user says otherwise. Obey `USAGE GUARD` messages from the hook.
  Budget mode (usage ≥ 85%): drop `panel-design`, keep `panel-cdo` only if an AC rests on it,
  never escalate `panel-correctness` to Opus, and say so.

## 1. Scope gate (before questions)

Write 6 lines max, in chat:
- **Smallest useful version:** what a new user needs, nothing more.
- **Cut:** features/knobs/config dropped, and why.
- **Deferred:** good ideas parked → plan doc's Backlog section, not the spec.
- **Reuse/delete:** existing code to reuse or remove instead of adding.
- **Trust boundary?** yes/no (auth, tokens, crypto, signing, provisioning, payments, PII,
  admin surfaces, untrusted input parsing). Yes → security seat in step 7.
- **Audience-facing?** yes/no (docs, onboarding, README, site/landing, pricing,
  positioning) + the target reader. Yes → `panel-cdo` in step 7.

## 2a. Exec room (only when the owner asks for it)

Dispatch `lean-sdd:exec-seat` ×3 in ONE message (CEO, CPO, CMO), each with: the question, the
target reader, source files, and its paper path `docs/superpowers/exec-room/<date>/r1-<seat>.md`.
Round 2 (`r2-*`, each reads the others) only if the papers conflict on something the spec needs.
Then you act as CTO: drop what can't be delivered, run the step-1 Cut over the rest
(extras → Backlog). Surviving choices become the options in step 2's questions. The
papers never decide; the owner does. Commit them with the spec.

## 2. One question round

Research first (docs, code). Classify each open fork:
- **Observable fact** (behavior, timing, load, output, which design handles a workload):
  don't ask, don't settle it by argument. Add a prototype/measurement task that settles
  it as the first plan task, and mark the dependent decision `pending: T1`.
- **Technical call the code or docs settle:** decide, state it in Decisions.
- **Product, taste, or ambiguous intent:** ask.

One-way-door choices (data shape, wire format, public interface, algorithm): name ≥2
shapes in Decisions. If a fact decides between them, it's the first case.
Then ask ALL questions in one AskUserQuestion call (max 4), recommended option first.

## 3. Spec

`docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` with: Goal, Non-goals (from scope
gate), Decisions, Design, **numbered Acceptance criteria** (each falsifiable: condition,
metric, threshold, plus the command that checks it, e.g. "10k rows export < 2 s:
`<your test command>`"; step 8 checks them). A criterion no command can check
(claims audit, visual taste) names its checker instead: `check: seat <name>` or
`check: owner at gate`. Security notes (if trust boundary). Self-review once: run each AC's Check command once on
the base (red is fine; a usage error or missing file is not: fix the command). Then one **pre-mortem**:
`lean-sdd:panel-correctness` (default model) on the spec file only, brief "which edge,
release or semantics questions will the milestone panel raise about this design? Name each external API or third-party
behavior the design assumes and check it against its docs. max 8 lines".
Each answer becomes a Decision, a Non-goal or a question at the gate. Then **GATE: user approves**.

## 4. Plan: interfaces and tests, not code

`docs/superpowers/plans/YYYY-MM-DD-<milestone>.md`. Per task:
files, public interfaces/signatures, acceptance tests (name + what each asserts),
constraints, **agent** (`sdd-implementer-lite` | `sdd-implementer`; role names, dispatched as `lean-sdd:<name>`), **depends-on**.
- No full implementation code; snippets ≤ 15 lines only for tricky contracts.
- When tasks share a contract (outputs, API, file format), the consumer's test fixtures use the producer's real-shaped values, not simplified fakes.
- A removal or rename task's acceptance test is a repo-wide grep (every dir: web, assets, examples, dotfiles) with an explicit allowlist.
- Tiering: lite = docs, config, boilerplate, mechanical; implementer = logic, stores,
  handlers, integration, e2e. Tasks that run network or infra tooling (a download,
  install or network step) are never lite. Use `model: "opus"` override only for genuinely hard
  algorithmic/concurrency tasks, and say why.
- Order: settling prototypes/measurements and baseline capture first (riskiest unknown
  first), then scaffold, then features. Tasks that don't depend on the pending decision
  (e.g. middleware against an interface fake) join the settling task's parallel group.
- Mark tasks with no shared files and no depends-on as one **parallel group**.
- An e2e that proves a workflow sizes its fixture so the workflow takes its full path, and asserts
  the workflow's own artifacts (ledger, metrics), not only the final output.
- Add a **Backlog** section (deferred items from step 1 and later reviews).
- Then build immediately.

## 5. Build

- Dispatch with the plugin-qualified name: `subagent_type: "lean-sdd:sdd-implementer"` / `"lean-sdd:sdd-implementer-lite"`
  (the bare name errors "not found"; use `lean-sdd:<agent>` for every dispatch below).
  The agents carry the coding rules, the 3-attempt stuck rule and a 10-line report format,
  so the brief is just: task text from the plan + base sha + spec path.
- Parallel group → dispatch in one message, each with `isolation: "worktree"`; merge back
  in plan order, run the full suite after the merge.
- Ledger stays (pause/resume), one line per event, appended with `"${CLAUDE_PLUGIN_ROOT}"/scripts/sdd-log.sh <plan> <line>`
  (it refuses formats not in the `"${CLAUDE_PLUGIN_ROOT}"/scripts/sdd-metrics.sh` header). Run sdd-metrics.sh after each panel round (it lints).
  A `fix` = one reviewer fix-needed verdict on a task; the re-review that passes is `done`.

## 6. Per-task review

`"${CLAUDE_PLUGIN_ROOT}"/scripts/review-pkg.sh <task-base-sha>` → prints package path (diff, diffstat,
trailer check). Dispatch `lean-sdd:sdd-reviewer` (or `lean-sdd:sdd-reviewer-lite` for lite tasks) with the
path + task brief.

**Fix-round cap:** max 2 fix rounds per task. Re-reviews use `lean-sdd:sdd-reviewer-lite` on the fix
diff only. Still failing after 2 → mark `blocked` in the ledger, move on to independent
tasks, report at milestone end.

**Mid-build spec change:** a fix that changes a spec Decision gets a `lean-sdd:panel-correctness` pre-mortem
on the spec diff before dispatch. Briefs for later reviews cite `git show <branch>:<spec>`, not a worktree copy.

## 7. Milestone panel

After all tasks, build one package for the whole branch, then dispatch in ONE message:
- `lean-sdd:panel-correctness` (Sonnet, medium); trust boundary → dispatch with `model: "opus"`
- `lean-sdd:panel-design` (Sonnet) only if the branch adds ≥ ~300 lines of new non-test code (not docs,
  renames or tests); otherwise skip it and log `PANEL design skipped <reason>`.
- `lean-sdd:panel-security` (Opus) only if the scope gate said trust boundary. It is the only
  security pass; don't also run `/security-review`.
- `lean-sdd:panel-cdo` if the scope gate said audience-facing or the milestone has UI. It does the
  browser QA (main flows, screenshots) with a browser automation tool if installed, otherwise it says QA was partial. Brief: target reader, plus any skills or
  reference bar to judge against.
Each seat's brief lists the `check: seat <name>` ACs it owns; the seat answers them on its `ACS:` line.

Filter first. Propose dismissals, each with a one-line reason: a hypothetical input no
caller can produce (trace the call site), a preference with no concrete failure ("I'd use
an interface"), a nit inflated to must/should. Ask the owner about all of them in one
AskUserQuestion before the fix wave; accepted ones are listed again at the merge gate.
Then triage: findings raised by 2+ seats are **must-fix**. Surviving single-seat `must` is a fix. `should`
gets fixed if cheap, otherwise goes to the Backlog. One fix wave (`lean-sdd:sdd-implementer`), then one
`lean-sdd:sdd-reviewer-lite` re-review. Log each `ACS:` answer as a `SEAT` line; an owner's yes on a
`check: owner` AC is `SEAT owner pass <sha> AC<n>` (spec-converge reads only that form).
**Seat re-run** (the one rule): a `check: seat` AC whose files changed after its `SEAT` line (fix
wave or coord fixes) gets that seat re-run on the fix diff only (`review-pkg.sh <pre-fix sha>`),
never the whole branch. All re-runs finish before spec-converge, so converge runs once. The brief
lists the owned ACs and every dismissed finding with its one-line reason (not re-raised). The seat
rules pass/fail on those ACs plus regressions the fix caused; new nits go to the Backlog, unfixed.
Max one re-run per seat per milestone; a second fail → ask the owner.

## 8. Converge and docs

- `lean-sdd:spec-converge` agent with the spec path, base ref and plan path (for `SEAT` ledger lines).
  It writes the status table into the spec,
  one verdict per criterion: VERIFIED | NOT VERIFIED | INCONCLUSIVE.
  Any verdict other than VERIFIED: fix it, or ask the user to accept it as a deliberate cut.
- Update the README/usage docs for user-visible changes, and add a CHANGELOG entry if the repo has one.
- superpowers:finishing-a-development-branch, then **GATE: user approves merge**. The
  finishing menu counts as the gate only if the non-VERIFIED criteria and the dismissed
  findings are listed right above it; picking merge or PR is then the explicit yes.
- After the PR opens, and again after every push to the PR branch: `"${CLAUDE_PLUGIN_ROOT}"/scripts/pr-checks-wait.sh <pr>`
  (exit 1 = a check failed, 3 = gh error or no checks). The merge gate quotes the head sha it printed. CI red → fix before merge. ACs checked on PR
  CI get their spec edit committed to the branch before the merge, never after.
- Merge with `"${CLAUDE_PLUGIN_ROOT}"/scripts/pr-merge.sh <pr> <head sha>`: it refuses a moved head, merges, and
  prints any branch commit missing from the base (exit 3 = lost work; land it on main).

## 9. Retro (after merge, ≤ 6 lines, appended to the plan doc)

- **Numbers:** paste the line from `"${CLAUDE_PLUGIN_ROOT}"/scripts/sdd-metrics.sh <plan>` (tasks, fix rounds,
  coord fixes, blocked, findings per seat, triage, 5h usage).
- **What repeated or wasted effort?** Turn each item into **structure**: a script, hook,
  test, agent rule or CLAUDE.md line. Mechanical lessons get a check, not prose. Keep a lesson
  only if it is high-signal, high-frequency or high-impact.
- **Workflow lessons** (this skill, the plugin's `agents/` and `scripts/`): propose the edit
  with its evidence, apply on the user's yes in your clone of the lean-sdd repo, then append
  `YYYY-MM-DD <file>: <change> (evidence)` to `skills/lean-sdd/CHANGELOG.md` there. A marketplace
  install has no clone, and the plugin cache is overwritten on update: record the lesson in the
  project's `CLAUDE.md` or open an issue or PR against lean-sdd instead.
  Baseline = the real-session failure the edit targets, cited in the CHANGELOG line (plan or
  ledger ref). A rule with no real failure behind it runs a superpowers:writing-skills eval
  (baseline first) before it ships. Other lessons: Backlog, except a CI or post-merge escape:
  its check becomes T1 of the next plan.
- Update project memory: the next milestone and anything to start from.

## Context discipline (coordinator)

- Never read full diffs or whole files yourself during build/review. Agents read the
  package path. You read their 10–15-line reports.
- Exception: a fix of ≤ 10 lines you may make yourself, logged as
  `T<n> coord <sha> <note>`. Batch them: one `lean-sdd:sdd-reviewer-lite` checks all coord fixes of a
  task (or of the panel round) at the boundary, before a dependent task starts. A coord fix
  under a `check: seat` AC follows the step-7 seat re-run rule instead.
- Chat between gates: only questions, blockers, gate summaries and one line when the build or
  panel phase finishes. Agent reports go to the ledger, not to chat. Answer status questions when asked.
- The plan doc and the ledger are the source of truth. After a `/compact` or on resume, re-read the
  ledger tail and the current task. Don't re-read the whole plan.
- Suggest `/compact` at milestone boundaries (after the retro), not mid-task.

## Pause / resume

On a `USAGE GUARD` pause message or a user request:
1. Let in-flight agents finish and commit.
2. Append `PAUSED at <step/task>, next: <action>` to the ledger, the plan doc and project memory.
3. Stop any containers you started, then report.

Resume: read the ledger tail, verify the tree is clean and on the right branch, then continue at `next`.
