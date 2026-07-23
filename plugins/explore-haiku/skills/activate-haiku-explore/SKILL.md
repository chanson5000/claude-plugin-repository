---
name: activate-haiku-explore
description: One-time setup step for the explore-haiku plugin. Use when the user has just installed the explore-haiku plugin and wants to activate the Haiku-pinned Explore override, or asks to "activate explore haiku", "set up explore haiku", or "enable the explore override".
---

# Activate explore-haiku

Claude Code plugins cannot override a built-in agent directly: a plugin-scoped agent named `Explore` is namespaced (e.g. `explore-haiku:Explore`) rather than replacing the bare built-in `Explore`. The only way to actually override the built-in is a subagent file named `explore.md` placed at **user scope** (`~/.claude/agents/explore.md`). This skill performs that one-time placement so the plugin's override takes effect.

## Steps

1. Locate this plugin's bundled agent file. Search for it in likely install locations, e.g.:
   ```
   find ~/.claude/plugins -path '*explore-haiku*/agents/explore.md' 2>/dev/null
   find . -path '*explore-haiku*/agents/explore.md' 2>/dev/null
   ```
   Use whichever match actually exists. If none is found, stop and tell the user you couldn't locate the bundled agent file, and ask them to confirm the plugin is installed.

2. Check whether `~/.claude/agents/explore.md` already exists.
   - If it does **not** exist: copy the bundled file's contents there as-is.
   - If it **does** exist and its contents differ from the bundled file: show the user a brief diff/summary and ask before overwriting — it may be a customization they made intentionally.
   - If it exists and is already identical: tell the user it's already active, nothing to do.

3. After writing the file, tell the user the override is active starting with their **next new session** (agent resolution happens at session start, so the current session will keep using the built-in `Explore` until restarted).
