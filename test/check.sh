#!/usr/bin/env bash
# Local acceptance checks. Usage: test/check.sh <guard|export|readme|hero|compare|install|fieldnotes>
# export (AC5): the 8 diagram assets exist, pairs differ, no <script, no external refs.
# guard (AC11): status-line sample -> cache -> usage-guard hook, in a temp state dir.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)

guard() {
  local tmp out fail=0
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  export CLAUDE_CONFIG_DIR="$tmp"
  for pct in 96 10; do
    rm -rf "$tmp/state"
    printf '{"model":{"display_name":"M"},"rate_limits":{"five_hour":{"used_percentage":%s}}}' "$pct" |
      "$ROOT/scripts/statusline-cache.py" >/dev/null
    out=$(printf '{"hook_event_name":"UserPromptSubmit","session_id":"s"}' | "$ROOT/hooks/usage-guard.py")
    if [ "$pct" -eq 96 ]; then
      case $out in *"USAGE GUARD"*) echo "ok   96% prints USAGE GUARD" ;; *) echo "FAIL 96% printed: $out"; fail=1 ;; esac
    elif [ -z "$out" ]; then
      echo "ok   10% prints nothing"
    else
      echo "FAIL 10% printed: $out"; fail=1
    fi
  done
  return "$fail"
}

export_assets() {
  local name f g fail=0
  for name in workflow lifecycle sequence architecture; do
    f=$ROOT/assets/$name-light.svg
    g=$ROOT/assets/$name-dark.svg
    if ! { [ -s "$f" ] && [ -s "$g" ]; }; then echo "FAIL $name: missing or empty asset"; fail=1; continue; fi
    if cmp -s "$f" "$g"; then echo "FAIL $name: light and dark are identical"; fail=1; continue; fi
    if grep -q '<script' "$f" "$g"; then echo "FAIL $name: contains <script"; fail=1; continue; fi
    if grep -qE '@import|url\(["'"'"']?https?:|href="https?:|src="https?:|<link ' "$f" "$g"; then
      echo "FAIL $name: external font or stylesheet reference"; fail=1; continue
    fi
    echo "ok   $name pair"
  done
  return "$fail"
}

README=$ROOT/README.md

# verdict <status> <ok text> <fail text>: print one result line, set the caller's fail=1 on failure
verdict() {
  if [ "$1" -eq 0 ]; then echo "ok   $2"; else echo "FAIL $3"; fail=1; fi
}

# alt_words <file>: print the word count of each <img alt="..."> in the file
alt_words() {
  grep -o 'alt="[^"]*"' "$1" | sed 's/^alt="//; s/"$//' | awk '{ print NF }'
}

readme() {
  local fail=0 pics dark light n f name alts all
  pics=$(grep -c '<picture>' "$README")
  dark=$(grep -c '<source media="(prefers-color-scheme: dark)"' "$README")
  light=$(grep -c '<source media="(prefers-color-scheme: light)"' "$README")
  s=0; [[ $pics -eq 4 && $dark -eq 4 && $light -eq 4 ]] || s=1
  verdict $s "4 picture, 4 dark, 4 light sources" "picture=$pics dark=$dark light=$light, want 4/4/4"
  n=0
  for name in workflow lifecycle sequence architecture; do
    for f in "$ROOT/assets/$name-light.svg" "$ROOT/assets/$name-dark.svg"; do
      if grep -q "assets/$(basename "$f")" "$README" && [ -s "$f" ]; then
        n=$((n + 1))
      else
        echo "FAIL $name: $(basename "$f") not referenced or empty"; fail=1
      fi
    done
    if cmp -s "$ROOT/assets/$name-light.svg" "$ROOT/assets/$name-dark.svg"; then
      echo "FAIL $name: light and dark are identical"; fail=1
    fi
  done
  s=0; [[ $n -eq 8 ]] || s=1
  verdict $s "8 existing non-empty files" "$n of 8 files referenced and non-empty"
  alts=$(alt_words "$README" | awk '$1 >= 5' | wc -l)
  all=$(alt_words "$README" | wc -l)
  [ "$alts" -eq 4 ] && [ "$all" -eq 4 ]
  verdict $? "4 alt texts of 5 or more words" "$alts of $all alt texts have 5 or more words, want 4 of 4"
  return "$fail"
}

