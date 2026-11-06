# Lite edits

`build-lite.py` applies these blocks to the copied files before it rewrites agent prefixes.
Each block sits under a heading `## <path>` and has this shape, with the markers alone on their lines:

    <<<<
    exact full text, found exactly once in that file
    ====
    lite text
    >>>>

The build fails and names the path and the first anchor line when the anchor is not found exactly once.

## skills/lean-sdd/SKILL.md
<<<<
Needs Claude Code. If the Agent tool or the `lean-sdd:` agents are missing (claude.ai chat
====
Needs Claude Code. If the Agent tool or the `lean-sdd-lite:` agents are missing (claude.ai chat
>>>>

<<<<
- Trailer hook, only if the user asked for commit trailers, in this session or in the project's CLAUDE.md (otherwise skip it; never install it unasked), so subagent commits never need rewriting:
  `"${CLAUDE_PLUGIN_ROOT}"/scripts/install-git-hooks.sh "<trailer lines from the system attribution reminder, one per line>"`
  Re-run at every session start and whenever the attribution reminder changes (it can change mid-session).
- Usage: `cat "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/state/usage.json"` (written by the status line). Pause threshold 95%
  unless the user says otherwise. Obey `USAGE GUARD` messages from the hook.
====
- Trailers, only if the user asked for them in this session or in the project's CLAUDE.md. Then tell every subagent to end its commit message with the trailer lines from the system attribution reminder. Otherwise add none.
- Usage: read the 5h and 7d percentages the status line shows. Pause threshold 95%
  unless the user says otherwise. If the user sends a pause message, follow the Pause / resume section.
>>>>

<<<<
- Ledger stays (pause/resume), one line per event, appended with `"${CLAUDE_PLUGIN_ROOT}"/scripts/sdd-log.sh <plan> <line>`
  (it refuses formats not in the `"${CLAUDE_PLUGIN_ROOT}"/scripts/sdd-metrics.sh` header). Run sdd-metrics.sh after each panel round (it lints).
  A `fix` = one reviewer fix-needed verdict on a task; the re-review that passes is `done`.
====
- Ledger stays (pause/resume), one line per event. Append each line with the Edit tool at the end of the last `## Ledger` section of the plan doc.
  Lite does not check the format, so use only these (the first word is the line type):
  - `T<n>[a-z] done <sha> <agent> <note>` (task done; the re-review that passes is `done`)
  - `T<n>[a-z] fix <sha> <reviewer> fix-needed <note>` (one fix round = one reviewer fix-needed verdict on a task)
  - `T<n>[a-z] coord <sha> <note>` (coordinator fix, 10 lines or fewer)
  - `T<n>[a-z] blocked <sha> <agent> <note>`
  - `T<n>[a-z] review <approve|fail> <sha> <agent> <note>`
  - `SEAT <seat> <pass|fail> <sha> AC<n> [note]` (one line per AC a seat rules on)
  - `SEAT owner pass <sha> AC<n>` (owner yes on a `check: owner` AC)
  - `PANEL <seat> <sha> must=<n> should=<n> nit=<n>` (a later PANEL of the same seat = re-run)
  - `PANEL <seat> skipped <reason>`
  - `TRIAGE fixed=<n> dismissed=<n> backlog=<n>` (after the panel round)
  - `FIX wave <sha> <agent> <note>`
  - `USAGE start|end <5h%>` (at start, pause, resume and merge)
  - `COORD`, `CONVERGE`, `DISMISSED`, `MERGE`, `MERGED`, `PAUSED`, `PLAN`, `PR` and `RESUME` lines, each followed by a note.
>>>>

<<<<
`"${CLAUDE_PLUGIN_ROOT}"/scripts/review-pkg.sh <task-base-sha>` → prints package path (diff, diffstat,
trailer check). Dispatch `lean-sdd:sdd-reviewer` (or `lean-sdd:sdd-reviewer-lite` for lite tasks) with the
path + task brief.
====
Build the review package with this command. Replace `<base>` with the task base sha and keep the rest as written.
It prints the package path (commits, diffstat, diff).

```bash
base=<base>
head=$(git rev-parse --short HEAD)
out=$(git rev-parse --path-format=absolute --git-common-dir)/review-pkg-$(git rev-parse --short "$base")-$head.md
{
  echo "# Review package: $base..HEAD"
  echo
  echo "## Commits"
  git log --format='- %h %s' "$base..HEAD"
  echo
  echo "## Diffstat"
  echo '```'
  git diff --stat "$base..HEAD" -- ':(top)' ':(top,exclude)docs/superpowers'
  echo '```'
  echo
  echo "## Diff"
  echo '```diff'
  git diff "$base..HEAD" -- ':(top)' ':(top,exclude)docs/superpowers'
  echo '```'
} > "$out"
echo "$out"
```

Dispatch `lean-sdd:sdd-reviewer` (or `lean-sdd:sdd-reviewer-lite` for lite tasks) with the
path + task brief.
>>>>

<<<<
wave or coord fixes) gets that seat re-run on the fix diff only (`review-pkg.sh <pre-fix sha>`),
====
wave or coord fixes) gets that seat re-run on the fix diff only (the step 6 command with `<base>` set to the pre-fix sha),
>>>>

<<<<
- After the PR opens, and again after every push to the PR branch: `"${CLAUDE_PLUGIN_ROOT}"/scripts/pr-checks-wait.sh <pr>`
  (exit 1 = a check failed, or the head moved during the wait: re-run it; 3 = gh error or no checks). The merge gate quotes the head sha it printed. CI red → fix before merge. ACs checked on PR
  CI get their spec edit committed to the branch before the merge, never after.
- Merge with `"${CLAUDE_PLUGIN_ROOT}"/scripts/pr-merge.sh <pr> <head sha>`: it refuses a moved head, merges, and
  prints any branch commit missing from the base (exit 3 = lost work; land it on main).
====
- After the PR opens, and again after every push to the PR branch, wait for the checks:
  Run this block in one Bash call. Replace `<pr>` first. It does the whole wait, so do not run `sleep` as a separate call.
   ```bash
   pr=<pr>
   deadline=$(( $(date +%s) + 1200 ))
   sleep 15
   while :; do
     before=$(gh pr view "$pr" --json commits -q '.commits[-1].oid' 2>/dev/null)
     out=$(gh pr checks "$pr" 2>&1)
     sha=$(gh pr view "$pr" --json commits -q '.commits[-1].oid' 2>/dev/null)
     if [ "$before" != "$sha" ]; then
       echo "head moved (${before:-unknown} -> ${sha:-unknown}): run the wait again"; exit 1
     fi
     status=$(printf '%s\n' "$out" | awk -F'\t' 'NF >= 2 { print $2 }')
     if ! printf '%s\n' "$status" | grep -qxE 'pass|fail|pending|queued|in_progress|skipping|cancelled|timed_out|action_required'; then
       echo "$out"; echo "gh error or no checks listed: stop and report"; exit 3
     fi
     if ! printf '%s\n' "$status" | grep -qxE 'pending|queued|in_progress'; then
       echo "$out"; echo "head $sha"
       printf '%s\n' "$status" | grep -qxE 'fail|cancelled|timed_out|action_required' && { echo "CI is red"; exit 1; }
       exit 0
     fi
     [ "$(date +%s)" -ge "$deadline" ] && { echo "$out"; echo "timeout after 20 minutes"; exit 2; }
     sleep 20
   done
   ```
  The block reads the status column, which is the second tab-separated field. It does not match words anywhere else in the line. Act on the result:
  1. Exit 0: nothing is pending and nothing failed. The last line is `head <sha>`. Record that sha as the head sha. It must be the full 40 hex characters.
  2. Exit 1 with "head moved": a push landed during the wait. Run the block again.
  3. Exit 1 with "CI is red": a check failed, was cancelled, timed out or needs action. Fix it before the merge.
  4. Exit 2: the checks did not finish in 20 minutes. Stop and report the timeout.
  5. Exit 3: gh printed an error or listed no checks. Stop and report. Do not loop.
  The merge gate quotes the head sha. CI red → fix before merge. ACs checked on PR
  CI get their spec edit committed to the branch before the merge, never after.
- Merge in this order:
  0. Run `gh pr view <pr> --json headRefName,baseRefName` to read `<branch>` and `<base>`.
  1. Run `git ls-remote origin refs/heads/<branch>`. If the output is empty or the sha differs from the recorded head sha, the head moved. Stop and run the wait again.
  2. Run `git fetch origin`, then repeat step 1.
  3. Run `gh pr merge <pr> --merge`. If it fails, stop and report. Do not run step 4.
  4. Run `git fetch origin`, then `git log --oneline origin/<base>..origin/<branch>`. A non-empty list is lost work: land it on main.
>>>>

<<<<
- **Numbers:** paste the line from `"${CLAUDE_PLUGIN_ROOT}"/scripts/sdd-metrics.sh <plan>` (tasks, fix rounds,
  coord fixes, blocked, findings per seat, triage, 5h usage).
====
- **Numbers:** count the plan's ledger lines by type and write one line (tasks done, fix rounds,
  coord fixes, blocked, findings per seat, triage, 5h usage).
>>>>

<<<<
- **Workflow lessons** (this skill, the plugin's `agents/` and `scripts/`): propose the edit
====
- **Workflow lessons** (this skill and the plugin's `agents/`): propose the edit
>>>>

## agents/sdd-implementer.md
<<<<
 Run `python3 -I "${CLAUDE_PLUGIN_ROOT}"/skills/asd-ste100/scripts/ste-lint.py <changed .md files>` on docs you wrote; fix hard violations.
- Commit with a conventional message. The commit-msg hook adds the trailer; never amend for trailers.
====
 Re-read the docs you wrote and fix every violation.
- Commit with a conventional message. End it with the trailer lines the brief gives, if any. Never amend just to fix trailers.
>>>>

## agents/sdd-implementer-lite.md
<<<<
 Run `python3 -I "${CLAUDE_PLUGIN_ROOT}"/skills/asd-ste100/scripts/ste-lint.py <changed .md files>` on docs you wrote; fix hard violations.
- Commit with a conventional message. The commit-msg hook adds the trailer; never amend for trailers.
====
 Re-read the docs you wrote and fix every violation.
- Commit with a conventional message. End it with the trailer lines the brief gives, if any. Never amend just to fix trailers.
>>>>

## agents/sdd-reviewer.md
<<<<
(from review-pkg.sh)
====
(from the coordinator's review command)
>>>>

<<<<
, trailer check line in the package.
====
.
>>>>

## agents/sdd-reviewer-lite.md
<<<<
 nothing outside its scope changed, trailer check is ok.
====
 nothing outside its scope changed.
>>>>

<<<<
The trailer to check is the one in `.git/claude-trailer` (installed by the commit-msg hook), never the model named in your own attribution reminder.

====
>>>>

## skills/asd-ste100/SKILL.md
<<<<
 For a mechanical first pass over the structural rules, run `scripts/ste-lint.py` (stdin or file args, `--json` for structured output); it checks semicolons, sentence length, phrasal verbs, nominalization, marketing adjectives, synonym rotation, dangling-conjunction in supported list items, passive voice, and compound tenses, and by design never flags hedges or modality. `--baseline N` tolerates N hard violations (for adopting on existing docs); `--disable rule1,rule2` silences named rules.
====
 For a first pass over the structural rules, check by hand for semicolons, long sentences, phrasal verbs, nominalization, marketing adjectives, synonym rotation, dangling conjunctions in list items, passive voice, and compound tenses. Hedges and modality are content: never flag them.
>>>>

<<<<
- **`examples/before-after.md`** — worked examples, including official STE examples and agent-output examples built for this skill.
- **`scripts/ste-lint.py`** — deterministic, stdlib-only linter for the structural rules, including dangling-conjunction in supported list items, plus a synonym-rotation check (one word, one meaning) scoped per file. Exit 1 when hard violations exceed `--baseline` (default 0); advisory findings (passive voice, compound tenses) never fail the run; `--disable` silences named rules. It never flags hedges or modality: those are content, not style, and `--selftest` asserts that "may have failed" passes clean.
====
- **`examples/before-after.md`** — worked examples, including official STE examples and agent-output examples built for this skill.
>>>>

## skills/lean-sdd/SKILL.md
<<<<
On a `USAGE GUARD` pause message or a user request:
====
When usage reaches the pause threshold or the user asks:
>>>>
