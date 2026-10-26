# CPO r1: first-run experience of lean-sdd (reader: superpowers power user, wants fewer gates, lower token cost, skeptical)

No `.agents/product-marketing.md` or `.claude/product-marketing.md` exists in the repo (checked); sources are the brief's files. Paths below are under `/home/leo/.claude/`. Install commands are not in any source: marked "verify".

## Position
1. The value moment inside 10 minutes is the spec gate: one prompt, one size line, a 6-line scope gate, one question round, a spec with checkable criteria, then a yes from the user. No code is written before it (SKILL.md:13-20, 48-94).
2. The README must sell "two gates, everything else quiet", not "a full process". Show triage, scope gate and the gates. Hide the exec room, ledger and metrics until after the first merge.
3. As shipped today, an outsider hits personal setup before the value moment: a git hook written into their repo, hardcoded `~/.claude/` paths, a statusline that carries a caveman badge. Cut or soften those before the README matters.

## Reasoning with sources
**Install and prerequisites (needed-when, so the skeptic sees the real up-front cost):**
- Plugin install: `/plugin marketplace add <owner>/lean-sdd`, then `/plugin install lean-sdd@<marketplace>` (verify exact syntax and that plugins can ship the agents, scripts and hook listed here).
- superpowers: needed for `finishing-a-development-branch`, TDD and `systematic-debugging` (SKILL.md:8-11). lean-sdd replaces brainstorming, writing-plans and subagent-driven-development, and says not to invoke them (SKILL.md:8-9). A power user will ask "does it collide with my superpowers triggers?" The README answers in one line.
- gh CLI: first used at step 8 (`pr-checks-wait.sh`, `pr-merge.sh` call `gh`, scripts/pr-checks-wait.sh:11, scripts/pr-merge.sh:8,14). Not needed before the merge gate. Say so, so it is not read as a day-one blocker. GitHub-only is a stated limit.
- Statusline: the guard reads a cache the statusline writes (hooks/usage-guard.py:4,15-16; scripts/statusline.py:63-77). No statusline, no cache: the hook returns silently (usage-guard.py:29-33). The user believes they are protected and are not. This is the worst silent failure on the first run.
- Playwright: only `panel-cdo`, only for UI or audience-facing work (agents/panel-cdo.md:10). Optional.

**First prompt and first 10 minutes.** A plain prompt ("build X", "continue next milestone", GUIDE.md:5). Expected sequence:
- 0:00 Prompt. Claude states the size in one line (SKILL.md:36). Small (1-3 files, under ~150 lines, no trust boundary) skips the skill and just does the work (SKILL.md:31-33). A skeptic's first test is a small task; the README should say "nothing happens, by design".
- 0:30 Step 0 setup: re-runs `install-git-hooks.sh`, which copies a commit-msg hook into the user's repo and writes `.git/claude-trailer` (SKILL.md:40-42; scripts/install-git-hooks.sh:9-21). Surprising, invasive, and unrelated to the user's goal.
- 1:00 Scope gate, 6 lines in chat: smallest version, cut, deferred, reuse, trust boundary, audience-facing (SKILL.md:50-58).
- 2:00 One question round, max 4 questions, recommended option first (SKILL.md:80-81).
- 4-8:00 Spec at `docs/superpowers/specs/...` with numbered, falsifiable criteria and their check commands (SKILL.md:84-89), a pre-mortem by one subagent (SKILL.md:89-93), then GATE. This already spends a subagent; the README should not claim "no subagents before build".
- The build (plan, parallel implementers, per-task review, panel) starts only after the yes. Time-to-first-code is therefore past the 10 minutes, and the README says so.

**Show vs hide.**
- Show: size line, scope gate, the two gates (SKILL.md:20), one example spec with its criteria, one real retro numbers line after a merge (SKILL.md:187-188).
- Hide, one line each under "Optional": exec room, owner-asked only (SKILL.md:60; CHANGELOG.md:84); ledger, written by script, never by hand (SKILL.md:124-125); metrics, run by the retro (SKILL.md:187).
- Evidence for skepticism: the CHANGELOG, one line per edit with the failure behind it (GUIDE.md:11; CHANGELOG.md:36 cut panel-correctness after it used 19% of 24h usage; :82 dropped the Medium tier, 0 of 6 plans used it; :85 shrank GUIDE from 258 to 11 lines). No source compares total token cost against vanilla superpowers; the only per-agent figure is "~9k tokens per implementer, n=1" (CHANGELOG.md:92). Make no cost-saving claim without a measurement.

**README order (4 diagrams).**
1. Pitch, 3 lines: what it replaces, two gates, small tasks skipped. 2. Install plus the needed-when prerequisites table. 3. First prompt and "what you will see", with diagram 1 (workflow T to 9) right under it. 4. "What the two gates ask of you", with diagram 2 (task lifecycle: build, review, max 2 fix rounds, blocked; SKILL.md:134-136). 5. "How it works" for the curious: diagram 3 (coordinator to agents sequence) and diagram 4 (architecture map: skill, agents, scripts, hook, statusline cache). 6. Optional: usage guard, exec room, metrics. 7. Evidence (CHANGELOG link). 8. Third party: asd-ste100 lint, MIT, with license.

