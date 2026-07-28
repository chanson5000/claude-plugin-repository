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
  dotnet-dev-agents/        # Domain-specific subagents for .NET/C#/Blazor development
```

Each plugin directory is self-contained:
- `.claude-plugin/plugin.json` — plugin manifest (name, version, description, author, homepage, repository, license)
- `agents/*.md` — subagents, if any
- `skills/<skill-name>/SKILL.md` — skills, if any
- `README.md` — install instructions and usage

## Working With Plugins

- Every plugin listed in `.claude-plugin/marketplace.json` must have a matching directory under `plugins/` with a valid `.claude-plugin/plugin.json`.
- Keep `homepage`/`repository` URLs in every `plugin.json` and `marketplace.json` entry pointed at this repo (`chanson5000/claude-plugin-repository`) — a wrong URL breaks the documented install command silently.
- When adding a new plugin, add it to `marketplace.json`, give it its own `README.md` with an `/plugin install` snippet, and keep its `plugin.json` `repository`/`homepage` fields consistent with the pattern used by existing plugins.

## Working With Agents

Agent files are markdown with YAML frontmatter (`name`, `description`, `color`, optionally `model`/`effort`) followed by the agent's system prompt.

- The `description` field is used by Claude Code to decide when to invoke the agent automatically — make it precise and trigger-oriented.
- Keep agent responsibilities narrow. Cross-cutting concerns (logging, security) have their own dedicated agents.

## Working With Skills

Each skill lives at `plugins/<plugin-name>/skills/<skill-name>/`:
- `SKILL.md` — the skill entry point; invoked via the `Skill` tool
- Optional subagent prompt files referenced inside `SKILL.md`

The `resolve-pr-feedback` skill uses an approval-gate pattern: fetch → evaluate → user approval → plan → user approval → implement → diff review → commit/push. Preserve these gates when editing; skipping them is explicitly called out as a red flag in the skill.

## Conventions

- **Encoding:** UTF-8 without BOM on all files
- **Line endings:** LF, enforced via `.gitattributes`
- **Paths:** Unix-style forward slashes everywhere
- **Target stack for `dotnet-dev-agents`:** .NET 10+, C#, Blazor, MudBlazor, EF Core, xUnit, Serilog
