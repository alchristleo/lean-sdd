# T1 findings: plugin prototype

Date: 2026-10-26. Claude Code 2.1.310. Probe plugin: 1 skill, 1 agent, 1 script, 1 hook, plugin and
marketplace both named `lean-sdd`. Every install used a temp `CLAUDE_CONFIG_DIR`. The probe fixtures are
removed from the repo (they were `test/fixtures/probe-plugin/`).

Method for runtime checks: `claude -p` against a local mock of the Messages API. The mock script
(`test/fixtures/mock-messages-api.py`) and the driver (`test/fixtures/t1-runtime-probe.sh`) are kept. The
probe plugin itself is not kept. The mock replied with scripted `Skill` and `Agent` tool calls and logged
every request body. No real model was called and no real credentials were used. The substitution of
`${CLAUDE_PLUGIN_ROOT}` happens in the Claude Code client before the request leaves, so the mock could
not fake it: the substituted text is what the client sent.

Common setup for every command below (`$SP` is a scratch dir, `$W` is the repo root):

```
export CLAUDE_CONFIG_DIR=$SP/cfg1
cd $W && claude plugin marketplace add ./test/fixtures/probe-plugin   # fixture since removed
claude plugin install lean-sdd@lean-sdd
```

Output of those two: `Successfully added marketplace: lean-sdd (declared in user settings)` then
`Successfully installed plugin: lean-sdd@lean-sdd (scope: user)`.

Runtime driver, per step `skill`, `agent-prefixed`, `agent-bare`:

```
export ANTHROPIC_BASE_URL=http://127.0.0.1:18765 ANTHROPIC_API_KEY=sk-ant-fake
python3 -I test/fixtures/mock-messages-api.py 18765 $SP/mock.log &
claude -p "STEP skill" --dangerously-skip-permissions --output-format text
claude -p "STEP agent-prefixed" --dangerously-skip-permissions --output-format text
claude -p "STEP agent-bare" --dangerously-skip-permissions --output-format text
```

## Verdict

- Decision 2 path shape **A holds**. Shape B is not needed.
- Decision 11 is not touched by T1 (see T2).
- Decision 14: one command can add the marketplace and install (finding 5). The plugin declares no
  superpowers dependency (finding 4), so the README lists superpowers as a prerequisite.

## 1. `${CLAUDE_PLUGIN_ROOT}` substitution: YES in skill, agent and hook

Command: `claude -p "STEP skill" ...` (mock sends a `Skill` call with `skill: lean-sdd:probe`).
Skill body `ROOT=${CLAUDE_PLUGIN_ROOT}` and `QUOTED="${CLAUDE_PLUGIN_ROOT}"/scripts/probe.sh`, tool result of
the `Skill` call (`lean-sdd:probe`):

```
ROOT=/home/leo/.../test/fixtures/probe-plugin
QUOTED="/home/leo/.../test/fixtures/probe-plugin"/scripts/probe.sh
```

Command: `claude -p "STEP agent-prefixed" ...`, then the system prompt of the sub-agent request was read from `$SP/mock.log`.
Agent body `Reply exactly: PROBE-AGENT-OK ROOT=${CLAUDE_PLUGIN_ROOT}`, as seen in the sub-agent's request
system prompt:

```
Reply exactly: PROBE-AGENT-OK ROOT=/home/leo/.../test/fixtures/probe-plugin
```

Hook: no extra command, the 3 `claude -p` runs above (plus 1 earlier run) each fired it, then `cat $CLAUDE_CONFIG_DIR/hook.log`.
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

Commands: `claude -p "STEP agent-prefixed" ...` and `claude -p "STEP agent-bare" ...`.

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

## 4. `dependencies` on `superpowers@claude-plugins-official`: works, but NOT DECLARED (owner decision)

Owner decision after review: the plugin declares no dependency. `plugin.json` has no `dependencies` and
`marketplace.json` has no `allowCrossMarketplaceDependenciesOn`. superpowers is a README prerequisite
("install superpowers first"). The test results below are kept as the reason the decision is safe.

Commands per case (`$SP/dep` = probe copy with `"dependencies": ["superpowers@claude-plugins-official"]`
in `plugin.json`; `$SP/dep2` = same without `allowCrossMarketplaceDependenciesOn`; each case has its own
`CLAUDE_CONFIG_DIR`):

```
# case 1
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin marketplace add $SP/dep
claude plugin install lean-sdd@lean-sdd
claude plugin list
# case 2: same, with $SP/dep2
# case 3: same, without the first line
```

| Case | Result |
|---|---|
| 1. Official marketplace added first, allow-list present | `Successfully installed plugin: lean-sdd@lean-sdd (scope: user) (+ 1 dependency: superpowers)`. Both `Status: enabled`. superpowers 7.0.0. |
| 2. Official marketplace added, allow-list absent | install rc 0, then `Status: failed to load`, `Dependency "superpowers@claude-plugins-official" is not installed` |
| 3. Official marketplace not added | install rc 0 with `Warning: dependency "superpowers@claude-plugins-official" was not installed (no marketplace you have added lists it). "lean-sdd" will not load without it` |

`validate --strict` passed in both manifest forms. With no declared dependency, none of these failure
modes can happen, and the README tells the user to install superpowers first.

## 5. One command and `details`

- Command: `claude plugin install --marketplace $SP/dep lean-sdd` (fresh `CLAUDE_CONFIG_DIR`, official marketplace added before). Output: `Adding marketplace…`, `Successfully added marketplace: lean-sdd`, `Successfully installed plugin: lean-sdd@lean-sdd (scope: user) (+ 1 dependency: superpowers)`. It adds the marketplace and installs in one command
  (tested with a local path, official marketplace already added: `(+ 1 dependency: superpowers)`).
  `<source>` accepts `owner/repo`, URL or path per `--help`. The GitHub form is untested (no remote yet).
- Command: `claude plugin marketplace add <src> && claude plugin install lean-sdd@lean-sdd`. The two-command form also works (AC2 uses it).
- Command: `claude plugin details --json lean-sdd`. Output: `error: unknown option '--json'`, rc 1. `claude plugin details lean-sdd` prints text: `Skills (1)`, `Agents (1)`, `Hooks (1)  UserPromptSubmit`. The smoke test parses
  the installed dir instead. `claude plugin list --json` exists.

## 6. Isolation: YES

Command run after all installs: `grep -c lean-sdd ~/.claude/plugins/known_marketplaces.json ~/.claude/plugins/installed_plugins.json ~/.claude/settings.json`.

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
