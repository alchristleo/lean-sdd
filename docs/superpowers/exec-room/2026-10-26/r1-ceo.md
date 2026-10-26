# CEO position paper, round 1: lean-sdd open-source launch (2026-10-26)

Sources: SKILL.md, GUIDE.md, CHANGELOG.md in `~/.claude/skills/lean-sdd/`; `~/.claude/agents/*.md`; the brief; coordinator message (owner constraint: generic, stack-neutral, origin repo github.com/alchristleo/agentic-warden).
No `product-marketing.md` exists (checked `~/.claude`, repo, `~/.agents`), so positioning rests on the brief's reader only.

## Position
Sell lean-sdd as a generic "size dial plus evidence trail" on top of superpowers, not as a lighter superpowers. No source measures token cost against plain superpowers, so the promise cannot claim it yet. What the sources prove: two fixed gates, small work skips the process, and every rule traces to a real failure.
Origin story goes second, as proof, not first, as identity. Lead with the generic promise. Link the CHANGELOG as a case study ("built across real milestones on agentic-warden") so the skeptic sees evidence without reading a Go/auth project's rules.
Day-30 success is a few strangers finishing one milestone, not stars. The top launch risk is that the repo reads as one person's setup.

## Reasoning
1. **One-line promise (draft):** "Two gates, not nine steps: replaces superpowers' brainstorming, plan and subagent steps; small tasks skip it." Backed by two fixed gates (SKILL.md:20), triage skipping 1-3 file tasks (SKILL.md:31-33), replacing three superpowers skills (SKILL.md:8-11).
2. **Why pick it over plain superpowers, in the order the reader must believe it:**
   (a) It sits on superpowers: TDD, systematic-debugging, finishing-a-branch stay (SKILL.md:9-11).
   (b) The gate count is honest: 2 approvals plus an "always ask" list (SKILL.md:23-26, GUIDE.md:6). A skeptic counts gates; show the count.
   (c) Rules are earned: each CHANGELOG line names a failure (CHANGELOG.md:3); a rule without one needs an eval first (SKILL.md:195-198).
   (d) Cost levers exist: Haiku/Sonnet tiers (sdd-implementer-lite.md:4, sdd-implementer.md:4), panel-correctness cut from Opus/xhigh after 19% of 24h usage (CHANGELOG.md:25), design seat only above ~300 new lines (SKILL.md:145-146), budget mode at 85% (SKILL.md:16-18).
3. **Hold until measured:** "lower token cost", "faster", "fewer gates than superpowers". The only comparison is old vs new lean-sdd (CHANGELOG.md:16); ~9k tokens per implementer is n=1 (CHANGELOG.md:81).
4. **Origin story vs generic tool (new constraint):**
   - Generic wins for the target reader: a skeptic who sees Go, `tofu` and IdP examples assumes "fits that project only". Stack-specific text sits in the rules today: `go test` example (SKILL.md:87), "complete App.tsx" (SKILL.md:31), "tofu, docker" (SKILL.md:105; sdd-implementer.md:19,25), IdP/vendor pre-mortem (SKILL.md:92), "Go errors" convention (sdd-implementer.md:22).
   - Origin helps as proof only: the CHANGELOG cites real failures from the author's builds, including "hosted cells" and ECR (CHANGELOG.md:21,24). Keep it as a dated case study with a link, outside the rules.
   - Generic scrubbing changes the rules; each CHANGELOG line's evidence then points at text that no longer exists. Mark the CHANGELOG "history, pre-generalization" so evidence stays honest.
5. **Buying journey:** README hero (promise + workflow diagram) -> "not for you if" (small tasks, no superpowers) -> install -> first run must be a Large task, since Small skips the skill (SKILL.md:31-33) -> CHANGELOG/case study as proof.

## Risks
- **Personal-workflow feel (high):** `~/.claude/scripts/*` paths, status-line usage file, trailer hook, CLAUDE.md rules are baked in (SKILL.md:41-43,124-130,179-194; GUIDE.md:9). Plugin install may not place them. Verify on a clean machine, or the first run fails.
- **Generic scrub drift (medium):** removing project examples may weaken rules that came from them (e.g. network-hang rule, sdd-implementer.md:19). Each removal needs its CHANGELOG evidence kept, or the "earned rules" claim breaks.
- **Superpowers dependency (medium):** it overrides three superpowers skills by instruction (SKILL.md:8-11); no version pin in the sources.
- **Maintenance (medium):** 68 dated CHANGELOG entries in 4 days, 2026-10-23 to 10-26 (CHANGELOG.md), so the rules move fast; public issues add load. The asd-ste100 lint adds a third-party license and update duty (brief).
- **Looks heavy (medium):** 9 steps, 4-seat panel, pre-mortem (SKILL.md:13-18,141-152). Put the triage line above the fold.

## Options for the owner
**A (recommended): generic-first, evidence-linked soft launch.** Promise = size dial + two gates, no token claim. Scrub examples from SKILL.md and agents to neutral wording; CHANGELOG stays as linked agentic-warden case study; README has "not for you if", pinned superpowers version, clean-machine install test. Ask ~5 named power users to run one Large milestone. Day-30 bar (owner sets): >=5 outside runs reaching merge, >=3 outside issues, 0 open install failures. Cost: ~2-3 days (scrub, install test); ~2-3 h/week triage for the month.
**B: measured-savings launch.** Run 3 same tasks on plain superpowers and lean-sdd, publish `sdd-metrics.sh` numbers (GUIDE.md:10); permits a token claim only if it holds. Cost: ~2-4 days plus usage spend; a null result forces A's wording.
**C: origin-story launch ("how I run agentic-warden").** Ship mostly as is, narrative first. Cheapest (hours) but fits the target reader worst: reads as a personal setup and breaks the generic requirement.
