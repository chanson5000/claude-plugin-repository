# explore-haiku

Overrides Claude Code's built-in `Explore` agent so it always runs on Haiku, instead of inheriting the session's model.

## Why

Up through Claude Code v2.1.197, `Explore` always ran on Haiku. As of v2.1.198 it inherits the main conversation's model instead — capped at Opus on the Claude API, uncapped on other providers. So a session on Opus now dispatches Explore on Opus.

Explore does fast, read-only file and symbol lookups. That workload doesn't need a large model, so pinning it back to Haiku cuts cost and latency on every dispatch.

## Install

```
/plugin marketplace add chanson5000/claude-plugin-repository
/plugin install explore-haiku@personal-claude-setups
```

Start a new session and the override is active — the bundled `SessionStart` hook places the agent file for you (see [How it works](#how-it-works)). If you're on Windows without Git Bash, run the hook's manual equivalent once by asking Claude to **"activate explore haiku"**.

## What changes, beyond the model

Overriding `Explore` with a custom subagent has one side effect worth knowing about:

> Explore and Plan skip your CLAUDE.md files and the parent session's git status to keep research fast and inexpensive. Every other built-in and custom subagent loads both.

A custom subagent named `Explore` is subject to that second sentence. Once this plugin is active, every Explore dispatch loads your full CLAUDE.md hierarchy plus git status, which the built-in skipped. There is no frontmatter field to opt out.

In practice the Opus→Haiku swing still dominates, but in repos with large CLAUDE.md hierarchies the added per-dispatch tokens partly offset the savings. Worth measuring before assuming it's a pure win.

## How it works

Claude Code resolves same-named subagents by location priority: managed settings > `--agents` CLI flag > project `.claude/agents/` > user `~/.claude/agents/` > plugin `agents/`. A subagent whose frontmatter `name` is `Explore`, at **user or project scope**, overrides the built-in and keeps its own `model` field.

Plugin-scoped agents are the exception: Claude Code namespaces them (`explore-haiku:Explore`), so a plugin's copy alone never shadows the bare built-in `Explore`. Confirmed empirically — dispatching `subagent_type: Explore` with only the plugin installed still resolves to the main conversation's model.

So the file has to land at user scope. `hooks/sync-explore-agent.sh`, wired to `SessionStart` via `hooks/hooks.json`, copies `agents/explore.md` to `~/.claude/agents/explore.md`. Plugin hooks run automatically once the plugin is enabled — installing the plugin is the consent, there's no per-session prompt. The script:

- writes the file only if it's absent, or if it byte-matches the copy this plugin last wrote (tracked in `${CLAUDE_PLUGIN_DATA}/synced-explore.md`);
- leaves any pre-existing or user-edited `~/.claude/agents/explore.md` completely alone;
- re-syncs automatically after `/plugin update`, so the user-scope copy can't silently go stale;
- always exits 0, so a failure can never block session startup.

It's a POSIX shell script. Claude Code runs hook commands through Git Bash on Windows, falling back to PowerShell when Git Bash isn't installed — in that fallback the hook won't run, and the `activate-haiku-explore` skill does the same job manually.

Note: the filename `explore.md` is a convention, not a requirement. Subagent identity comes only from the `name` frontmatter field.

## Uninstall

`/plugin uninstall` does **not** remove `~/.claude/agents/explore.md`. Left behind, it keeps overriding `Explore` forever with a frozen copy of the prompt. To fully undo:

1. Ask Claude to **"deactivate explore haiku"** (the `deactivate-haiku-explore` skill), which removes the user-scope file after confirming you didn't customize it.
2. `/plugin uninstall explore-haiku@personal-claude-setups`

Do them in that order — with the plugin still enabled, the `SessionStart` hook re-creates the file on the next session.

## Alternatives

`CLAUDE_CODE_SUBAGENT_MODEL=haiku` is simpler and needs no plugin, but it pins **every** subagent to Haiku, not just Explore. Use it if that's what you want; use this plugin if you want Explore specifically.

The two don't compose: `CLAUDE_CODE_SUBAGENT_MODEL` sits above subagent frontmatter in model resolution, so if it's set to anything other than `inherit`, it silently wins over this plugin's `model: haiku`. That's the first thing to check if the override doesn't seem to be taking effect.

## Caveats

The built-in Explore's system prompt isn't published, so `agents/explore.md` is a reconstruction from the documented description and tool contract, not a byte-for-byte copy. Its `disallowedTools` list matches the built-in's exactly; the prompt and `description` are best-effort.

Because `description` drives when Claude auto-delegates, drift between this reconstruction and the evolving built-in changes delegation behavior. The agent file records which Claude Code version it was last verified against — re-check on updates.