hero() {
  local pic inst fail=0
  pic=$(grep -n '<picture>' "$README" | head -1 | cut -d: -f1)
  inst=$(grep -n '^```bash' "$README" | head -1 | cut -d: -f1)
  grep -A3 '<picture>' "$README" | head -4 | grep -q 'workflow-'
  verdict $? "first picture is the workflow" "first picture is not the workflow"
  [ -n "$pic" ] && [ "$pic" -lt 30 ]
  verdict $? "workflow picture at line $pic" "picture line ${pic:-none}, want before 30"
  [ -n "$inst" ] && [ "$inst" -lt 45 ]
  verdict $? "install block at line $inst" "install block line ${inst:-none}, want before 45"
  return "$fail"
}

compare() {
  local sec cols rows cons fail=0
  sec=$(awk '/^## How it compares/ { on = 1; next } /^## / { on = 0 } on' "$README")
  [ -n "$sec" ] || { echo "FAIL no How it compares section"; return 1; }
  cols=$(printf '%s\n' "$sec" | grep -m1 '^| Feature' | awk -F'|' '{ print NF - 3 }')
  rows=$(printf '%s\n' "$sec" | grep '^|' | grep -vc -e '^| Feature' -e '^|---')
  cons=$(printf '%s\n' "$sec" | grep -c '^[0-9]\. ')
  [ "$cols" -eq 4 ]
  verdict $? "4 tool columns" "$cols tool columns, want 4"
  [ "$rows" -ge 8 ]
  verdict $? "$rows feature rows" "$rows feature rows, want 8 or more"
  printf '%s\n' "$sec" | grep -q '^### Trade-offs' && [ "$cons" -ge 4 ]
  verdict $? "Trade-offs list with $cons cons" "Trade-offs list has $cons cons, want 4 or more"
  printf '%s\n' "$sec" | grep -qE '^Sources.*20[0-9]{2}-[0-9]{2}-[0-9]{2}'
  verdict $? "sources line with check date" "no sources line with a check date"
  ! printf '%s\n' "$sec" | grep -qi 'unverified'
  verdict $? "no unverified cell" "unverified cell present"
  return "$fail"
}

install() {
  local first n smoke want fail=0
  first=$(awk '/^```bash/ { on = 1; next } /^```/ { if (on) exit } on' "$README")
  n=$(printf '%s\n' "$first" | wc -l)
  s=0; [[ -n $first && $n -eq 1 ]] || s=1
  verdict $s "first bash block is one line" "first bash block has $n lines, want 1"
  smoke=$(grep -m1 '^claude plugin install --marketplace' "$ROOT/test/install-smoke.sh" | sed 's/ *>.*$//')
  want=${smoke//\"\$SRC\"/alchristleo/lean-sdd}
  [ -n "$want" ] && [ "$first" = "$want" ]
  verdict $? "block matches the command install-smoke.sh runs" "README: $first | smoke with slug: $want"
  return "$fail"
}

fieldnotes() {
  local fail=0 rows want got
  local plans='^| \[.*\](https://github.com/alchristleo/agentic-warden/blob/main/docs/superpowers/plans/'
  rows=$(grep -c "$plans" "$README")
  s=0; [[ $rows -eq 6 ]] || s=1
  verdict $s "6 linked rows" "$rows linked rows, want 6"
  want=$(grep '^| \[' "$ROOT/docs/field-notes.md")
  got=$(grep "$plans" "$README")
  [ "$want" = "$got" ]
  verdict $? "rows equal docs/field-notes.md" "rows differ from docs/field-notes.md"
  grep -q '^6 milestones, one maintainer, one repo, Oct 2026\. Descriptive, not a benchmark\.$' "$README"
  verdict $? "caption present" "caption missing"
  ! { printf '%s\n' "$got"; grep -A1 '^| Milestone' "$README"; } | grep -q '%'
  verdict $? "no % in the table" "% in the table"
  return "$fail"
}

case ${1:-} in
  guard) guard ;;
  export) export_assets ;;
  readme) readme ;;
  hero) hero ;;
  compare) compare ;;
  install) install ;;
  fieldnotes) fieldnotes ;;
  *) echo "usage: test/check.sh guard|export|readme|hero|compare|install|fieldnotes" >&2; exit 2 ;;
esac
