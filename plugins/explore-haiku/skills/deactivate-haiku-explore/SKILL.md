---
name: deactivate-haiku-explore
description: Removes the explore-haiku plugin's user-scope Explore override and restores Claude Code's built-in Explore agent. Use when the user asks to "deactivate explore haiku", "remove the explore override", "restore the built-in Explore", or is uninstalling the explore-haiku plugin.
---

# Deactivate explore-haiku

The plugin's override lives at `~/.claude/agents/explore.md` (user scope), not inside the plugin directory. Uninstalling or disabling the plugin does **not** remove it — the file keeps shadowing the built-in `Explore` indefinitely, with whatever prompt was frozen there at activation time. This skill removes it.

## Steps

1. Check whether `~/.claude/agents/explore.md` exists. If it doesn't, tell the user the override isn't active and stop.

2. Confirm the file is the plugin's, not something the user wrote themselves. Compare it against the synced copy recorded at activation:

   ```
   diff ~/.claude/agents/explore.md ~/.claude/plugins/data/explore-haiku-personal-claude-setups/synced-explore.md
   ```

   - **Identical:** it's an untouched plugin copy. Delete it without further prompting.
   - **Differs, or the synced copy is missing:** the user may have customized it, or it may predate this plugin. Show them the file (or a summary of how it differs) and ask for explicit confirmation before deleting. Do not delete on your own judgment.

   As a secondary signal, an unmodified plugin copy has `model: haiku` and a `name: Explore` frontmatter block matching the plugin's bundled `agents/explore.md`.

3. Delete `~/.claude/agents/explore.md`, then remove the tracking copy so a later re-activation starts clean:

   ```
   rm -f ~/.claude/plugins/data/explore-haiku-personal-claude-setups/synced-explore.md
   ```

4. Tell the user:
   - The built-in `Explore` is restored starting with their **next new session** — the current session keeps using the override until restarted.
   - The built-in inherits the main conversation's model (capped at Opus on the Claude API), so exploration will cost more per dispatch than it did on Haiku, but it also goes back to skipping CLAUDE.md and git status.
   - If they also want the plugin gone entirely, they still need `/plugin uninstall explore-haiku@personal-claude-setups`. Leaving the plugin installed after running this skill is harmless, except that its `SessionStart` sync hook will re-create the override on the next session — so uninstall or disable the plugin if they want the removal to stick.
