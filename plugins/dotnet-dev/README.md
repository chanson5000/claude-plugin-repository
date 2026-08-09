# dotnet-dev

Skills and subagents for .NET/C# development: API endpoints, Blazor/MudBlazor components, xUnit tests, database migrations, Serilog logging, security review, feature-flag removal, and documentation.

Target stack: .NET 10+, C#, Blazor, MudBlazor, EF Core, xUnit, Serilog.

## Install

```
/plugin marketplace add chanson5000/claude-plugin-repository
/plugin install dotnet-dev@personal-claude-setups
```

> Renamed from `dotnet-dev-agents` in v2.0.0. If you have the old plugin installed, run `/plugin uninstall dotnet-dev-agents` first.

## Skills vs. agents

A subagent's prompt exists only inside that subagent's context. So conventions that must hold whenever Claude writes code — test naming, MudBlazor over raw HTML, structured log templates — have to be **skills**, loaded into the working context. Encoded as agents, they would go unenforced every time Claude writes the code itself instead of delegating, which is most of the time.

Agents are reserved for work that is genuinely delegated: a bounded job whose output is a report or a self-contained changeset, and whose search fan-out would otherwise flood the main context.

## Skills

Loaded into the current context, automatically or by slash command.

| Skill | Load it when |
|---|---|
| `api-conventions` | Writing or changing an ASP.NET Core endpoint, controller, or the service behind it |
| `blazor-components` | Editing a `.razor` file or client-side service — includes the lifecycle traps behind duplicate init and WASM leaks |
| `test-conventions` | Writing any xUnit or BUnit test, including a single test alongside a feature |
| `db-migrations` | Adding or changing schema, before writing the script |
| `serilog-logging` | Adding or changing a log statement |
| `remove-feature-flag` | `/remove-feature-flag <FlagName>` — drives the removal agent behind a diff-review gate |

`blazor-components` keeps its rules in `SKILL.md` and its code examples in `references/patterns.md`, so the examples load only when needed.

## Agents

Dispatched into their own context. The two auditors have no edit tools — a review that quietly rewrites the code it reviews produces changes nobody asked for.

| Agent | Model | Edits code? | Purpose |
|---|---|---|---|
| `security-reviewer` | opus | No | .NET-aware vulnerability sweep, authorization-first |
| `logging-auditor` | sonnet | No | Finds logging gaps, wrong levels, leaked sensitive data |
| `feature-flag-remover` | sonnet | Yes, no commit | Sweeps and collapses a rolled-out flag across code, markup, and tests |
| `documentation-writer` | haiku | Yes | Markdown docs as a self-contained deliverable |

Dispatch explicitly as `dotnet-dev:security-reviewer`, or let Claude Code select on the `description` frontmatter.

## Boundaries with other tooling

This plugin's agents and skills overlap in purpose with some of Claude Code's built-in commands; here's which to reach for:

| For | Use |
|---|---|
| Quick security pass over the current diff | built-in `/security-review` |
| Deep .NET security sweep of a whole area | `dotnet-dev:security-reviewer` |
| Guidance for authoring new tests | `dotnet-dev:test-conventions` |

## Project configuration

Every skill and agent defers to the project's own `CLAUDE.md` for specifics it cannot know: typed HTTP clients, the auth library, theme constants, the migration tool and script directory, logging sinks, and the feature-flag service interface. A project-level convention always wins over a default here.
