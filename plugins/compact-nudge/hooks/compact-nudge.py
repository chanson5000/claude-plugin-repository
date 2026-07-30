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


TAIL_CHUNK_BYTES = 256 * 1024
MAX_TAIL_CHUNKS = 8  # ~2MB backward extension cap; a miss just returns None (no nudge that turn).


def _find_usage_in_lines(lines):
    for line in reversed(lines):
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        if entry.get("type") != "assistant":
            continue
        # Subagent turns carry their own usage against a separate context.
        if entry.get("isSidechain"):
            continue
        usage = (entry.get("message") or {}).get("usage")
        if not isinstance(usage, dict):
            continue
        total = 0
        for key in (
            "input_tokens",
            "cache_read_input_tokens",
            "cache_creation_input_tokens",
        ):
            value = usage.get(key)
            if isinstance(value, int):
                total += value
        if total > 0:
            return total
    return None


def context_tokens(transcript_path):
    """Context size of the most recent main-thread assistant turn, or None."""
    try:
        with open(transcript_path, "rb") as fh:
            fh.seek(0, os.SEEK_END)
            file_size = fh.tell()

            for chunk_index in range(1, MAX_TAIL_CHUNKS + 1):
                read_size = TAIL_CHUNK_BYTES * chunk_index
                truncated = read_size < file_size
                fh.seek(max(0, file_size - read_size))
                data = fh.read()
                text = data.decode("utf-8", errors="replace")
                lines = text.splitlines()
                if truncated and lines:
                    # First line of the tail is likely a partial line; drop it.
                    lines = lines[1:]

                result = _find_usage_in_lines(lines)
                if result is not None:
                    return result

                if not truncated:
                    # Already read the whole file; no point extending further.
                    return None
    except OSError:
        return None

    # Exhausted the backward-extension cap without finding a matching entry
    # (e.g. a long trailing run of sidechain-only entries). Returning None
    # here just means no nudge this turn, consistent with degrade-silently.
    return None


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
