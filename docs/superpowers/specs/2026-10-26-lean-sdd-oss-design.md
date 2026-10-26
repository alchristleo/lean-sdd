# lean-sdd open-source release: design

Date: 2026-10-26. Exec room papers: `docs/superpowers/exec-room/2026-10-26/r1-{ceo,cpo,cmo}.md`.

## Goal

Publish `lean-sdd` as a public GitHub repo, installable as a Claude Code plugin, with stack-neutral
rules and a README that explains the workflow through four archify diagrams. The repo becomes the
source of truth for the owner's own copy.

Reader: a Claude Code power user who knows superpowers, wants fewer gates, and doubts heavy process.

## Non-goals

- No claim of lower token cost or fewer gates than superpowers (no measurement exists). Backlog: measured A/B.
- No interactive archify HTML on GitHub Pages, no animated GIF, no demo video, no recorded run.
- No preflight script, no eval suite, no CONTRIBUTING guide (Backlog).
- No change to what the rules do. Only wording that names one stack or one person changes.
- No launch posts (Backlog; outward-facing, owner does them).

## Decisions

1. **Name and tagline:** `lean-sdd`, H1 subtitle "Two gates. Evidence for everything else." (owner).
2. **Install shape (one-way door):** a Claude Code plugin with a marketplace manifest in the same repo.
   Two path shapes for scripts the skill calls; `pending: T1`:
   - A (expected). The skill, agents and `hooks.json` use `"${CLAUDE_PLUGIN_ROOT}"/scripts/...` (quoted).
     Docs (pre-mortem) say Claude Code substitutes it in skill/agent bodies and hook commands, but it is
     NOT in the Bash env, so scripts never read it: scripts find each other via `$(dirname "$0")`.
   - B (fallback only if T1 shows A fails). The skill resolves its own base directory (printed on load)
     and calls `<skill dir>/../../scripts/...`.
   T1 also settles: agents and hooks ship in a plugin; the exec bit survives the plugin cache copy; the
   `subagent_type` name of plugin agents (docs say `lean-sdd:<agent>` for `--agent`/@-mentions, unconfirmed
   for subagent_type); no agent uses frontmatter that plugin agents ignore (hooks, mcpServers,
   permissionMode); whether `dependencies: ["superpowers@<mkt>"]` loads with
   `allowCrossMarketplaceDependenciesOn` in marketplace.json. If the dependency fails, the README says
   "install superpowers first". Isolation for tests: `CLAUDE_CONFIG_DIR` (HOME alone is undocumented).
   Plugin name, marketplace name and install id are pinned to `lean-sdd`, `lean-sdd`, `lean-sdd@lean-sdd`.
   State path: scripts and the hook use `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/state`, never `~/.claude/state`.
   Agent names in SKILL.md, README and the owner's CLAUDE.md follow the T1 result in one rename sweep.
3. **Source of truth:** this repo. The owner installs it as a plugin from the local clone and retires
   the copies in `~/.claude/{skills/lean-sdd,agents,scripts,hooks/usage-guard.py}` (backed up first,
   owner confirms at the merge gate).
4. **Stack-neutral rules:** rules hold no project example. Rewrites: Go test example → `<your test command>`;
   "IdP/vendor field" → "each external API or third-party behavior"; `tofu`/`docker` → "a download,
   install or network step"; Playwright → "a browser automation tool if installed, otherwise say QA was
   partial"; "complete App.tsx" → "complete one existing file"; Go error convention → "the language's own
   error convention"; "CLAUDE.md coding rules" → "the project's coding rules". Model names in agent
   frontmatter stay (Claude Code needs them).
5. **Commit trailer hook:** opt-in. Step 0 runs it only if the user turned it on; the README says how.
6. **Usage guard:** ships with a cache-only status line script (`statusline.py` minus the personal
   badge). The README says the guard does nothing without it.
7. **asd-ste100 lint:** bundled with its MIT license; credited in `THIRD_PARTY_NOTICES.md`.
8. **CHANGELOG:** ships unchanged plus one header line naming the origin repo
   (github.com/alchristleo/agentic-warden) and saying milestone names refer to it. README wording:
   "each rule cites the failure behind it, or says it has none." Shows "one maintainer, since 2026-10-23".
