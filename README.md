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
├── dotnet-dev/
│   ├── .claude-plugin/plugin.json
│   ├── agents/
│   │   ├── documentation-writer.md
│   │   ├── feature-flag-remover.md
│   │   ├── logging-auditor.md
│   │   └── security-reviewer.md
│   ├── skills/
│   │   ├── api-conventions/SKILL.md
│   │   ├── blazor-components/
│   │   │   ├── SKILL.md
│   │   │   └── references/patterns.md
│   │   ├── db-migrations/SKILL.md
│   │   ├── remove-feature-flag/SKILL.md
│   │   ├── serilog-logging/SKILL.md
│   │   └── test-conventions/SKILL.md
│   └── README.md
└── subagent-orchestration/
    ├── .claude-plugin/plugin.json
    ├── agents/
    │   ├── implement-complex.md
    │   ├── implement-mechanical.md
    │   ├── implement-standard.md
    │   ├── investigate-deep.md
    │   ├── investigate-standard.md
    │   ├── plan-standard.md
    │   └── review-critical.md
    ├── hooks/
    │   ├── hooks.json
    │   └── orchestrator-guard.sh
    ├── skills/orchestrate/
    │   ├── SKILL.md
    │   └── references/dispatch-brief.md
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

### `subagent-orchestration`

An orchestrator-first development style: the main session triages work and dispatches it, and does not read broadly or edit files itself. Cost then tracks task difficulty rather than the session model — a rename runs on Haiku at low effort while a migration runs on Opus at high effort, in the same session.

```
/plugin install subagent-orchestration@personal-claude-setups
```

Start with `/orchestrate`. Seven worker agents form the ladder:

| Agent | Model / effort | Edits? | Dispatch for |
|---|---|---|---|
| `plan-standard` | sonnet / medium | No | Sequencing multi-step work into tier-scoped dispatch briefs |
| `investigate-standard` | sonnet / medium | No | How and why code behaves as it does; scoping a change |
| `investigate-deep` | opus / high | No | Diagnosis that resisted a cheaper pass — races, corruption, perf |
| `implement-mechanical` | haiku / low | Yes, no commit | Fully decided changes: stated renames, known call sites |
| `implement-standard` | sonnet / medium | Yes, no commit | Ordinary features and fixes with a pattern to follow |
| `implement-complex` | opus / high | Yes, no commit | Consequence-heavy or unsettled work |
| `review-critical` | opus / high | No | A changeset about to be committed in expensive-to-break code |

The ladder is separate definitions rather than one configurable agent because the Agent tool can override an agent's `model` at dispatch time but **not** its `effort` — that lives in frontmatter only. `plan-standard` exists because the built-in `Plan` agent inherits the session model, so it would otherwise plan on Opus however ordinary the work is.

Enforcement is on from install, with no flag to set: a bundled hook injects the doctrine at `SessionStart` and denies main-session edits, so Claude re-routes to a worker instead of asking you to approve each one. `SUBAGENT_ORCHESTRATION_STRICT=ask` softens it to a prompt and `=off` disables it.

See [`plugins/subagent-orchestration/README.md`](./plugins/subagent-orchestration/README.md) for the triage rubric, escalation rules, strict mode, and how it composes with `explore-haiku` and `dotnet-dev`.

## License

MIT
