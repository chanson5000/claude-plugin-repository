# compact-nudge

Budgets a Claude Code session against an **absolute context-token count** instead of a percentage of the model's window.

Claude Code's built-in auto-compact fires at a fraction of the available context. On a 1M-context model that means the session runs far longer between compactions than it did at 250K — but long contexts cost more per turn regardless of how much headroom is left. This plugin restores the shorter-window cadence by nudging toward `/compact` once the session crosses a token count you choose.

## Install

```
/plugin marketplace add chanson5000/claude-plugin-repository
/plugin install compact-nudge@personal-claude-setups
```

## What it does

A `UserPromptSubmit` hook reads the session transcript, takes the most recent main-thread assistant turn, and sums the API's own reported usage:

```
input_tokens + cache_read_input_tokens + cache_creation_input_tokens
```

That is a measurement, not an estimate. Subagent (sidechain) turns are skipped, since they run against their own separate context.

Above the warning threshold it injects a short instruction asking Claude to mention the overage. Above the budget itself, the nudge escalates: Claude finishes the immediate request, then recommends `/compact` and prefers delegating further file-reading to subagents in the meantime.

## Configuration

| Variable | Default | Meaning |
| --- | --- | --- |
| `CONTEXT_BUDGET_TOKENS` | `250000` | The budget, in tokens |
| `CONTEXT_BUDGET_WARN_PCT` | `80` | Percent of the budget at which the soft warning starts |

Set them in `~/.claude/settings.json`:

```json
{
  "env": {
    "CONTEXT_BUDGET_TOKENS": "250000",
    "CONTEXT_BUDGET_WARN_PCT": "80"
  }
}
```

Unset, unparseable, or out-of-range values fall back to the defaults; `CONTEXT_BUDGET_WARN_PCT` is clamped to 100.

## Limitations

**This plugin cannot compact anything.** There is no compact tool, and no hook event initiates a compaction — so `/compact` still has to be typed by you. What the plugin guarantees is that the overage gets surfaced every turn instead of going unnoticed. If you want enforcement rather than a reminder, the same measurement can drive a `PreToolUse` hook that denies tool calls above the ceiling; this plugin deliberately does not.

Because the nudge is injected as context, Claude may occasionally fold it into a response rather than calling it out prominently. It is a steady pressure, not a hard gate.

Leaving Claude Code's own auto-compact enabled is still recommended as a backstop for the case where you ignore the nudges.

### Cost note

Cache reads bill at roughly a tenth of fresh input tokens, so the savings from compacting earlier are real but smaller than raw context size suggests — and each compaction itself costs a full-context read plus summary generation. A budget in the 250K–300K range is usually a better trade than an aggressively small one.

## Requirements

Python 3 on `PATH` (as `python3`, `python`, or `py`). If none is found the hook exits silently and the session is unaffected. Every failure path — unreadable transcript, malformed payload, missing interpreter — exits 0 without output, so the hook can never block a prompt.
