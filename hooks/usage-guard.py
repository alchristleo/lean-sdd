#!/usr/bin/env python3
"""Inject a pause instruction when 5-hour/7-day usage crosses the threshold.

Reads the cache written by scripts/statusline-cache.py (run as the status line). Runs on
UserPromptSubmit and after every tool call (background subagents return
immediately, so hooking only Agent would miss usage climbing mid-run).
Speaks only when the level changes or every 10 minutes at the same level.
Threshold: env CLAUDE_USAGE_PAUSE_PCT (default 95), warn at threshold-10.
"""
import json
import os
import sys
import time

CONFIG = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(os.path.expanduser("~"), ".claude")
STATE = os.path.join(CONFIG, "state")
CACHE = os.path.join(STATE, "usage.json")
PAUSE = float(os.environ.get("CLAUDE_USAGE_PAUSE_PCT", "95"))
WARN = PAUSE - 10
REPEAT_SECS = 600


def main():
    try:
        inp = json.load(sys.stdin)
    except Exception:
        inp = {}
    event = inp.get("hook_event_name", "UserPromptSubmit")
    session = inp.get("session_id", "default")
    try:
        with open(CACHE) as f:
            u = json.load(f)
    except Exception:
        return
    now = time.time()
    # Ignore stale data or a window that already reset.
    if now - u.get("updated_at", 0) > 900:
        return
    if u.get("five_hour_resets_at") and now > u["five_hour_resets_at"]:
        return
    pct = max(u.get("five_hour") or 0, u.get("seven_day") or 0)
    level = "pause" if pct >= PAUSE else "warn" if pct >= WARN else None
    if level is None:
        return

    # Dedupe per session: same level within REPEAT_SECS stays silent,
    # except user prompts, which always get the reminder.
    seen_path = os.path.join(STATE, f"usage-guard-{session}.json")
    try:
        with open(seen_path) as f:
            seen = json.load(f)
    except Exception:
        seen = {}
    if (
        event != "UserPromptSubmit"
        and seen.get("level") == level
        and now - seen.get("at", 0) < REPEAT_SECS
    ):
        return
    try:
        with open(seen_path, "w") as f:
            json.dump({"level": level, "at": now}, f)
    except Exception:
        pass

    if level == "pause":
        msg = (
            f"USAGE GUARD: rate limit at {pct:.0f}% (pause threshold {PAUSE:.0f}%). "
            "Do not dispatch new subagents or start new tasks. Let the in-flight "
            "task finish, commit it, write the pause point to the ledger/plan and "
            "project memory, then stop and tell the user."
        )
    else:
        msg = (
            f"USAGE GUARD: rate limit at {pct:.0f}%. Prefer cheaper tiers "
            "(Haiku/Sonnet) for remaining dispatches and plan a clean pause point."
        )
    print(json.dumps({"hookSpecificOutput": {"hookEventName": event, "additionalContext": msg}}))


if __name__ == "__main__":
    main()
