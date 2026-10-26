# Comparison research (fills spec Decision 13)

Check date: 2026-10-26. Every non-lean-sdd cell cites a page fetched on that date. Quotes came through a summarizing fetch and were spot-checked against the source pages (see Notes).
lean-sdd cells cite line numbers in `~/.claude/skills/lean-sdd/SKILL.md` (shown as `SKILL L<n>`), the
version this repo ports. Answers are yes, no or partial. A "no" cell quotes the doc sentence that rules
the feature out, or says "not documented" and names the page that was read. No cost, speed or quality claims.

## Table

| Feature | lean-sdd | obra/superpowers | GitHub spec-kit | Plain Claude Code |
|---|---|---|---|---|
| Size triage that skips small tasks | yes (SKILL L29-36) | partial: trivial requests skip the process, a small change gets a short design doc and approval still applies ([brainstorming](https://raw.githubusercontent.com/obra/superpowers/main/skills/brainstorming/SKILL.md)) | no: not documented, [spec-driven.md](https://raw.githubusercontent.com/github/spec-kit/main/spec-driven.md) describes no scaling to task size | partial: guidance only, "If you could describe the diff in one sentence, skip the plan" ([best-practices](https://code.claude.com/docs/en/best-practices)) |
| Fixed approval gates | yes: spec and merge (SKILL L20-27) | partial: "Nothing gets built until your human partner approves the design doc" and plan review before execution ([brainstorming](https://raw.githubusercontent.com/obra/superpowers/main/skills/brainstorming/SKILL.md), [writing-plans](https://raw.githubusercontent.com/obra/superpowers/main/skills/writing-plans/SKILL.md)). The finishing step offers merge, PR, keep or discard ([README](https://github.com/obra/superpowers)) | partial: workflow `gate` step pauses for human approval ([workflows](https://github.github.io/spec-kit/reference/workflows.html)). The README names no formal gates: "reviewing each result before continuing" ([README](https://github.com/github/spec-kit)) | partial: plan mode makes no edits "until you approve" ([common-workflows](https://code.claude.com/docs/en/common-workflows)). No fixed spec or merge gate |
| Falsifiable acceptance criteria with a check command each | yes (SKILL L84-89) | partial: plan steps give a command and expected result, the docs never use the term acceptance criteria ([writing-plans](https://raw.githubusercontent.com/obra/superpowers/main/skills/writing-plans/SKILL.md)) | partial: "clear acceptance criteria" ([spec-driven.md](https://raw.githubusercontent.com/github/spec-kit/main/spec-driven.md)). Converge checks acceptance criteria against code ([converge.md](https://raw.githubusercontent.com/github/spec-kit/main/templates/commands/converge.md)). No check command per criterion is documented | partial: advice to "Provide verification criteria" in the prompt ([best-practices](https://code.claude.com/docs/en/best-practices)). No spec format |
| Parallel build in isolated worktrees | yes (SKILL L122-123) | partial: implementation subagents run serially, "Never dispatch multiple implementation subagents in parallel (conflicts)". Worktree setup is documented: "use superpowers:using-git-worktrees to create one or verify the existing one" ([subagent-driven-development](https://raw.githubusercontent.com/obra/superpowers/main/skills/subagent-driven-development/SKILL.md), [using-git-worktrees](https://raw.githubusercontent.com/obra/superpowers/main/skills/using-git-worktrees/SKILL.md)). [dispatching-parallel-agents](https://raw.githubusercontent.com/obra/superpowers/main/skills/dispatching-parallel-agents/SKILL.md) never mentions worktrees | partial: tasks marked `[P]` for parallel groups ([tasks.md](https://raw.githubusercontent.com/github/spec-kit/main/templates/commands/tasks.md)). Worktrees not documented ([workflows](https://github.github.io/spec-kit/reference/workflows.html)) | yes: `isolation: worktree` on subagents and `--worktree` ([worktrees](https://code.claude.com/docs/en/worktrees)). `/batch` runs each subagent in its own worktree ([best-practices](https://code.claude.com/docs/en/best-practices)) |
| Per-task review | yes (SKILL L128-136) | yes: "spec compliance AND task quality are both required" ([subagent-driven-development](https://raw.githubusercontent.com/obra/superpowers/main/skills/subagent-driven-development/SKILL.md)) | no: not documented. Converge runs after implement on the whole feature, not per task ([quickstart](https://github.github.io/spec-kit/quickstart.html)) | partial: bundled `/code-review` reviews the current diff in a fresh subagent. Not tied to plan tasks ([best-practices](https://code.claude.com/docs/en/best-practices)) |
| Multi-seat milestone panel (several reviewer lenses) | yes (SKILL L141-152) | no: the review skill dispatches one reviewer, "Dispatch a `general-purpose` subagent" ([requesting-code-review](https://raw.githubusercontent.com/obra/superpowers/main/skills/requesting-code-review/SKILL.md)) | no: not documented. The repo tree lists one `code-review` skill ([repo tree](https://api.github.com/repos/github/spec-kit/git/trees/main?recursive=1)) | partial: you define reviewer subagents yourself, for example `security-reviewer` ([best-practices](https://code.claude.com/docs/en/best-practices)). No built-in review subagent ([sub-agents](https://code.claude.com/docs/en/sub-agents)) |
| Spec converge with a verdict per criterion | yes: VERIFIED, NOT VERIFIED, INCONCLUSIVE (SKILL L169-174) | no: not documented. The skill list has no converge step ([README](https://github.com/obra/superpowers)) | partial: converge reports gaps only, "produce a `Finding` only where there is a gap", outcome `converged` or `tasks_appended` ([converge.md](https://raw.githubusercontent.com/github/spec-kit/main/templates/commands/converge.md)) | no: not documented. No spec checking command in the bundled skills ([skills](https://code.claude.com/docs/en/skills)) |
| Usage guard (pause at a usage threshold) | yes (SKILL L43-46) | no: not documented. The skill list has none ([README](https://github.com/obra/superpowers)) | no: not documented ([quickstart](https://github.github.io/spec-kit/quickstart.html)) | partial: the status line receives `rate_limits` with `five_hour` and `seven_day` `used_percentage` ([statusline](https://code.claude.com/docs/en/statusline)). No built-in pause |
| Retro that edits the workflow | yes (SKILL L185-198) | no: not documented. `writing-skills` creates new skills, no retro step ([README](https://github.com/obra/superpowers)) | no: not documented ([quickstart](https://github.github.io/spec-kit/quickstart.html)) | partial: auto memory, "notes Claude writes itself based on your corrections and preferences" ([memory](https://code.claude.com/docs/en/memory)). It does not edit skills |
| Agent and editor support | Claude Code only (SKILL L119, L124 use Claude Code agent dispatch and `~/.claude` paths) | 16 install entries: Claude Code, Antigravity, Codex App, Codex CLI, Cursor, Devin, Factory Droid, Gemini CLI, Copilot CLI, Grok, Kimi, OpenCode, Pi, Qwen, Hermes, Muse ([README](https://github.com/obra/superpowers)) | 43 integrations incl. `none` and `generic` ([integrations](https://github.github.io/spec-kit/integrations/index.html)) | itself: terminal, desktop app, VS Code and JetBrains ([plugins](https://code.claude.com/docs/en/plugins), [setup](https://code.claude.com/docs/en/setup)) |
| Install method | planned one line: `claude plugin marketplace add alchristleo/lean-sdd && claude plugin install lean-sdd@lean-sdd` (spec Decision 14) | `/plugin install superpowers@claude-plugins-official` ([README](https://github.com/obra/superpowers)) | `uv tool install specify-cli`, then `specify init my-project --integration copilot` ([README](https://github.com/github/spec-kit)) | `curl -fsSL https://claude.ai/install.sh \| bash` ([setup](https://code.claude.com/docs/en/setup)) |
| Dependencies | superpowers (SKILL L8-11, L176 names `superpowers:finishing-a-development-branch`), `gh` for merge scripts, bash | not documented in README ([README](https://github.com/obra/superpowers)) | Python 3.11+, uv, and a supported AI coding agent ([README](https://github.com/github/spec-kit)) | none beyond the install. Needs a Pro, Max, Team, Enterprise or Console account ([setup](https://code.claude.com/docs/en/setup)) |

## Trade-offs (lean-sdd cons)

1. Needs superpowers. SKILL.md hands step 8 to `superpowers:finishing-a-development-branch` and names
   superpowers TDD and systematic-debugging as still used (SKILL L8-11, L176). Claude Code can declare plugin
   dependencies in `plugin.json` ([plugin-dependencies](https://code.claude.com/docs/en/plugin-dependencies)).
2. Claude Code only. The skill dispatches named agents and reads `~/.claude/state` (SKILL L43, L119). The other
   two tools list 16 and 43 agent entries (see the Agent and editor support row).
3. Merge scripts need GitHub. `pr-checks-wait.sh` and `pr-merge.sh` call `gh pr view` and `gh pr merge`
   (SKILL L179-183, `~/.claude/scripts/pr-merge.sh` lines 8-14).
4. One maintainer, young. `git log` shows one author and commits dated 2026-10-26 only. The skill
   CHANGELOG starts 2026-10-23 (`~/.claude/skills/lean-sdd/CHANGELOG.md` line 3).
5. Two fixed human gates on large work. Spec and merge each need an explicit yes (SKILL L20-23). Plain Claude
   Code has no fixed gate (see the Fixed approval gates row).

## Sources (read 2026-10-26)

- https://github.com/obra/superpowers
- https://raw.githubusercontent.com/obra/superpowers/main/skills/brainstorming/SKILL.md
- https://raw.githubusercontent.com/obra/superpowers/main/skills/writing-plans/SKILL.md
- https://raw.githubusercontent.com/obra/superpowers/main/skills/subagent-driven-development/SKILL.md
- https://raw.githubusercontent.com/obra/superpowers/main/skills/requesting-code-review/SKILL.md
- https://raw.githubusercontent.com/obra/superpowers/main/skills/dispatching-parallel-agents/SKILL.md
- https://raw.githubusercontent.com/obra/superpowers/main/skills/using-git-worktrees/SKILL.md
- https://api.github.com/repos/obra/superpowers/git/trees/main?recursive=1
- https://github.com/github/spec-kit
- https://github.com/github/spec-kit/blob/main/docs/installation.md
- https://raw.githubusercontent.com/github/spec-kit/main/spec-driven.md
- https://raw.githubusercontent.com/github/spec-kit/main/templates/commands/converge.md
- https://raw.githubusercontent.com/github/spec-kit/main/templates/commands/tasks.md
- https://api.github.com/repos/github/spec-kit/git/trees/main?recursive=1
- https://github.github.io/spec-kit/quickstart.html
- https://github.github.io/spec-kit/reference/workflows.html
- https://github.github.io/spec-kit/reference/extensions.html
- https://github.github.io/spec-kit/integrations/index.html
- https://code.claude.com/docs/en/best-practices
- https://code.claude.com/docs/en/common-workflows
- https://code.claude.com/docs/en/sub-agents
- https://code.claude.com/docs/en/worktrees
- https://code.claude.com/docs/en/statusline
- https://code.claude.com/docs/en/memory
- https://code.claude.com/docs/en/skills
- https://code.claude.com/docs/en/plugins
- https://code.claude.com/docs/en/plugin-dependencies
- https://code.claude.com/docs/en/setup

## Notes and conflicts

- spec-kit pages disagree on agent count: `docs/installation.md` (re-read 2026-10-26 at
  https://raw.githubusercontent.com/github/spec-kit/main/docs/installation.md) lists 6 agents, the integrations page lists
  43 integrations (41 named agents plus `none` and `generic`). The table uses the integrations page.
- "not documented" is an absence claim from the pages named in the cell. It is not a quote.
- The lean-sdd install cell is planned, not shipped. T1 checks the command.
- Several quotes come from a summarizing fetch tool, not a raw page read. Cell quotes for the superpowers
  skills, spec-kit converge and tasks templates and the Claude Code pages should be spot-checked at the
  panel-cdo seat (AC16).