9. **GUIDE.md:** deleted; the README replaces it.
10. **README layout:** H1 + tagline, one plain text line (license, plugin, superpowers), one-sentence
    pitch, 3 bullets, workflow diagram, install. Then "What happens to one task" with the lifecycle
    diagram. Sequence and architecture diagrams inside `<details>`. Then "You approve / Claude decides /
    Claude asks you" table, Optional (exec room, ledger, metrics, usage guard), Removed list, Proof
    (4 sourced CHANGELOG lines), "Where this came from", Built on (credits). No badges, no emoji,
    max 3 GitHub alerts.
11. **Diagrams:** archify JSON sources in `docs/diagrams/*.json`, exported to `assets/<name>-{light,dark}.svg`,
    shown with `<picture>` + `prefers-color-scheme`. Fallback if SVG export or GitHub rendering fails:
    PNG pairs (`pending: T1`). Each `<img>` has alt text stating the diagram's point.
12. **Spec, plan and exec-room docs ship in the repo** as a worked example of the workflow on itself.
13. **Comparison table** (owner): README section "How it compares", after Proof and before "Where this
    came from". Columns: lean-sdd, obra/superpowers, GitHub spec-kit, plain Claude Code. Rows are
    yes/no/partial features (e.g. size triage that skips small tasks, fixed approval gates, falsifiable
    ACs with check commands, parallel worktree build, per-task review, multi-seat milestone panel,
    spec converge with verdicts, usage guard, retro that edits the workflow, agent/editor support,
    install method, dependencies). Plus a "Trade-offs" list of lean-sdd's cons (needs superpowers,
    Claude Code only, GitHub-only merge scripts, one maintainer, young). Every non-lean-sdd cell is checked
    against that project's current docs, and the sources are listed under the table with the check date. No
    cost, speed or quality numbers (Non-goal 1). A research task in the plan fills it; cells it cannot
    source say "unverified" and get cut before merge.

14. **One-line install** (owner, after spec approval): the README install block is one copy-paste shell
    line, `claude plugin marketplace add alchristleo/lean-sdd && claude plugin install lean-sdd@lean-sdd`,
    plus the same two `/plugin` commands for use inside a session. T1 checks whether a single command does
    both, and whether it pulls superpowers. No `curl | bash`.
15. **Field notes** (owner, after spec approval): Proof gets a `<details>` table from `docs/field-notes.md`
    (6 agentic-warden milestones: tasks, fix rounds, blocked, triage where logged), each row linked to its
    public plan, captioned "6 milestones, one maintainer, one repo, Oct 2026. Descriptive, not a benchmark."
    No usage numbers, percentages, averages or comparisons.

## Design

```
.claude-plugin/plugin.json        name, version, description, dependencies (if T1 allows)
.claude-plugin/marketplace.json   one-entry marketplace pointing at this repo
skills/lean-sdd/SKILL.md          stack-neutral, paths per Decision 2
skills/lean-sdd/CHANGELOG.md      + origin header line
skills/asd-ste100/...             vendored, with LICENSE
agents/*.md                       10 agents, stack-neutral
scripts/*.sh                      6 scripts + git-hooks/commit-msg, paths per Decision 2
hooks/hooks.json, hooks/usage-guard.py
scripts/statusline-cache.py       cache writer only
docs/diagrams/*.json              4 archify candidates
assets/*-{light,dark}.svg         8 exports
README.md, LICENSE (MIT), THIRD_PARTY_NOTICES.md
test/check.sh                     runs ACs 3-9 locally
```

## Acceptance criteria

Run from the repo root.

1. Plugin manifest and marketplace are valid with no warnings. `claude plugin validate --strict .` exits 0.
2. A clean install exposes 2 skills (lean-sdd, asd-ste100), 10 agents, and the usage-guard hook on
   UserPromptSubmit and PostToolUse. Check: `test/install-smoke.sh`: sets a temp `CLAUDE_CONFIG_DIR`, runs
   `claude plugin marketplace add ./ && claude plugin install lean-sdd@lean-sdd`, then parses the installed
   plugin dir (or `details --json` if T1 finds it), asserts those counts and that every `scripts/*.sh` is executable.
