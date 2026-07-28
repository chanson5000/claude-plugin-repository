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
│   ├── skills/activate-haiku-explore/SKILL.md
│   └── README.md
└── dotnet-dev-agents/
    ├── .claude-plugin/plugin.json
    ├── agents/
    │   ├── api-developer.md
    │   ├── blazor-developer.md
    │   ├── database-migration-specialist.md
    │   ├── documentation-writer.md
    │   ├── feature-flag-remover.md
    │   ├── logging-specialist.md
    │   ├── security-reviewer.md
    │   └── test-coverage-engineer.md
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

### `dotnet-dev-agents`

Domain-specific subagents for .NET/C# development: API design, Blazor/MudBlazor components, EF Core migrations, Serilog logging, security review, feature-flag removal, xUnit test coverage, and Markdown documentation.

```
/plugin install dotnet-dev-agents@personal-claude-setups
```

| Agent | Purpose |
|---|---|
| `api-developer` | RESTful API design, conventions, error handling, and security |
| `blazor-developer` | Blazor components with MudBlazor |
| `database-migration-specialist` | Safe DB schema migrations (DbUp, EF Core, FluentMigrator) |
| `documentation-writer` | Structured Markdown documentation |
| `feature-flag-remover` | Safely removing deprecated feature flags and their conditional logic |
| `logging-specialist` | Structured Serilog logging with Application Insights integration |
| `security-reviewer` | OWASP Top 10 security reviews and fixes |
| `test-coverage-engineer` | xUnit / Shouldly / BUnit / Moq test authoring |

See [`plugins/dotnet-dev-agents/README.md`](./plugins/dotnet-dev-agents/README.md).

## License

MIT
