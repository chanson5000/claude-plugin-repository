# claude-plugin-repository

A Claude Code plugin marketplace: installable agents and skills for .NET/C# development and general workflow automation.

## Install the marketplace

```
/plugin marketplace add chanson5000/claude-plugin-repository
```

Then install any plugin below, e.g.:

```
/plugin install resolve-pr-feedback@personal-claude-setups
```

## Contents

```
.claude-plugin/
└── marketplace.json                   # Marketplace manifest
plugins/
├── resolve-pr-feedback/
│   ├── .claude-plugin/plugin.json
│   ├── agents/
│   │   ├── pr-feedback-evaluator.md
│   │   └── pr-feedback-implementer.md
│   ├── skills/resolve-pr-feedback/
│   │   ├── SKILL.md
│   │   ├── fetch-and-evaluate-prompt.md
│   │   └── implementer-prompt.md
│   └── README.md
├── explore-haiku/
│   ├── .claude-plugin/plugin.json
│   ├── agents/explore.md
│   ├── hooks/
│   │   ├── hooks.json
│   │   └── sync-explore-agent.sh
│   ├── skills/
│   │   ├── activate-haiku-explore/SKILL.md
│   │   └── deactivate-haiku-explore/SKILL.md
│   └── README.md
└── dotnet-dev/
    ├── .claude-plugin/plugin.json
    ├── agents/
    │   ├── documentation-writer.md
    │   ├── feature-flag-remover.md
    │   ├── logging-auditor.md
    │   └── security-reviewer.md
    ├── skills/
    │   ├── api-conventions/SKILL.md
    │   ├── blazor-components/
    │   │   ├── SKILL.md
    │   │   └── references/patterns.md
    │   ├── db-migrations/SKILL.md
    │   ├── remove-feature-flag/SKILL.md
    │   ├── serilog-logging/SKILL.md
    │   └── test-conventions/SKILL.md
    └── README.md
```

## Plugins

### `resolve-pr-feedback`

A systematic multi-step workflow for resolving GitHub PR review comments with explicit approval gates before any changes are made. Fetches and evaluates all review threads, presents a verdict table (`ACCEPT` / `PARTLY_ACCEPT` / `PUSHBACK` / `OUTDATED`), and proceeds only after user confirmation at each stage.

```
/plugin install resolve-pr-feedback@personal-claude-setups
```

See [`plugins/resolve-pr-feedback/README.md`](./plugins/resolve-pr-feedback/README.md) for prerequisites and usage.

### `explore-haiku`

Overrides Claude Code's built-in `Explore` agent so it always runs on Haiku instead of inheriting the session model, cutting cost and latency on read-only search dispatches without changing behavior.

```
/plugin install explore-haiku@personal-claude-setups
```

See [`plugins/explore-haiku/README.md`](./plugins/explore-haiku/README.md) — installing requires a one-time activation step, explained there.

### `dotnet-dev`

Skills and subagents for .NET/C# development, targeting .NET 10+, Blazor, MudBlazor, EF Core, xUnit, and Serilog.

```
/plugin install dotnet-dev@personal-claude-setups
```

The split between the two kinds is deliberate: a subagent's prompt exists only inside that subagent's context, so **authoring conventions have to be skills** — encoded as agents they would go unenforced every time Claude writes the code itself instead of delegating. Agents are reserved for delegated jobs that return a report or a self-contained changeset.

| Skill | Load it when |
|---|---|
| `api-conventions` | Writing or changing an ASP.NET Core endpoint or the service behind it |
| `blazor-components` | Editing a `.razor` file — includes the lifecycle traps behind duplicate init and WASM leaks |
| `test-conventions` | Writing any xUnit or BUnit test |
| `db-migrations` | Adding or changing schema, before writing the script |
| `serilog-logging` | Adding or changing a log statement |
| `remove-feature-flag` | `/remove-feature-flag <FlagName>` — drives the removal agent behind a diff gate |

| Agent | Edits code? | Purpose |
|---|---|---|
| `security-reviewer` | No | .NET-aware vulnerability sweep, authorization-first |
| `logging-auditor` | No | Finds logging gaps, wrong levels, leaked sensitive data |
| `feature-flag-remover` | Yes, no commit | Collapses a rolled-out flag across code, markup, and tests |
| `documentation-writer` | Yes | Markdown docs as a self-contained deliverable |

> Renamed from `dotnet-dev-agents` in v2.0.0 — uninstall the old plugin before installing this one.

See [`plugins/dotnet-dev/README.md`](./plugins/dotnet-dev/README.md).

## License

MIT