3. No machine-specific paths. `test -s skills/lean-sdd/SKILL.md && [ $(ls agents/*.md | wc -l) -eq 10 ] && test -d scripts && test -d hooks && ! grep -rnE --exclude=CHANGELOG.md '/home/|~/\.claude/' skills agents scripts hooks`
   exits 0. Positive control: the same grep on the original `~/.claude` copies finds hits.
4. Rules are stack-neutral. `test -s skills/lean-sdd/SKILL.md && [ $(ls agents/*.md | wc -l) -eq 10 ] && ! grep -rniwE 'tofu|docker|playwright|go test|IdP|Entra|App\.tsx|ECR' skills/lean-sdd/SKILL.md agents`
   exits 0. (CHANGELOG excluded by Decision 8.) Positive control: 9 hits on the original copies.
5. README has 4 diagrams, each a `<picture>` with a dark and a light source whose files exist.
   `test/check.sh readme` counts 4 `<picture>`, 4 dark + 4 light sources, 8 existing non-empty files,
   each light/dark pair byte-different, 4 `alt` texts of ≥ 5 words. If archify cannot export a dark SVG,
   T1 switches Decision 11 to PNG pairs and this AC checks `.png`.
6. Hero fits one screen: the workflow `<picture>` starts before README line 30 and the install block before line 45.
   `test/check.sh hero`.
7. No unbacked cost or comparison claim. `! grep -niE 'token (cost|saving)|cheaper|fewer gates than|faster than superpowers' README.md` exits 0.
8. Max 3 GitHub alerts, 0 badges. `[ $(grep -c '^> \[!' README.md) -le 3 ] && ! grep -q 'shields.io' README.md`.
9. Third-party notices present. `grep -q 'Dustin Yuchen Teng' THIRD_PARTY_NOTICES.md && grep -q 'tt-a1i' THIRD_PARTY_NOTICES.md && test -f skills/asd-ste100/LICENSE`.
10. Scripts are clean. `shellcheck scripts/*.sh scripts/git-hooks/commit-msg` exits 0.
11. Usage guard pipeline works without the personal status line: piping a sample status-line JSON with
    `rate_limits.five_hour.used_percentage=96` into `scripts/statusline-cache.py`, then running
    `hooks/usage-guard.py`, prints `USAGE GUARD`. Check: `test/check.sh guard` (temp state dir).
12. Trailer hook is opt-in: a fresh install writes nothing to `.git/hooks`. Check: `test/install-smoke.sh`
    asserts `.git/hooks/commit-msg` absent in its scratch repo after a session-free install.
13. Every number and claim in the README traces to a CHANGELOG line, the skill, or a sdd-metrics line. `check: seat panel-cdo`.
14. Diagrams render readable in GitHub light and dark mode, README reads as a polished, quiet page against
    the reference bar (ripgrep, charmbracelet/glow, obra/superpowers). `check: seat panel-cdo`.
15. Stack-neutral rewrites keep each rule's meaning (no rule weakened or dropped). `check: seat panel-correctness`.
16. Comparison table has 4 tool columns, ≥ 8 feature rows, a Trade-offs list with ≥ 4 cons, a sources
    line with a check date, and no "unverified" cell. `test/check.sh compare`. Each cell matches its
    cited source: `check: seat panel-cdo`.
17. Owner's own setup runs from the plugin; old `~/.claude` copies are backed up and removed (so they
    can't shadow plugin agents); `~/.claude/CLAUDE.md` agent names match the T1 naming. `check: owner at gate`.

18. Install is one line: the README's first fenced `bash` block is exactly one line, and it is the command
    `test/install-smoke.sh` runs (with the local path swapped for the repo slug). `test/check.sh install`.
19. Field-notes table: 6 rows, each linked to an agentic-warden plan, values equal to `docs/field-notes.md`,
    caption present, no `%` in the table. `test/check.sh fieldnotes`. Values match `sdd-metrics.sh` on each plan: `check: seat panel-cdo`.

## Security notes

Trust boundary is small: the plugin installs a hook that runs on every prompt and scripts that call
`git` and `gh`. `panel-security` reviews: the hook reads only its own cache file, scripts quote all
arguments, `pr-merge.sh` refuses a moved head, the trailer hook is opt-in and writes only inside `.git/`.
