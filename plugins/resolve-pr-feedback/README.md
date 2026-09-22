# resolve-pr-feedback

A systematic multi-step workflow for resolving GitHub PR review comments. Fetches and evaluates all review threads, presents a verdict table (`ACCEPT` / `PARTLY_ACCEPT` / `PUSHBACK` / `OUTDATED`), and either gates on your approval at each stage (default) or runs the whole thing unattended and asks only about the calls it isn't sure of (`auto`).

## Prerequisites

- `gh` CLI installed and authenticated (used to detect the current PR)
- The [`github`](https://github.com/anthropics/claude-plugins-public/tree/main/external_plugins/github) plugin (or any MCP server exposing equivalent `pull_request_read` / `add_reply_to_pull_request_comment` tools) installed and enabled — this is how PR comments are fetched and threads are resolved

## Install

```
/plugin marketplace add chanson5000/claude-plugin-repository
/plugin install resolve-pr-feedback@personal-claude-setups
```

## Usage

As a plugin skill it is auto-invoked by description match, or you can reference it explicitly as `resolve-pr-feedback:resolve-pr-feedback` (namespaced by plugin name — confirmed via local `--plugin-dir` testing). Invoke it from a branch with an open PR, passing the mode as an argument:

| Command | Behavior |
|---------|----------|
| `/resolve-pr-feedback` | **Interactive** (default) — approval gate at evaluation, plan, and diff |
| `/resolve-pr-feedback auto` | **Auto** — evaluates, implements, commits, pushes, and resolves threads unattended; stops only for feedback it isn't sure about |
| `/resolve-pr-feedback auto --stop-before-push` | Auto through commit; stops before pushing or posting any GitHub reply |
| `/resolve-pr-feedback auto --stop-before-commit` | Auto through implementation; always shows you the diff first |
| `/resolve-pr-feedback dry-run` | Stop after the evaluation table, before any changes |
| `/resolve-pr-feedback #3 #5` | Address only specific comment numbers (combinable with `auto`) |

## Interactive workflow

1. Detect the PR for the current branch
2. Dispatch the bundled `pr-feedback-evaluator` subagent (`agents/pr-feedback-evaluator.md`, pinned to Sonnet at high effort) to fetch and evaluate every unresolved review comment against the actual code
3. Present a grouped evaluation table — **pause for your approval**
4. Build an implementation plan from accepted feedback — **pause for your approval**
5. Dispatch the bundled `pr-feedback-implementer` subagent (`agents/pr-feedback-implementer.md`, pinned to Sonnet at low effort) to implement only the approved changes
6. Present the diff — **pause for your approval**
7. Commit, push, and reply/resolve GitHub threads based on each verdict

## Auto mode

Auto mode removes the *approval* gates, not the *verification*. Every comment is still read against the real code before it gets a verdict; what changes is who signs off.

The evaluator tags each comment with a confidence (`HIGH` / `LOW`) alongside its verdict. `HIGH`-confidence, low-blast-radius items are implemented, committed, pushed, and their threads resolved with no interruption. Everything else is held back and brought to you in **one consolidated checkpoint**, each item with a recommended call — never one question at a time.

Escalation triggers: unverifiable claims, conflicting reviewers, pure judgment calls (naming, API shape, architectural direction), high blast radius (public contracts, migrations, auth, secrets, CI, dependencies, test deletions), reviewer questions rather than change requests, comments needing product context, judgment-heavy `PARTLY_ACCEPT` splits, scope expansion beyond the PR, unverifiable pushback arguments, and anything that would require inventing unspecified behavior.

Some things stay off-limits regardless of mode: history rewrites and force-pushes, pushing to the default branch, committing files the implementer didn't touch, resolving a human's pushback thread, changing PR state, touching CI config or secrets, and pushing a red build. A run that drops or fails an item says so explicitly in its closing report.

See `skills/resolve-pr-feedback/SKILL.md` for the full workflow definition, including the complete escalation trigger table.
