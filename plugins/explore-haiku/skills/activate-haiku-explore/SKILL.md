---
name: activate-haiku-explore
description: One-time setup step for the explore-haiku plugin. Use when the user has just installed the explore-haiku plugin and wants to activate the Haiku-pinned Explore override, or asks to "activate explore haiku", "set up explore haiku", or "enable the explore override".
---

# Activate explore-haiku

Claude Code plugins cannot override a built-in agent directly: a plugin-scoped agent named `Explore` is namespaced (e.g. `explore-haiku:Explore`) rather than replacing the bare built-in `Explore`. The only way to actually override the built-in is a subagent whose frontmatter `name` is `Explore`, loaded from **user scope** (`~/.claude/agents/`). This skill performs that one-time placement so the plugin's override takes effect.

The filename doesn't matter — subagent identity comes only from the `name` frontmatter field — but use `explore.md` for consistency with the plugin's docs and its uninstall skill.

If the plugin's `SessionStart` sync hook is running, this placement already happened automatically and this skill has nothing to do. Run it when the hook is unavailable (no POSIX shell on Windows) or when the user wants to do it explicitly.

## Steps

1. Locate this plugin's bundled agent file under the plugin cache:

   ```
   find ~/.claude/plugins/cache -path '*explore-haiku/*/agents/explore.md' 2>/dev/null
   ```

   Do **not** fall back to searching the current directory — that matches a checkout of the plugin's source repo rather than the installed copy.

   Old plugin versions linger in the cache for about two weeks after an update, so this can return several paths. Take the most recently modified one (`ls -t` rather than `find -printf`, which is GNU-only and absent on macOS). Capture the `find` output first and check it's non-empty before piping to `ls -t` — an empty result piped straight into `xargs ls -t` runs `ls -t` with no arguments, which falls back to listing the current directory and silently returns an unrelated file instead of nothing:

   ```
   matches=$(find ~/.claude/plugins/cache -path '*explore-haiku/*/agents/explore.md' 2>/dev/null)
   if [ -z "$matches" ]; then
     bundled=""
   else
     bundled=$(echo "$matches" | xargs ls -t 2>/dev/null | head -1)
   fi
   ```

   If `$bundled` is empty, stop and tell the user you couldn't locate the bundled agent file, and ask them to confirm the plugin is installed.

2. Check whether `~/.claude/agents/explore.md` already exists.
   - If it does **not** exist: copy the bundled file's contents there as-is.
   - If it **does** exist and its contents differ from the bundled file: show the user a brief diff/summary and ask before overwriting — it may be a customization they made intentionally.
   - If it exists and is already identical: tell the user it's already active, nothing to do.

3. Record what was written so the uninstall skill can tell an untouched copy from a user edit:

   ```
   mkdir -p ~/.claude/plugins/data/explore-haiku-personal-claude-setups
   cp ~/.claude/agents/explore.md ~/.claude/plugins/data/explore-haiku-personal-claude-setups/synced-explore.md
   ```

4. Tell the user:
   - The override is active starting with their **next new session** — agent resolution happens at session start, so the current session keeps using the built-in `Explore` until restarted.
   - **Behavior change beyond the model:** the built-in `Explore` skips CLAUDE.md files and the parent session's git status to stay fast and cheap. A custom subagent named `Explore` does not — it loads both on every dispatch. In repos with large CLAUDE.md hierarchies this adds per-dispatch tokens that partly offset the Haiku savings.
   - If they ever run `/plugin update`, the copy at `~/.claude/agents/explore.md` is a snapshot and will **not** refresh on its own. Re-run this skill after an update (or rely on the plugin's `SessionStart` sync hook, which handles it automatically).
   - To undo this later, use the `deactivate-haiku-explore` skill — uninstalling the plugin alone leaves this file in place and it keeps overriding `Explore`.

## Troubleshooting

If the user reports the override isn't taking effect after restarting, check whether `CLAUDE_CODE_SUBAGENT_MODEL` is set in their environment or settings. It sits **above** subagent frontmatter in model resolution, so a value there silently wins over this agent's `model: haiku`.
