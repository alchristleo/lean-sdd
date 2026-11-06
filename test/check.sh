#!/usr/bin/env bash
# Local acceptance checks. Usage: test/check.sh <guard|export|readme|hero|compare|install|fieldnotes|lite>
# export (AC5): the 8 diagram assets exist, pairs differ, no <script, no external refs.
# guard (AC11): status-line sample -> cache -> usage-guard hook, in a temp state dir.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)

guard() {
  local tmp out fail=0
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  export CLAUDE_CONFIG_DIR="$tmp"
  unset CLAUDE_USAGE_PAUSE_PCT
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
  # Expired 5h window must not hide a 7d value over the threshold.
  rm -rf "$tmp/state"
  printf '{"rate_limits":{"five_hour":{"used_percentage":10,"resets_at":1},"seven_day":{"used_percentage":96}}}' |
    "$ROOT/scripts/statusline-cache.py" >/dev/null
  out=$(printf '{"hook_event_name":"UserPromptSubmit","session_id":"s"}' | "$ROOT/hooks/usage-guard.py")
  case $out in *"USAGE GUARD"*) echo "ok   7d 96% with expired 5h window prints USAGE GUARD" ;; *) echo "FAIL 7d 96% with expired 5h printed: $out"; fail=1 ;; esac
  # A malformed threshold falls back to 95 without a traceback.
  for bad in abc nan inf; do
    out=$(printf '{"hook_event_name":"UserPromptSubmit","session_id":"s2-%s"}' "$bad" | CLAUDE_USAGE_PAUSE_PCT=$bad "$ROOT/hooks/usage-guard.py" 2>&1)
    case $out in *"USAGE GUARD"*"threshold 95%"*) echo "ok   CLAUDE_USAGE_PAUSE_PCT=$bad falls back to 95" ;; *) echo "FAIL threshold $bad printed: $out"; fail=1 ;; esac
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

# fm_field <file> <key>: print a frontmatter value
fm_field() {
  awk -v k="$2" '/^---$/ { n++; next } n == 1 && index($0, k ":") == 1 { sub("^" k ": *", ""); print; exit }' "$1"
}