**Personal or confusing to an outsider (each with a source).**
- Hardcoded `~/.claude/scripts/...` throughout SKILL.md (lines 41, 43, 124-125, 130, 179, 182, 187, 194) and `/home/leo/...` in the hook command (settings.json:9,21, outside the plugin). A plugin needs `${CLAUDE_PLUGIN_ROOT}`-style paths (verify).
- Statusline: `statusline.py` pulls a caveman plugin badge by glob (statusline.py:12-13). Ship only the cache-writing part.
- The commit-msg trailer hook and "attribution reminder" (SKILL.md:40-42) exist for one owner's commit conventions (CHANGELOG.md:63, :83).
- Jargon with no definition in the skill: AC, SEAT, PANEL, coord, converge, "act as CTO" (SKILL.md:66), "owner" (the reader is the user).
- CHANGELOG names unexplained sources and projects: poteto, Pocock, noodle, "hosted cells", "agent-wrapper" (CHANGELOG.md:18-22, 87). It reads as a private diary to an outsider. Keep the evidence, add one header line saying the project names are the author's own repos.
- GUIDE.md says it is an "overview" while SKILL.md wins on conflict (GUIDE.md:3). A README replaces it; delete it to avoid a third description.

**Stack-neutral rewrite (owner constraint: origin is the public Go/auth repo agentic-warden). Leaks and generic wording:**
- SKILL.md:87 `go test -run TestExport10k -v` -> "`<your test command>`, e.g. a single named test". SKILL.md:31 "complete App.tsx" -> "complete one existing file".
- SKILL.md:92-93 "IdP/vendor field" -> "each external API or third-party behavior the design assumes; check it against that provider's docs". SKILL.md:55 trust-boundary list (auth, tokens, crypto, provisioning) is generic enough; keep, drop "provisioning".
- SKILL.md:103 "web, assets, examples, dotfiles" -> "every directory, including docs, examples and config". SKILL.md:105 "(tofu, docker, package downloads)" -> "tasks that call the network or external tooling"; sdd-implementer.md:19,25 and lite:23 "tofu init, docker pull" -> "a download or install step", "servers, containers" -> "any process you started".
- panel-cdo.md:10 and SKILL.md:150 "Playwright" -> "a browser automation tool if one is installed; otherwise read the rendered output and say QA was partial". sdd-implementer.md:22 "Go errors: lowercase..." -> "the language's own error-message convention".
- Other stack or person ties: SKILL.md:32 "CLAUDE.md coding rules" (the outsider has none; say "your project's own rules"); SKILL.md:46,144-147 and agent frontmatter name Haiku/Sonnet/Opus (say cheap/default/strongest tier, map in one table); STE100 wording rule in the implementer agents (implementer.md:22) is a personal style, make it a config line, not a default; panel-security.md:7 "SSRF, nonce reuse, replay" suits an auth project, keep as a checklist "where relevant".
- CHANGELOG leaks (public): ":35 ECR ARN", ":76 Entra email_verified", ":43 tofu init", "hosted cells", "agent-wrapper", "security-hardening", "releases". Cost to fix: rewrite ~12 lines so evidence stays but names go ("a cloud-deploy milestone"); or keep verbatim and say it is the origin project.
- Rule for the owner: a rule has no project example; an example lives in the README, labeled as an example.

## Risks
- Skeptic runs a tiny task, sees no process, concludes it does nothing. Mitigation: README says that is the design.
- Skeptic counts gates: the real count includes the question round, the dismissal question (SKILL.md:156-157) and the always-ask list (SKILL.md:24-27). "Two gates" is true only for hard approvals. State the full list, not a flattering one.
- Silent usage-guard failure (above) damages the "lower token cost" promise at the first rate limit.
- Plugin packaging unverified: agents in `~/.claude/agents/` and a `settings.json` hook may not ship the way the brief assumes.

## Options for the owner
**A (recommended): spec-gate-first README plus minimum portability.** README in the order above; prerequisites table with needed-when; make the trailer hook opt-in and the statusline cache-only; replace hardcoded paths; add a header to the CHANGELOG; delete GUIDE.md; apply the stack-neutral rewrite above (about 10 line edits in SKILL.md and 4 agents, one grep for tofu|docker|Playwright|go test|IdP|Entra as the check); add an "if the guard is silent" check to the README. Cost: README plus diagrams (already decided), a path-refactor pass over SKILL.md, 6 scripts and the hook; one maintenance rule: every skill edit re-checks the README sequence.
**B: A plus a real recorded first run.** One real run on a toy Large task, text transcript to the spec gate plus a later retro line, pasted in the README as proof. Cost: one real run (tokens and time) and a re-record whenever steps 1-3 change; gives the skeptic evidence A cannot.
**C: A plus a preflight script.** One command checks superpowers, `gh auth`, a fresh `usage.json`, the hook registered. Cost: one new script and tests, kept in step with the prerequisites; it removes the silent-guard failure instead of documenting it. B and C can both be added later; neither blocks v1.
