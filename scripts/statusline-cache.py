#!/usr/bin/env python3
"""Status line that caches usage numbers for the usage-guard hook.

Prints model, context % and 5h/7d usage. Writes the usage numbers to
<state>/usage.json, where <state> is ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/state.
"""
import json
import os
import sys
import time

CONFIG = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(os.path.expanduser("~"), ".claude")
STATE = os.path.join(CONFIG, "state")


def color(pct):
    if pct >= 90:
        return "\033[31m"
    if pct >= 75:
        return "\033[33m"
    return "\033[32m"


def fmt(label, pct):
    if pct is None:
        return None
    return f"{color(pct)}{label} {pct:.0f}%\033[0m"


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        data = {}

    parts = []
    model = (data.get("model") or {}).get("display_name")
    if model:
        parts.append(model)

    ctx = (data.get("context_window") or {}).get("used_percentage")
    rl = data.get("rate_limits") or {}
    five = (rl.get("five_hour") or {}).get("used_percentage")
    seven = (rl.get("seven_day") or {}).get("used_percentage")

    for p in (fmt("ctx", ctx), fmt("5h", five), fmt("7d", seven)):
        if p:
            parts.append(p)

    if five is not None or seven is not None:
        try:
            os.makedirs(STATE, exist_ok=True)
            tmp = os.path.join(STATE, "usage.json.tmp")
            with open(tmp, "w") as f:
                json.dump(
                    {
                        "five_hour": five,
                        "five_hour_resets_at": (rl.get("five_hour") or {}).get("resets_at"),
                        "seven_day": seven,
                        "updated_at": int(time.time()),
                    },
                    f,
                )
            os.replace(tmp, os.path.join(STATE, "usage.json"))
        except Exception:
            pass

    print(" │ ".join(parts))


if __name__ == "__main__":
    main()
