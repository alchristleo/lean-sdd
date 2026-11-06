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
