# lean-sdd-lite

The Markdown-only edition of [lean-sdd](https://github.com/alchristleo/lean-sdd), a lean spec-driven build workflow for Claude Code. It ships 2 skills and 10 agents.

Install one edition, not both. Both ship skills named `lean-sdd` and `asd-ste100`.

Install superpowers first. lean-sdd-lite does not pull it in.

```bash
claude plugin install superpowers@claude-plugins-official
```

Then install lite:

```bash
claude plugin install --marketplace alchristleo/lean-sdd lean-sdd-lite
```

## What lite drops

- The commit-trailer hook. Subagent commits get no trailer.
- The usage guard and the status line. Nothing pauses the build before you hit the 5-hour or 7-day limit.
- The `asd-ste100` linter. Nothing checks wording by script.
- The ledger format lint. Nothing checks ledger lines by script.
- The metrics line. Claude counts the ledger lines instead.
- The review-package, PR-checks and merge scripts. The skill holds the same commands as text.

Install the full `lean-sdd` plugin to get these back.
