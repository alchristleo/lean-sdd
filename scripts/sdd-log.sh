#!/usr/bin/env bash
# Append one ledger line to the end of a plan's last '## Ledger*' section.
# Usage: sdd-log.sh <plan.md> <line...>
# The line must match a format in the sdd-metrics.sh header (the single list; a trailing note is allowed).
# Otherwise it is refused.
set -eu
plan="${1:?usage: sdd-log.sh <plan.md> <line...>}"; shift
[ $# -gt 0 ] || { echo "usage: sdd-log.sh <plan.md> <line...>" >&2; exit 2; }
exec python3 -I - "$(dirname "$0")/sdd-metrics.sh" "$plan" "$*" <<'PY'
import re, sys
metrics, plan, line = sys.argv[1:]
if "\n" in line or "\r" in line:
    sys.stderr.write("refused: line holds a newline or CR\n"); sys.exit(1)
hdr = open(metrics).read().split("\nset -eu", 1)[0].splitlines()
i = next(n for n, l in enumerate(hdr) if l.startswith("# Ledger line formats"))
formats, free = [], []
for l in hdr[i + 1:]:
    m = re.match(r"#   Free-note types: (.*)", l)
    if m: free = m.group(1).split(); break
    formats.append(re.split(r" {2,}", l[4:].strip())[0])
def rx(fmt):
    out = []
    for tok in re.findall(r"\[note\]|T<n>\[a-z\]|<[^>]+>|[^<\[ ]+| ", fmt):
        if tok == "T<n>[a-z]": out.append(r"T[0-9]+[a-z]?")
        elif tok == "[note]": out[-1:] = [r"( .+)?"]
        elif tok in ("<note>", "<reason>"): out.append(r".+")
        elif tok == "<sha>": out.append(r"[0-9a-f]{7,40}")
        elif tok == "<n>": out.append(r"[0-9]+")
        elif tok == "<5h%>": out.append(r"[0-9]+%?")
        elif tok.startswith("<") and "|" in tok: out.append("(" + tok[1:-1] + ")")
        elif tok.startswith("<"): out.append(r"[^ ]+")
        elif "|" in tok: out.append("(" + tok + ")")
        else: out.append(re.escape(tok))
    return "".join(out)
ok = any(re.fullmatch(rx(f) + r"( .+)?", line) for f in formats) or \
     (line.split(" ", 1)[0] in free and " " in line.strip())
if not ok:
    sys.stderr.write("refused: line matches no ledger format. Allowed:\n" +
        "".join("  " + f + "\n" for f in formats) + "  <" + "|".join(free) + "> <note>\n")
    sys.exit(1)
lines = open(plan).read().split("\n")
heads = [n for n, l in enumerate(lines) if l.startswith("## Ledger")]
if not heads: sys.exit("refused: no '## Ledger' section in " + plan)
end = next((n for n in range(heads[-1] + 1, len(lines)) if lines[n].startswith("## ")), len(lines))
at = end
while at > heads[-1] + 1 and lines[at - 1].strip() == "": at -= 1
if lines[at - 1].startswith("```") and sum(l.startswith("```") for l in lines[heads[-1]:at]) % 2 == 0:
    at -= 1  # closing fence of a fenced ledger
lines.insert(at, line)
open(plan, "w").write("\n".join(lines))
print("logged: " + line)
PY
