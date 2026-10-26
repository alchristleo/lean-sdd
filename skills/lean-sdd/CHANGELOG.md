# lean-sdd changelog

Origin: github.com/alchristleo/agentic-warden. Milestone names in the lines below refer to that repo.

Workflow edits to this skill, `~/.claude/agents/` and `~/.claude/scripts/`. One line each: `YYYY-MM-DD <file>: <change> (evidence)`. Backup of the pre-2026-10-23 version: `~/.claude/backups/lean-sdd-2026-10-23/`.

- 2026-10-23 SKILL.md: description trimmed to triggers only (writing-skills: workflow summaries in descriptions get followed instead of the body).
- 2026-10-23 SKILL.md: gates need explicit yes; ask on ambiguity/judgment at any step (user rule, replaces "proceed on recommended").
- 2026-10-23 SKILL.md step 2: classify forks; observable facts settled by a first-task prototype/measurement; ≥2 shapes for one-way doors (poteto prototype + architect; baseline S1 settled token bucket vs fixed window by argument).
- 2026-10-23 SKILL.md steps 3-4: falsifiable acceptance criteria with check command; riskiest-unknown/baseline first (poteto verify-this, figure-it-out).
- 2026-10-23 SKILL.md step 7: filter hypothetical/preference/inflated findings before triage (poteto interrogate lead-judgment; baseline S3 rule forced guarding an impossible nil).
- 2026-10-23 SKILL.md step 8 + spec-converge.md: VERIFIED/NOT VERIFIED/INCONCLUSIVE, run-based evidence, base-vs-branch timing (poteto verify-this, prove-it-works; baseline S3 proposed unit-test timing assert).
- 2026-10-23 SKILL.md step 9: workflow lessons routed back here with changelog (poteto reflect, noodle meditate quality bar, Pocock retro).
- 2026-10-23 sdd-implementer[-lite].md: literal expected values; revert refuted-hypothesis changes (baseline S2 Haiku kept tautological test and unproven DB changes).
- 2026-10-23 sdd-reviewer.md: two-edit test check (poteto test-behavior-not-implementation).
- 2026-10-23 SKILL.md step 4: tasks independent of a pending decision join the settling task's parallel group (eval round 1: S1 lost parallelism, strict T1→T5 chain).
- 2026-10-23 sdd-implementer[-lite].md: root cause outside task files → CONCERNS, not fixed (eval round 1: S2 planned out-of-scope fix with no deviation).
- 2026-10-23 eval result: blinded A/B, old vs new, 4 scenarios. Final: S1 12/9, S2 9/7, S2-lite 9/6, S3 12/11 (new/old). Artifacts were in session scratchpad (not kept).
- 2026-10-23 ~/.claude/CLAUDE.md rule 5: red-capable command on current code path before theory (Pocock diagnosing-bugs). Eval: bug scenario 3 reps each; baseline 0/3 reproduced on current code (all tested a not-yet-existing API = compile-red), treatment 3/3 drove existing entry point and treated green as "theory refuted".
- 2026-10-23 ~/.claude/CLAUDE.md rule 1: two readings → ask (recommended first) unless evidence settles it; was "pick the recommended one" (conflicted with user ask-first rule).
2026-10-23 agents/sdd-implementer.md, sdd-implementer-lite.md: sync worktree to brief's base sha, commit on worktree branch not detached HEAD (agent-wrapper platform refresh: 4/6 worktree agents started from stale base, 2 committed detached, manual merges)
2026-10-23 scripts/review-pkg.sh: default name includes base sha (two packages at one HEAD overwrote each other, platform refresh T4)
2026-10-24 agents/sdd-implementer.md, sdd-implementer-lite.md: stop background processes before reporting (hosted cells: 3 agents left hung tofu init, one re-sent its report 3x)
2026-10-24 agents/sdd-implementer.md: mutation-check each security/negative assertion (hosted cells: 2 vacuous security tests passed TDD, caught only by reviewer mutations)
2026-10-24 agents/sdd-reviewer-lite.md: check trailer against .git/claude-trailer, not own attribution reminder (3 false Haiku-trailer findings across 2 milestones)
2026-10-24 skills/lean-sdd/SKILL.md step 4: consumer fixtures use producer's real-shaped contract values (hosted cells: ECR ARN bug hidden by a fake one-segment repo URL)
2026-10-25 agents/panel-correctness.md + SKILL.md step 7: panel-correctness Sonnet/medium by default, Opus only on trust boundary; panel-dependent ACs re-run that seat on the fix diff only (panel-correctness was 19% of 24h usage at Opus/xhigh)
2026-10-25 skills/lean-sdd/SKILL.md step 7: scoped re-run briefs list dismissed findings with reasons (readme-appeal: CDO re-raised '05 lacks doctor output' after it was dismissed with tape:line evidence)
2026-10-25 review of 4 milestones (platform refresh, hosted cells, docs-onboarding, readme-appeal); backup ~/.claude/backups/lean-sdd-2026-10-25/. Applied on user yes:
2026-10-25 SKILL.md intro + description: lean-sdd replaces brainstorming/writing-plans/SDD; keeps TDD, systematic-debugging, finishing (none of the three invoked in 4 milestones)
2026-10-25 SKILL.md gates: always-ask list (dismiss finding, skip review step, past cap, early start, user-facing wording); "unless you object" is not asking (diagnosis 18bd1826: calls made alone after the user's loop-me rule)
2026-10-25 SKILL.md triage: unclear or trust boundary -> Large; re-triage at >=5 planned tasks; scope gate for every size above Small (platform refresh labelled Medium with 5 tasks + trust boundary; hosted cells had no scope gate)
2026-10-25 SKILL.md step 3 + spec-converge.md: `check: seat <name>` / `check: owner at gate` for criteria no command checks; SEAT ledger lines (readme-appeal AC3/AC11, docs AC11 INCONCLUSIVE until re-run)
2026-10-25 SKILL.md step 4 + sdd-implementer[-lite].md: network/infra tasks never lite; hung download = 1 retry then BLOCKED (hosted T5 haiku ran tofu init 20x, 34% of agent tokens)
2026-10-25 sdd-implementer[-lite].md: docs claims cite a source in the commit body, else cut (docs-onboarding 8 fix rounds, 14+9 unsupported claims; readme-appeal T5 2 rounds)
2026-10-25 SKILL.md step 7: drop /security-review, panel-security is the only security pass (hosted cells: 3 overlapping passes, /security-review 0 findings, failed once on origin/HEAD)
2026-10-25 SKILL.md step 8: finishing menu counts as merge gate when non-VERIFIED ACs + dismissals are listed above it; gh pr checks --watch; main..origin/<branch> empty after merge (merge gate taken from menu "2" twice; PR #1 CI red found by user; cc21887 + 7ad4785 stranded off main)
2026-10-25 SKILL.md coordinator: fixes <=10 lines allowed, ledger `coord`, reviewer-lite if an AC rests on it (~10 coordinator fixes across 4 milestones despite the rule)
2026-10-25 GUIDE.md: synced with the above and the earlier 2026-10-25 panel-tier and re-run changes. Not rerun as an eval: evidence is the real-session failures above.

## 2026-10-25 review 2 (owner proposals + 7 findings; not rerun as eval, evidence = sessions below)
2026-10-25 SKILL.md T: Medium runs 0 and 8 (trailer hook, converge, merge gate, CI, stranded-commit check); dead "+ security if flagged" removed (trust boundary is always Large) (review: Medium had no merge gate)
2026-10-25 SKILL.md 1, 2a + agents/exec-seat.md: scope gate asks audience-facing + reader; yes → exec room (CEO/CPO/CMO papers, 1 round default, coordinator as CTO, options feed step 2, claims cited) (docs-onboarding exec room was improvised via general-purpose prompts; its r2 papers shaped the spec)
2026-10-25 SKILL.md 7 + agents/panel-cdo.md: CDO seat for audience-facing/UI work, absorbs the browser QA pass (readme-appeal ran panel-design as "Chief Design Officer" via a prompt override, mixing code-design and visual lenses)
2026-10-25 SKILL.md 7 + panel-*.md + spec-converge.md: seat briefs list their `check: seat` ACs, seats answer on an `ACS:` line, ledger logs `SEAT <name> pass|fail <sha> AC<n>` (whole-branch approve was logged as if it proved one AC)
2026-10-25 SKILL.md 7: dismissals asked in one AskUserQuestion before the fix wave (contradicted the always-ask list)
2026-10-25 agents/sdd-reviewer*.md: unsourced product claim in docs = must (implementer sourcing rule had no check)
2026-10-25 agents/sdd-*.md, spec-converge.md: descriptions name agents, not old sonnet/haiku tags; spec-converge input includes the plan path (drift)
2026-10-25 CLAUDE.md: agent list + exec room mention synced
2026-10-25 SKILL.md 9: baseline = cited real-session failure; full writing-skills eval only for speculative rules (old >10-line rule never ran: both 2026-10-25 reviews skipped it). exec room + panel-cdo: first audience-facing milestone is their test
2026-10-25 final review: panel-cdo stops servers + screenshots outside repo; coordinator fix on `check: seat` AC re-runs the seat (reviewer-lite gives no SEAT line, converge would say INCONCLUSIVE); exec papers committed with spec; GUIDE converge attribution + Medium 'or UI' (review, no session failure yet: next audience-facing run tests them)
2026-10-25 scripts/pr-checks-wait.sh + SKILL.md 8: poll PR checks, local gh lacks `--watch` (releases plan retro: first watch died "unknown flag: --watch")
2026-10-25 agents/sdd-implementer.md: run CI-only `run:` steps locally with exact args (releases ledger T5 fix: test-install.sh missing `dist`, would fail every PR)
2026-10-25 scripts/git-hooks/commit-msg + install-git-hooks.sh + SKILL.md 0: multi-line trailer file, Claude-Session normalized too (releases retro: only coordinator commits carried Claude-Session)
2026-10-25 SKILL.md context discipline: quiet coordinator between gates (releases session: user said "ping me once done", coordinator still posted ~25 per-report summaries)
2026-10-25 SKILL.md 7: seat re-run rules pass/fail + regressions only, new nits to Backlog, max 1 re-run per seat (releases ledger: panel-cdo ran 3x, 7/4/4 fresh nits each round)
2026-10-25 SKILL.md context discipline: batch coord-fix reviews per task boundary (releases ledger T4: 4 serial reviewer-lite rounds for ~30 coord lines)
2026-10-25 SKILL.md 7: panel-design only for >= ~300 new non-test lines (releases panel: 1 of 7 design findings adopted on a script/docs milestone)
2026-10-25 SKILL.md 3: spec pre-mortem via panel-correctness on the spec (releases panel: prerelease->Latest, dev-version semantics, attestation scope all spec-level, found after build)
2026-10-25 agents/sdd-reviewer(-lite).md: flag tests that switch off the behavior they check (releases: -buildvcs=false hid AC2 false pass through T2 review; only panel-correctness caught it)
2026-10-25 scripts/sdd-metrics.sh + SKILL.md 5/9: USAGE/PANEL/TRIAGE ledger lines, retro Numbers from a command (releases retro numbers hand-tallied from memory)
2026-10-25 agents/spec-converge.md: carry forward VERIFIED rows and owner SEAT lines when files unchanged; append phase tables; check fix/TRIAGE lines before listing open findings (releases plan, phase 2 retro: AC9 downgraded, fixed findings listed open)
2026-10-25 scripts/sdd-metrics.sh: warn on ledger lines outside '## Ledger*' sections and on off-format PANEL/TRIAGE; count T7a-style tasks (releases phase 2: script silently printed phase 1 numbers)
2026-10-25 agents/sdd-implementer.md: run doc expected-output blocks in a fresh shell and compare line by line (releases phase 2: `ls ~/.local/bin/aw*` full paths passed the substring checker)
2026-10-25 SKILL.md 7: owner yes on a `check: owner` AC logged as `SEAT owner pass <sha> AC<n>` (security-hardening: AC13 INCONCLUSIVE after owner approved, logged as `OWNER approve`)
2026-10-25 SKILL.md 7 + scripts/sdd-metrics.sh: `PANEL <seat> skipped <reason>` is the skip format and lints clean (security-hardening ledger line 22 off-format warning)
2026-10-25 SKILL.md 3: pre-mortem names assumed IdP/vendor fields and checks vendor docs (security-hardening: Entra has no email_verified, found in T7, cost spec revision T5b)
2026-10-25 agents/sdd-implementer(-lite).md: reports, error/CLI text strict asd-ste100, docs STE-flavored, ste-lint on docs, language error conventions win (eval in security-hardening retro: baseline 1 hard lint violation + mismatch error with no fix; with rule 0 violations, errors name actor and fix; Go-style conflict found, so conventions-win clause)
2026-10-25 scripts/sdd-metrics.sh: one line per `## Ledger*` section; usage = sum of start/end pairs shown per pair; coord only from non-review `T<n> coord` lines; fix_rounds = `T<n> fix` lines + `fixN` notes; `FIX wave` count; seat re-runs marked; owner and no-AC SEAT lines out of pass/fail (owner shown apart); `PANEL <seat> skipped` accepted (evidence: review A F3, review B F2; security-hardening 5h printed 61%->4% for 36pt, releases phases merged, releases coord=8 for 6)
2026-10-25 scripts/sdd-metrics.sh + SKILL.md 5: ledger line-type lint (unknown first word warns), formats moved to the script header, SKILL.md format prose deleted; SKILL.md 5 defines a `fix` as one reviewer fix-needed verdict (evidence: review A F2, review B F2; security-hardening ledger `OWNER approve` cost AC13, readme fix_rounds=0 vs 4 in retro)
2026-10-25 SKILL.md 7 + context discipline: seat re-run rules merged into one; re-runs finish before spec-converge so converge runs once (evidence: review A F6, review B F1; security-hardening converge 6fbdd9c then a5b1db4, releases L158)
2026-10-25 SKILL.md 9: a CI or post-merge escape becomes T1 of the next plan, not Backlog (evidence: review A F4, review B F3; CI Go matrix in platform + hosted Backlogs, releases v0.1.0 tag publish failed)
2026-10-25 SKILL.md T/1/2/4/6 + agents/sdd-implementer-lite.md: dropped Medium tier (triage 2-way, short-spec bit folded into Large), Opus escalation (2 fix rounds -> blocked), Bias line, "don't ask mode" line, repeated "new ambiguity: ask" line; budget mode merged into step 0; lite network-hang rule dropped (lite never gets network tasks) (evidence: review A F5/F7/F9c, review B F5/F6; 0 of 6 plans used Medium, 0 escalations in 6 retros)
2026-10-25 SKILL.md 0: re-run install-git-hooks.sh at every session start and when the attribution reminder changes (evidence: review A F1; 36 commits 9713be0..28d6aed lack Claude-Session)
2026-10-25 SKILL.md 1/2a: exec room runs only when the owner asks; scope gate no longer triggers it; exec-seat agent kept (evidence: review A F10, review B F5; releases audience-facing, 2a skipped with no ledger line)
2026-10-25 GUIDE.md: cut from 258 lines to an 11-line human overview pointing to SKILL.md (evidence: review A F9a, review B F4; stale: no pre-mortem, SEAT owner, asd-ste100; needed manual syncs CHANGELOG L37, L49)
2026-10-25 CLAUDE.md: ping rule (send one PushNotification first, quote its result, no retry on "not sent"); line 13 drops "exec room (audience-facing)" and "security gate" to match SKILL.md (evidence: halluc review A F2/F6, review B F1/F4)
2026-10-25 memory (agent-wrapper): lean-sdd-workflow.md deleted (trust-boundary fact moved to agent-wrapper-project.md), lean-sdd edits paragraph cut to the owner-declined list, done reminders dropped, MEMORY.md index synced to descriptions (evidence: halluc review A F6, review B F4)
2026-10-25 scripts/pr-checks-wait.sh + SKILL.md 8: exit 3 on gh error or no checks, prints head sha; re-run after every push to the PR branch (evidence: halluc review A F1; PR #8 merge gate on red tapes CI)
2026-10-25 SKILL.md 3 + agents/spec-converge.md: self-review runs each AC's Check command once; converge running any other command = INCONCLUSIVE + reason (evidence: halluc review A F3, review B F2; hardening AC11 usage error, converge swapped command)
2026-10-25 scripts/review-pkg.sh: docs/superpowers left out of diff and diffstat, trailer check kept (evidence: halluc review B F5; hardening panel package 16% docs/superpowers)
2026-10-25 scripts/sdd-log.sh + sdd-metrics.sh header + SKILL.md 5: ledger lines appended via sdd-log.sh, refused unless they match the sdd-metrics.sh header formats; header adds `T<n> review <approve|fail> <sha> <agent> <note>` (evidence: halluc review A F8, review B F3; 7 off-header `T<n> review` lines in hardening)
2026-10-25 agents/sdd-implementer(-lite).md: Wording = 3 inline rules (active voice, one instruction per sentence, no semicolons), agents do not read the asd-ste100 skill file; conventions-win + ste-lint kept (evidence: halluc review A F5, review B F8; ~9k tokens per implementer, n=1 eval)
2026-10-25 agents/spec-converge.md: model haiku -> sonnet (evidence: halluc review B F2; converge factual errors patched by coordinator in releases and hardening)
2026-10-26 scripts/sdd-log.sh: refuse lines holding a newline or CR before the format match (evidence: skill-packs panel-security should; red test 2026-10-26 logged a forged `SEAT owner pass` via a multi-line COORD note, refused after the fix)
2026-10-26 SKILL.md 4: an e2e that proves a workflow sizes its fixture for the full path and asserts the workflow's own artifacts (evidence: skill-packs plan 2026-10-25 ledger `SEAT correctness pass 8f03409 AC7 letter only`, toy triaged Small, 1 fix wave + 3 reruns)
2026-10-26 SKILL.md 4: removal/rename tasks take a repo-wide grep with an explicit allowlist as acceptance test (evidence: adapter-cleanup ledger `T4 done 258071d ... still Gemini`, owner added T5; .agents/product-marketing.md leak)
2026-10-26 agents/sdd-implementer[-lite].md: user-facing commands copy-pasteable with real flags, no literal `...` (evidence: adapter-cleanup ledger `SEAT panel-cdo fail 4633631 AC11 re-enroll command ... not runnable`, fix wave 2 past cap)
2026-10-26 SKILL.md 6: mid-build spec Decision change gets a panel-correctness pre-mortem on the spec diff; review briefs cite the branch spec (evidence: hardening-r2 ledger cc908e2 reserve rule -> 2-seat panel must; T3 re-review false must from stale worktree spec)
2026-10-26 scripts/pr-merge.sh + SKILL.md 8: merge via pr-merge.sh (head check by git ls-remote, then lost-work check) (evidence: docs-polish ledger MERGED PR #14 after 2 failed merge commands: old gh lacks --match-head-commit and headRefOid)
2026-10-27 SKILL.md header: stop with a "needs Claude Code" message when the Agent tool or lean-sdd agents are missing (evidence: no session failure; claude.com/docs/plugins/platform-support says chat ignores plugin agents and hooks, and a directory listing reaches chat users)