# lite (AC1-6, 8, 9, 12): plugin-lite/ is a fresh build and holds the right parts
lite() {
  local fail=0 L=$ROOT/plugin-lite bad names n a f x tmp out rc base blk pkg gd s
  # AC1
  bad=$(find "$L" -type f ! -name '*.md' ! -name '*.json' ! -name '*.png' ! -name LICENSE)
  s=0; [ -z "$bad" ] || s=1
  verdict $s "AC1 allowed file types only" "AC1 other file types: $bad"
  # AC2
  python3 -I "$ROOT/scripts/dev/build-lite.py" &&
    [ -z "$(git -C "$ROOT" status --porcelain plugin-lite)" ]
  verdict $? "AC2 plugin-lite equals a fresh build" "AC2 plugin-lite differs from a fresh build"
  # AC3
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  sed 's/^Needs Claude Code\. If the Agent/Needs Claude Code. IF the Agent/' "$ROOT/scripts/dev/lite-edits.md" >"$tmp/edits.md"
  out=$(python3 -I "$ROOT/scripts/dev/build-lite.py" --edits "$tmp/edits.md" --out "$tmp/out" 2>&1)
  rc=$?
  [ "$rc" -ne 0 ] && case $out in *"skills/lean-sdd/SKILL.md: anchor not found exactly once: Needs Claude Code. IF the Agent"*) true ;; *) false ;; esac
  verdict $? "AC3 broken anchor fails and names path and anchor" "AC3 rc=$rc output: $out"
  # AC4 (fails until T2 inlines the script steps)
  out=$(grep -rnE 'CLAUDE_PLUGIN_ROOT|scripts/|hooks/|commit-msg|claude-trailer|usage\.json|USAGE GUARD|ste-lint|statusline' "$L")
  s=0; [ -z "$out" ] || s=1
  verdict $s "AC4 no reference to a file lite does not ship" "AC4 $(printf '%s\n' "$out" | wc -l) hits, first: $(printf '%s\n' "$out" | head -1)"
  # AC5
  names=$(cd "$ROOT/agents" && find . -name '*.md' | sed 's|^\./||; s|\.md$||' | sort)
  n=$(find "$L/agents" -name '*.md' | wc -l)
  s=0; [ "$n" -eq 10 ] && [ "$(find "$L/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 2 ] || s=1
  for a in $names; do
    for x in name model effort; do
      [ "$(fm_field "$ROOT/agents/$a.md" $x)" = "$(fm_field "$L/agents/$a.md" $x)" ] || { echo "FAIL AC5 $a: $x differs"; s=1; }
    done
  done
  grep -q '"name": "lean-sdd-lite"' "$L/.claude-plugin/plugin.json" || s=1
  verdict $s "AC5 2 skills, 10 agents, frontmatter and manifest name match" "AC5 parts differ"
  s=0
  grep -rq 'lean-sdd:' "$L" && s=1
  grep -rq 'lean-sdd-lite:lean-sdd-lite:' "$L" && s=1
  while read -r x; do
    case " ${names//$'\n'/ } <agent> <name> " in *" $x "*) ;; *) echo "FAIL AC5 unknown prefix target: $x"; s=1 ;; esac
  done < <(grep -oE 'lean-sdd-lite:[A-Za-z<][A-Za-z<>-]*' "$L/skills/lean-sdd/SKILL.md" | sed 's/^lean-sdd-lite://' | sort -u)
  verdict $s "AC5 prefix checks" "AC5 prefix checks failed"
  # AC6
  out=$(claude plugin validate --profile directory "$L" 2>&1)
  rc=$?
  s=0; [ "$rc" -eq 0 ] && ! printf '%s\n' "$out" | grep -q '❯' || s=1
  verdict $s "AC6 directory profile passes with no advisory" "AC6 rc=$rc: $(printf '%s\n' "$out" | grep '❯' | head -1)"
  claude plugin validate "$ROOT" >/dev/null 2>&1
  verdict $? "AC6 validate . passes" "AC6 validate . failed"
  # AC8
  out=$(git -C "$ROOT" diff main -- skills agents scripts hooks ':!scripts/dev')
  s=0; [ -z "$out" ] || s=1
  verdict $s "AC8 full edition unchanged" "AC8 full edition differs from main"
  # AC9: run the fenced bash block that writes review-pkg-* in a temp repo
  blk=$(awk '/^```bash/ { b = ""; on = 1; next } /^```/ { if (on && b ~ /review-pkg-/) { printf "%s", b; exit } on = 0 } on { b = b $0 "\n" }' "$L/skills/lean-sdd/SKILL.md")
  s=0
  if [ -z "$blk" ]; then
    s=1
  else
    mkdir "$tmp/r" && git -C "$tmp/r" init -q && git -C "$tmp/r" config user.email t@t && git -C "$tmp/r" config user.name t
    echo a >"$tmp/r/a.txt" && git -C "$tmp/r" add . && git -C "$tmp/r" commit -qm "first commit" || s=1
    base=$(git -C "$tmp/r" rev-parse HEAD)
    mkdir -p "$tmp/r/docs/superpowers" "$tmp/r/sub"
    echo b >"$tmp/r/b.txt" && echo secretplan >"$tmp/r/docs/superpowers/p.md"
    git -C "$tmp/r" add . && git -C "$tmp/r" commit -qm "second commit" || s=1
    blk=${blk//<base>/$base}
    (cd "$tmp/r" && bash -c "$blk" >/dev/null 2>&1) || s=1
    gd=$(git -C "$tmp/r" rev-parse --path-format=absolute --git-common-dir)
    pkg=$(find "$gd" -maxdepth 1 -name 'review-pkg-*' | head -1)
    if [ -z "$pkg" ]; then s=1; else
      case $pkg in /*) ;; *) s=1 ;; esac
      grep -q 'second commit' "$pkg" && grep -q ' | ' "$pkg" && grep -q 'b.txt' "$pkg" && ! grep -q 'secretplan\|docs/superpowers' "$pkg" || s=1
      rm -f "$pkg"
      (cd "$tmp/r/sub" && bash -c "$blk" >/dev/null 2>&1) || s=1
      [ -f "$pkg" ] || s=1
    fi
  fi
  verdict $s "AC9 review-package block writes the file from root and subdirectory" "AC9 review-package block missing or wrong"
  f=$L/skills/lean-sdd/SKILL.md
  s=0
  grep -q -e '--watch' -e '--match-head-commit' "$f" && s=1
  grep -qi '20[- ]minute' "$f" && grep -qi 'no checks' "$f" || s=1
  verdict $s "AC9 PR commands: no --watch, no --match-head-commit, 20-minute limit, stop on no checks" "AC9 PR step wording wrong"
  # AC12
  [ "$(grep '"version"' "$L/.claude-plugin/plugin.json")" = "$(grep '"version"' "$ROOT/.claude-plugin/plugin.json")" ]
  verdict $? "AC12 versions equal" "AC12 versions differ"
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
  lite) lite ;;
  *) echo "usage: test/check.sh guard|export|readme|hero|compare|install|fieldnotes|lite" >&2; exit 2 ;;
esac
