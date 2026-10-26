#!/usr/bin/env bash
# One-line lean-sdd retro numbers per '## Ledger*' section of a plan doc (lints the ledger too).
# Usage: sdd-metrics.sh <plan.md>
# Ledger line formats (one event per line; the first word is the line type; sdd-log.sh reads this list):
#   T<n>[a-z] done <sha> <agent> <note>              task done (or re-review passed)
#   T<n>[a-z] fix <sha> <reviewer> fix-needed <note>   one fix round = one reviewer fix-needed verdict on a task
#   T<n>[a-z] coord <sha> <note>                     coordinator fix (<= 10 lines); its review line names the reviewer
#   T<n>[a-z] blocked <sha> <agent> <note>
#   T<n>[a-z] review <approve|fail> <sha> <agent> <note>  per-task review verdict
#   SEAT <seat> <pass|fail> <sha> AC<n> [note]        one line per AC a seat rules on
#   SEAT owner pass <sha> AC<n>                        owner yes on a `check: owner` AC
#   PANEL <seat> <sha> must=<n> should=<n> nit=<n>    per seat report (a later PANEL of the same seat = re-run)
#   PANEL <seat> skipped <reason>
#   TRIAGE fixed=<n> dismissed=<n> backlog=<n>        after the panel round
#   FIX wave <sha> <agent> <note>                     one panel fix wave
#   USAGE start|end <5h%>                             at start, pause, resume and merge (pairs are summed)
#   Free-note types: COORD CONVERGE DISMISSED MERGE MERGED PAUSED PLAN PR RESUME
# Any other first word inside a ledger section warns (e.g. OWNER: use SEAT owner pass).
set -eu
plan="${1:?usage: sdd-metrics.sh <plan.md>}"
# Lint: ledger-looking lines outside a '## Ledger*' section.
awk '/^## Ledger/{on=1;next} /^## /{on=0} !on && /^(T[0-9]+[a-z]? (done|fix|blocked|coord)|SEAT|USAGE|PANEL|TRIAGE|FIX wave) /{printf "warn: line %d outside a ## Ledger section: %s\n", NR, substr($0,1,60)}' "$plan" >&2
nsec=$(grep -c '^## Ledger' "$plan" || true)
for i in $(seq 1 "$nsec"); do
  title=$(grep '^## Ledger' "$plan" | sed -n "${i}p" | sed 's/^## //')
  awk -v want="$i" '/^## Ledger/{n++; on=(n==want); next} /^## /{on=0} on{printf "%d\t%s\n", NR, $0}' "$plan" |
  awk -F'\t' -v multi="$([ "$nsec" -gt 1 ] && echo 1 || echo 0)" -v title="$title" '
  function w(msg) { printf "warn: line %d %s: %s\n", $1, msg, substr($2,1,70) > "/dev/stderr" }
  {
    line=$2; split(line, f, " "); t=f[1]
    if (line ~ /^[[:space:]]*$/ || line ~ /^```/) next
    if (t ~ /^T[0-9]+[a-z]?$/) {
      if (f[2]=="done") done[t]=1
      else if (f[2]=="fix") fixes++
      else if (f[2]=="blocked") blk[t]=1
      else if (f[2]=="coord" && f[4] !~ /^sdd-reviewer/) coord++
      if (f[2]!="fix" && match(line, / fix[0-9]+/)) fixes += substr(line, RSTART+4, RLENGTH-4)
    } else if (t=="SEAT") {
      ac = (line ~ / AC[0-9]+/)
      if (!ac) w("SEAT without AC<n> (not counted)")
      if (f[2]=="owner") { if (ac) owner++ }
      else if (ac) {
        if (f[3]=="pass") sp++; else if (f[3]=="fail") sf++
        if ((f[2] in seatsha) && seatsha[f[2]]!=f[4] && !((f[2] SUBSEP f[4]) in rr)) { rr[f[2], f[4]]=1; reruns++ }
        if (!(f[2] in seatsha)) seatsha[f[2]]=f[4]
      }
    } else if (t=="PANEL") {
      if (f[3]=="skipped") panel = panel sep f[2] " skipped"
      else if (f[4] ~ /^must=/ && f[5] ~ /^should=/ && f[6] ~ /^nit=/) {
        tag = (f[2] in seen) ? "(re-run)" : ""; seen[f[2]]=1
        panel = panel sep f[2] tag " " substr(f[4],6) "/" substr(f[5],8) "/" substr(f[6],5)
      } else { w("PANEL off-format"); next }
      sep="; "
    } else if (t=="TRIAGE") {
      if (line ~ /^TRIAGE fixed=[0-9]+ dismissed=[0-9]+ backlog=[0-9]+/) triage=substr(line,8)
      else w("TRIAGE off-format")
    } else if (t=="FIX") { if (f[2]=="wave") waves++ }
    else if (t=="USAGE") {
      if (f[2]=="start") { if (s!="") { us = us usep s "→?"; usep="," } s=f[3]+0 }
      else if (f[2]=="end") { if (s!="") { us = us usep s "→" f[3]+0; usep=","; pts += f[3]-s; s="" } else w("USAGE end without start") }
    } else if (t !~ /^(COORD|CONVERGE|DISMISSED|MERGE|MERGED|PAUSED|PLAN|PR|RESUME)$/) w("unknown ledger line type \"" t "\"")
  }
  END {
    if (s!="") us = us usep s "→?"
    for (k in done) tasks++; for (k in blk) blocked++
    printf "%stasks=%d fix_rounds=%d coord=%d fix_waves=%d blocked=%d seats pass/fail=%d/%d reruns=%d owner=%d panel(must/should/nit)=[%s] triage=[%s] 5h=%s\n",
      (multi ? "[" title "] " : ""), tasks, fixes, coord, waves, blocked, sp, sf, reruns, owner,
      (panel=="" ? "n/a" : panel), (triage=="" ? "n/a" : triage), (us=="" ? "?" : us " (" pts "pt)")
  }'
done
