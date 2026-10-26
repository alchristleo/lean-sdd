#!/bin/bash
SP=${SP:-/tmp/t1-probe}
# Prereq: $SP/cfg1 has the probe plugin installed (see docs/superpowers/t1-findings.md). Not run in CI.
export CLAUDE_CONFIG_DIR=$SP/cfg1
export ANTHROPIC_BASE_URL=http://127.0.0.1:18765 ANTHROPIC_API_KEY=sk-ant-fake
rm -f $SP/mock.log $CLAUDE_CONFIG_DIR/hook.log
python3 -I "$(dirname "$0")/mock-messages-api.py" 18765 $SP/mock.log & MP=$!
sleep 1
cd $SP
for s in skill agent-prefixed agent-bare; do
  echo "=== STEP $s"
  timeout 90 claude -p "STEP $s" --dangerously-skip-permissions --output-format text 2>&1 | head -10
done
kill $MP
echo "=== hook.log"
cat $CLAUDE_CONFIG_DIR/hook.log
echo "=== requests: $(wc -l < $SP/mock.log)"
