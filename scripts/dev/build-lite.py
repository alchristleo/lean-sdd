#!/usr/bin/env python3
"""Build plugin-lite/ from the full plugin. Usage: python3 -I scripts/dev/build-lite.py [--edits FILE] [--out DIR]"""
import argparse, glob, json, os, re, shutil, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

COPY = [
    "skills/lean-sdd/SKILL.md",
    "skills/asd-ste100/SKILL.md",
    "skills/asd-ste100/LICENSE",
    "skills/asd-ste100/examples/*.md",
    "skills/asd-ste100/references/*.md",
    "agents/*.md",
    ".claude-plugin/icon.png",
]

README = """# lean-sdd-lite

The Markdown-only edition of [lean-sdd](https://github.com/alchristleo/lean-sdd), a lean spec-driven build workflow for Claude Code. It ships 2 skills and 10 agents.

Install one edition, not both. Both ship skills named `lean-sdd` and `asd-ste100`.

```bash
claude plugin install --marketplace alchristleo/lean-sdd lean-sdd-lite
```

## What lite drops

- The commit-trailer hook.
- The usage guard and the status line.
- The `asd-ste100` linter.
- The ledger format lint.
- The metrics line. Claude counts the ledger lines instead.
- The review-package, PR-checks and merge scripts. The skill holds the same commands as text.

Install the full `lean-sdd` plugin to get these back.
"""


def die(msg):
    print(msg, file=sys.stderr)
    sys.exit(1)


def parse_edits(path):
    edits, cur, state, buf = [], None, None, []
    with open(path, encoding="utf-8") as f:
        lines = f.read().split("\n")
    for line in lines:
        if state is None:
            if line.startswith("## "):
                cur = line[3:].strip()
            elif line == "<<<<":
                if cur is None:
                    die(f"{path}: edit block before any '## <path>' heading")
                state, buf = "old", []
        elif state == "old" and line == "====":
            old, state, buf = "\n".join(buf), "new", []
        elif state == "new" and line == ">>>>":
            edits.append((cur, old, "\n".join(buf)))
            state = None
        else:
            buf.append(line)
    if state is not None:
        die(f"{path}: unterminated edit block")
    return edits


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--edits", default=os.path.join(ROOT, "scripts/dev/lite-edits.md"))
    ap.add_argument("--out", default=os.path.join(ROOT, "plugin-lite"))
    a = ap.parse_args()
    out = os.path.abspath(a.out)

    files = {}
    for pat in COPY:
        for p in sorted(glob.glob(os.path.join(ROOT, pat))):
            rel = os.path.relpath(p, ROOT)
            with open(p, "rb") as f:
                files[rel] = f.read()

    for rel, old, new in parse_edits(a.edits):
        if rel not in files:
            die(f"{rel}: not a copied file (anchor: {old.split(chr(10))[0]})")
        text = files[rel].decode("utf-8")
        if text.count(old) != 1:
            die(f"{rel}: anchor not found exactly once: {old.split(chr(10))[0]}")
        files[rel] = text.replace(old, new).encode("utf-8")

    names = sorted(os.path.basename(p)[:-3] for p in glob.glob(os.path.join(ROOT, "agents/*.md")))
    pat = re.compile(r"lean-sdd:(" + "|".join(map(re.escape, names + ["<agent>", "<name>"])) + ")")
    for rel in files:
        if rel.endswith(".md"):
            files[rel] = pat.sub(r"lean-sdd-lite:\1", files[rel].decode("utf-8")).encode("utf-8")

    with open(os.path.join(ROOT, ".claude-plugin/plugin.json"), encoding="utf-8") as f:
        full = json.load(f)
    manifest = {
        "name": "lean-sdd-lite",
        "version": full["version"],
        "description": "Lean-sdd without scripts or hooks: Markdown-only skills and agents for the plugin directory.",
        "author": full["author"],
        "license": full["license"],
        "homepage": full["homepage"],
        "repository": full["repository"],
    }
    files[".claude-plugin/plugin.json"] = (json.dumps(manifest, indent=2) + "\n").encode("utf-8")
    files["README.md"] = README.encode("utf-8")

    shutil.rmtree(out, ignore_errors=True)
    for rel, data in files.items():
        dest = os.path.join(out, rel)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        with open(dest, "wb") as f:
            f.write(data)


main()
