# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A Claude Code plugin marketplace: a collection of installable plugins (agents + skills) for .NET/C# development and general workflow automation, listed in `.claude-plugin/marketplace.json`.

## Repository Structure

```
.claude-plugin/
  marketplace.json          # Marketplace manifest listing all plugins below
plugins/
  resolve-pr-feedback/      # Gated multi-step PR review resolution workflow
  explore-haiku/            # Pins the built-in Explore agent to Haiku
  dotnet-dev/               # Skills (authoring conventions) + agents (delegated sweeps) for .NET/C#/Blazor
  subagent-orchestration/   # An orchestrator-first ladder of tier-scoped worker agents plus a guard hook
```

Each plugin directory is self-contained:
- `.claude-plugin/plugin.json` — plugin manifest (name, version, description, author, homepage, repository, license)
- `agents/*.md` — subagents, if any
- `skills/<skill-name>/SKILL.md` — skills, if any
- `hooks/hooks.json` (+ any scripts it invokes) — lifecycle hooks, if any
- `README.md` — install instructions and usage

Only `.claude-plugin/` sits under that name; `agents/`, `skills/`, and `hooks/` must be at the plugin root. Hook commands reference bundled files via `${CLAUDE_PLUGIN_ROOT}` and persist state under `${CLAUDE_PLUGIN_DATA}` — never hardcode install paths, which change on every plugin update.

## Working With Plugins

- Every plugin listed in `.claude-plugin/marketplace.json` must have a matching directory under `plugins/` with a valid `.claude-plugin/plugin.json`.
- Keep `homepage`/`repository` URLs in every `plugin.json` and `marketplace.json` entry pointed at this repo (`chanson5000/claude-plugin-repository`) — a wrong URL breaks the documented install command silently.
- When adding a new plugin, add it to `marketplace.json`, give it its own `README.md` with an `/plugin install` snippet, and keep its `plugin.json` `repository`/`homepage` fields consistent with the pattern used by existing plugins.

## Skill Or Agent?

A subagent's prompt exists **only inside that subagent's context**. Coding conventions encoded as an agent are therefore unenforced whenever Claude writes the code itself rather than delegating — which is the common case. Anything that must hold while Claude works is a **skill**.

- **Skill** — tells Claude how to do work it is already doing: conventions, house rules, a workflow with user gates. `dotnet-dev`'s `test-conventions`, `api-conventions`, `blazor-components`, `db-migrations`, `serilog-logging`.
- **Agent** — a bounded delegated job whose output is a report or a self-contained changeset, and whose search fan-out would otherwise flood the main context. `dotnet-dev`'s `security-reviewer`, `logging-auditor`, `feature-flag-remover`, `documentation-writer`.

A body of text that does both (the old `logging-specialist`) should be split, not compromised.

## Working With Agents

Agent files are markdown with YAML frontmatter (`name`, `description`, `color`, optionally `model`/`effort`/`tools`) followed by the agent's system prompt.

- The `description` field is used by Claude Code to decide when to invoke the agent automatically — make it precise, trigger-oriented, and include a negative boundary (what the agent is *not* for) whenever another agent, skill, or built-in command covers adjacent ground.
- Set `model` and `effort` deliberately on every agent. Omitting them silently inherits the session model, so a mechanical sweep can end up running on Opus.
- **Give review and audit agents a read-only `tools` allowlist** (`Read, Grep, Glob, Bash`). Without it an agent inherits every tool, and a "review" will sometimes rewrite the code it was asked to assess, producing unrequested changes that obscure the findings.
- Keep agent responsibilities narrow. Cross-cutting concerns (logging, security) have their own dedicated agents.

## Working With Skills

Each skill lives at `plugins/<plugin-name>/skills/<skill-name>/`:
- `SKILL.md` — the skill entry point; invoked via the `Skill` tool
- Optional subagent prompt files referenced inside `SKILL.md`

`explore-haiku` writes into user scope (`~/.claude/agents/`), because plugin-scoped agents are namespaced and can't shadow a built-in. Any skill or hook that does this must be non-destructive: write only when the target is absent or byte-matches what the plugin last wrote (tracked in `${CLAUDE_PLUGIN_DATA}`), never clobber a user's own file, and ship a matching deactivation path — uninstalling a plugin does not remove files it placed outside its own directory.

The `resolve-pr-feedback` skill uses an approval-gate pattern: fetch → evaluate → user approval → plan → user approval → implement → diff review → commit/push. Preserve these gates when editing; skipping them is explicitly called out as a red flag in the skill.

## Conventions

- **Encoding:** UTF-8 without BOM on all files
- **Line endings:** LF, enforced via `.gitattributes`
- **Paths:** Unix-style forward slashes everywhere
- **Target stack for `dotnet-dev`:** .NET 10+, C#, Blazor, MudBlazor, EF Core, xUnit, Serilog
