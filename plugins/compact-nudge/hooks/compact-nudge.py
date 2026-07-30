#!/usr/bin/env python3
"""Nudges toward /compact once a session exceeds an absolute context-token budget.

Claude Code's built-in auto-compact triggers on a *percentage* of the model's
window, so a 1M-context model runs far longer between compactions than a 250K one
did. Long contexts cost more per turn regardless of how much headroom remains, so
this hook budgets against an absolute token count instead.

It measures rather than estimates: every `assistant` line in the transcript carries
the API's own `usage` block, and the true context size for that turn is
`input_tokens + cache_read_input_tokens + cache_creation_input_tokens`.

Nudge-only by design. Nothing can trigger a compaction programmatically — there is
no compact tool and no hook event that starts one — so this injects context asking
Claude to surface the overage. The user still types /compact.

Configuration (environment variables):
  CONTEXT_BUDGET_TOKENS    Budget in tokens. Default 250000.
  CONTEXT_BUDGET_WARN_PCT  Percent of budget at which the soft warning starts.
                           Default 80.

Always exits 0. A failure here must never block a prompt.
"""

import json
import os
import sys

DEFAULT_BUDGET = 250_000
DEFAULT_WARN_PCT = 80


def env_int(name, default, minimum=1):
    raw = os.environ.get(name)
    if not raw:
        return default
    try:
        value = int(raw.strip())
    except ValueError:
        return default
    return value if value >= minimum else default


def _usage_total(entry):
    """Summed usage for a transcript entry, or None if it isn't a countable turn."""
    if entry.get("type") != "assistant":
        return None
    # Subagent turns carry their own usage against a separate context.
    if entry.get("isSidechain"):
        return None
    usage = (entry.get("message") or {}).get("usage")
    if not isinstance(usage, dict):
        return None
    total = 0
    for key in (
        "input_tokens",
        "cache_read_input_tokens",
        "cache_creation_input_tokens",
    ):
        value = usage.get(key)
        if isinstance(value, int):
            total += value
    return total if total > 0 else None


def context_tokens(transcript_path):
    """Context size of the most recent main-thread assistant turn, or None.

    Reads backward from the end of the transcript in growing chunks instead of
    `readlines()`-ing the whole file: the entry this needs is almost always in
    the last few lines, and this hook runs on every prompt, so a full read
    would mean re-scanning an ever-growing transcript each turn.
    """
    try:
        size = os.path.getsize(transcript_path)
    except OSError:
        return None

    read_size = min(65536, size)
    with open(transcript_path, "rb") as fh:
        while True:
            fh.seek(size - read_size)
            chunk = fh.read(read_size)
            lines = chunk.split(b"\n")
            if read_size < size:
                lines = lines[1:]  # first line may be a partial read; drop it
            for line in reversed(lines):
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line.decode("utf-8", errors="replace"))
                except ValueError:
                    continue
                total = _usage_total(entry)
                if total is not None:
                    return total
            if read_size >= size:
                return None
            read_size = min(read_size * 2, size)


def message(used, budget, warn_pct):
    warn_at = budget * warn_pct // 100
    if used < warn_at:
        return None

    used_k = used / 1000.0
    budget_k = budget / 1000.0
    pct = used * 100 // budget

    if used < budget:
        return (
            "[compact-nudge] This session is at ~{:.0f}K tokens of context, "
            "{}% of the configured {:.0f}K budget. When you finish responding to "
            "this prompt, add one short line telling the user they are approaching "
            "the budget and may want to run /compact. Do not interrupt the current "
            "task, and do not repeat the reminder if you have already given it this "
            "turn.".format(used_k, pct, budget_k)
        )

    return (
        "[compact-nudge] This session is at ~{:.0f}K tokens of context, over the "
        "configured {:.0f}K budget ({}%). Finish the immediate request, then stop "
        "and recommend the user run /compact before continuing — note that you "
        "cannot run it yourself. Prefer delegating further file-reading to subagents "
        "over reading large files into this context until they do."
        .format(used_k, budget_k, pct)
    )


def main():
    try:
        payload = json.load(sys.stdin)
    except (ValueError, OSError):
        return

    transcript_path = payload.get("transcript_path")
    if not transcript_path:
        return

    used = context_tokens(transcript_path)
    if used is None:
        return

    budget = env_int("CONTEXT_BUDGET_TOKENS", DEFAULT_BUDGET)
    warn_pct = env_int("CONTEXT_BUDGET_WARN_PCT", DEFAULT_WARN_PCT)
    if warn_pct > 100:
        warn_pct = 100

    text = message(used, budget, warn_pct)
    if not text:
        return

    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "UserPromptSubmit",
                "additionalContext": text,
            }
        },
        sys.stdout,
    )


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
    sys.exit(0)
