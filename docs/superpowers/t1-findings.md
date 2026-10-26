# T1 findings: plugin prototype

Date: 2026-10-26. Claude Code 2.1.310. Probe plugin: 1 skill, 1 agent, 1 script, 1 hook, plugin and
marketplace both named `lean-sdd`. Every install used a temp `CLAUDE_CONFIG_DIR`. The probe fixtures are
removed from the repo (they were `test/fixtures/probe-plugin/`).

Method for runtime checks: `claude -p` against a local mock of the Messages API
(`ANTHROPIC_BASE_URL=http://127.0.0.1:18765`, fake key). The mock replied with scripted `Skill` and `Agent`
tool calls and logged every request body. No real model was called and no real credentials were used.

## Verdict

- Decision 2 path shape **A holds**. Shape B is not needed.
- Decision 11 is not touched by T1 (see T2).
- Decision 14: one command can add the marketplace and install, but `superpowers` only installs as a
  dependency if its marketplace (`claude-plugins-official`) is already added. See finding 4.

## 1. `${CLAUDE_PLUGIN_ROOT}` substitution: YES in skill, agent and hook

Skill body `ROOT=${CLAUDE_PLUGIN_ROOT}` and `QUOTED="${CLAUDE_PLUGIN_ROOT}"/scripts/probe.sh`, tool result of
the `Skill` call (`lean-sdd:probe`):

```
ROOT=/home/leo/.../test/fixtures/probe-plugin
QUOTED="/home/leo/.../test/fixtures/probe-plugin"/scripts/probe.sh
```

Agent body `Reply exactly: PROBE-AGENT-OK ROOT=${CLAUDE_PLUGIN_ROOT}`, as seen in the sub-agent's request
system prompt:

```
Reply exactly: PROBE-AGENT-OK ROOT=/home/leo/.../test/fixtures/probe-plugin
```

`hooks.json` command `"${CLAUDE_PLUGIN_ROOT}"/scripts/probe.sh >> "${CLAUDE_CONFIG_DIR}/hook.log"` on
`UserPromptSubmit` ran on every prompt (4 log lines for 4 prompts):

```
probe script ran; env CLAUDE_PLUGIN_ROOT=[/home/leo/.../test/fixtures/probe-plugin]
```

Notes:
- The hook process also sees `CLAUDE_PLUGIN_ROOT` and `CLAUDE_CONFIG_DIR` in its env. Scripts that run from
  the Bash tool are not covered by this test. Keep the rule from Decision 2: scripts find each other with
  `$(dirname "$0")`.
- With a local-path marketplace the runtime root was the source directory, not the cache copy. Do not
  hard-code either.
- `validate --strict` needs `author` in `plugin.json`, in the marketplace entry, and a
  marketplace `description`. Without them it warns and exits 1.

## 2. Exec bit in the plugin cache: KEPT

```
$ ls -l $CLAUDE_CONFIG_DIR/plugins/cache/lean-sdd/lean-sdd/0.0.1/scripts
-rwxr-xr-x 1 leo leo 82 Oct 26 23:51 probe.sh
```

Source mode was 755. A source file with mode 644 stays 644 in the install (`test/install-smoke.sh` on a
copy with `chmod 644` printed `FAIL every scripts/*.sh executable (1 not)`). Commit scripts with the exec bit.

## 3. `subagent_type` for plugin agents: `lean-sdd:<agent>`

```
STEP agent-prefixed  subagent_type "lean-sdd:probe-agent" -> Agent launched, sub-agent system prompt
                     contained the agent body (request 3 in the mock log)
STEP agent-bare      subagent_type "probe-agent" -> tool result (is_error):
  Agent type 'probe-agent' not found. Available agents: claude, Explore, general-purpose,
  lean-sdd:probe-agent, Plan, statusline-setup
```

Rename sweep: every `subagent_type` and every agent mention in SKILL.md, README and the owner's
CLAUDE.md becomes `lean-sdd:<agent>`. Old copies in `~/.claude/agents` would register under the bare name
and may shadow, so AC17 stays.

## 4. `dependencies` on `superpowers@claude-plugins-official`: WORKS with two conditions

`plugin.json`: `"dependencies": ["superpowers@claude-plugins-official"]`. `marketplace.json`:
`"allowCrossMarketplaceDependenciesOn": ["claude-plugins-official"]`. `validate --strict` passes with both.

| Case | Result |
|---|---|
| Official marketplace added first, allow-list present | `Successfully installed plugin: lean-sdd@lean-sdd (+ 1 dependency: superpowers)`. Both `Status: enabled`. superpowers 7.0.0. |
| Official marketplace added, allow-list absent | install rc 0, then `Status: failed to load`, `Dependency "superpowers@claude-plugins-official" is not installed` |
| Official marketplace not added | install rc 0 with `Warning: dependency ... was not installed (no marketplace you have added lists it). "lean-sdd" will not load without it` |

Consequence: the install block must make sure `claude-plugins-official` is added. A fresh
`CLAUDE_CONFIG_DIR` does not have it. The owner's real config has it (auto-added by the app), so a normal
user probably has it too, but this is not proven for a fresh machine. Safe one-liner for the README:
`claude plugin marketplace add anthropics/claude-plugins-official && claude plugin marketplace add alchristleo/lean-sdd && claude plugin install lean-sdd@lean-sdd`
(first add is a no-op if present: not tested). Decision 14 says the block is one line, so the README author
must pick: the 2-command line plus a note, or the 3-command line. `install-smoke.sh` stays offline and
does not add the official marketplace, so it sees the dependency warning, which AC2 allows.

## 5. One command and `details`

- `claude plugin install --marketplace <source> lean-sdd` adds the marketplace and installs in one command
  (tested with a local path, official marketplace already added: `(+ 1 dependency: superpowers)`).
  `<source>` accepts `owner/repo`, URL or path per `--help`. The GitHub form is untested (no remote yet).
- The two-command form `marketplace add <src> && install lean-sdd@lean-sdd` also works (AC2 uses it).
- `claude plugin details --json` does NOT exist (`error: unknown option '--json'`). `claude plugin details
  lean-sdd` prints text: `Skills (1)`, `Agents (1)`, `Hooks (1)  UserPromptSubmit`. The smoke test parses
  the installed dir instead. `claude plugin list --json` exists.

## 6. Isolation: YES

After all installs above, the real config has no trace:

```
grep -c lean-sdd ~/.claude/plugins/known_marketplaces.json ~/.claude/plugins/installed_plugins.json ~/.claude/settings.json
-> 0, 0, 0
```

Plugin state, marketplaces and cache all landed under the temp `CLAUDE_CONFIG_DIR`.

## Not verified

- GitHub-slug install (no remote). The cache-copy path for a git source is assumed to match the
  local-path copy.
- Agent frontmatter fields ignored by plugin agents (hooks, mcpServers, permissionMode): not tested.
  Check in T4 when the real agents land.
- Whether the Bash tool env has `CLAUDE_PLUGIN_ROOT` (not needed under shape A).
