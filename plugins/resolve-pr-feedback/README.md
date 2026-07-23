# resolve-pr-feedback

A systematic multi-step workflow for resolving GitHub PR review comments with explicit approval gates before any changes are made. Fetches and evaluates all review threads, presents a verdict table (`ACCEPT` / `PARTLY_ACCEPT` / `PUSHBACK` / `OUTDATED`), and proceeds only after user confirmation at each stage.

## Prerequisites

- `gh` CLI installed and authenticated (used to detect the current PR)
- The [`github`](https://github.com/anthropics/claude-plugins-public/tree/main/external_plugins/github) plugin (or any MCP server exposing equivalent `pull_request_read` / `add_reply_to_pull_request_comment` tools) installed and enabled — this is how PR comments are fetched and threads are resolved

## Install

```
/plugin marketplace add chansonbiltd/personal-claude-setups
/plugin install resolve-pr-feedback@personal-claude-setups
```

## Usage

As a plugin skill it is auto-invoked by description match, or you can reference it explicitly as `resolve-pr-feedback:resolve-pr-feedback` (namespaced by plugin name — confirmed via local `--plugin-dir` testing). Invoke it from a branch with an open PR:

- Default: runs the full workflow (fetch → evaluate → approve → plan → approve → implement → review diff → commit/push/resolve)
- `dry-run` — stop after the evaluation table, before any changes
- `#3 #5` — address only specific comment numbers

## Workflow

1. Detect the PR for the current branch
2. Dispatch the bundled `pr-feedback-evaluator` subagent (`agents/pr-feedback-evaluator.md`, pinned to Sonnet at high effort) to fetch and evaluate every unresolved review comment against the actual code
3. Present a grouped evaluation table — **pause for your approval**
4. Build an implementation plan from accepted feedback — **pause for your approval**
5. Dispatch the bundled `pr-feedback-implementer` subagent (`agents/pr-feedback-implementer.md`, pinned to Sonnet at low effort) to implement only the approved changes
6. Present the diff — **pause for your approval**
7. Commit, push, and reply/resolve GitHub threads based on each verdict

See `skills/resolve-pr-feedback/SKILL.md` for the full workflow definition.
