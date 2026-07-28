# explore-haiku

Overrides Claude Code's built-in `Explore` agent so it always runs on Haiku, instead of inheriting the session's model. Everything else — description, search-breadth contract, tool restrictions — matches the built-in agent as closely as possible from its public documentation.

## Why

The `Explore` agent does fast, read-only file/symbol lookups. That workload doesn't need a large model, so pinning it to Haiku cuts cost and latency on every dispatch without changing behavior.

## Install

```
/plugin marketplace add chanson5000/claude-plugin-repository
/plugin install explore-haiku@personal-claude-setups
```

Then, once, ask Claude to **"activate explore haiku"** (or invoke the bundled `activate-haiku-explore` skill directly). This is a required one-time step — see "Why activation is a separate step" below. After that, start a new session for the override to take effect.

## How it works

Claude Code resolves same-named subagents by location priority (managed settings > `--agents` CLI flag > project `.claude/agents/` > user `~/.claude/agents/` > plugin directory). A subagent literally named `Explore` at **user or project scope** overrides the built-in one and keeps its own `model` field.

`agents/explore.md` in this plugin (`name: Explore`, `model: haiku`) is the source of truth for that override — but plugin-scoped agents are namespaced by Claude Code (e.g. `explore-haiku:Explore`), so the plugin's copy alone never actually shadows the bare built-in `Explore`. Confirmed empirically: dispatching `subagent_type: Explore` with this plugin installed still resolves to the main conversation's model, not Haiku.

## Why activation is a separate step

Because of the namespacing above, the only way to get a real override is to place a subagent file at `~/.claude/agents/explore.md` (user scope). There's no supported plugin-install-time hook to do this automatically without recurring permission prompts, so the bundled `activate-haiku-explore` skill does it as an explicit, user-confirmed one-time action instead: it locates this plugin's bundled `agents/explore.md` and copies it to `~/.claude/agents/explore.md`.

Note: the built-in agent's internal system prompt isn't publicly exposed, so the prompt in `agents/explore.md` is a faithful reconstruction from the documented description and tool contract rather than a byte-for-byte copy.
