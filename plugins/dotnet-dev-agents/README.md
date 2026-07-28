# dotnet-dev-agents

A set of domain-specific subagents for .NET/C# development — API controllers, Blazor/MudBlazor components, EF Core migrations, Serilog logging, security review, feature-flag removal, test coverage, and documentation.

## Install

```
/plugin marketplace add chanson5000/claude-plugin-repository
/plugin install dotnet-dev-agents@personal-claude-setups
```

## Agents

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

Each agent is invoked automatically by Claude Code based on its `description` frontmatter, or can be dispatched explicitly (e.g. `dotnet-dev-agents:security-reviewer`).
