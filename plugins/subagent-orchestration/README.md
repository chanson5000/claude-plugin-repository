# subagent-orchestration

An orchestrator-first development style. The main session triages work and dispatches it. The reading, searching, and writing happen in subagents, and **the orchestrator chooses each dispatch's model and effort for that specific task.**

## Install

```
/plugin marketplace add chanson5000/claude-plugin-repository
/plugin install subagent-orchestration@personal-claude-setups
```

Then start a session with:

```
/orchestrate
```

You don't have to, though. Every session starts with the doctrine already in context, and `/orchestrate` adds the full model/effort table, the escalation protocol, and the brief contract. See [What the hook does](#what-the-hook-does) for how to turn it off.

## Why

Three problems this addresses, all of which get worse the longer a session runs.

**Context.** Search fan-out and whole-file reads are what fill the main context. Once they live in subagents, the main thread holds decisions and short reports only, so hour-three quality resembles hour-one.

**Cost tracks difficulty instead of session model.** Without this, the session model sets the price of every piece of work: a rename on Opus costs Opus money. Here a rename runs on Haiku at low effort and a data migration runs on Opus at high effort, in the same session, decided per task.

**Time.** Dispatches run in the background, so independent investigations and disjoint changes proceed at once while the orchestrator keeps triaging.

## The agents

Four agents, one per job. None has a fixed tier: the orchestrator passes `model` and `effort` on every dispatch, and the Agent tool's parameters override frontmatter.

| Agent | Edits? | Dispatch for |
|---|---|---|
| `planner` | No | Turning multi-step work into sequenced dispatch briefs |
| `investigator` | No | How and why code behaves; scoping a change; root-cause diagnosis |
| `implementer` | Yes, never commits | Any decided change. The brief states `MODE: mechanical`, `standard`, or `complex` |
| `reviewer` | No | A changeset about to be accepted where a subtle mistake is expensive |

Built-in `Explore` covers plain "where is X" lookups, always dispatched with `model: haiku`. Otherwise it inherits the session model, so an Opus session greps on Opus. (If the session runs Fable, subscription and Console accounts drop Explore to the Opus alias.) `planner` replaces the built-in `Plan`, which inherits the session model and returns prose rather than briefs.

Frontmatter defaults are sonnet / medium (opus / medium for `reviewer`). They apply only when a dispatch omits the parameters.

## How model and effort get chosen

Two questions, in this order: **is the work decided, or does it still have to be figured out?** and **what does being wrong cost?**

| | Cheap to be wrong | Expensive to be wrong |
|---|---|---|
| **Fully decided** | mechanical, haiku / low | standard, sonnet / medium |
| **Clear intent, ordinary judgment** | standard, sonnet / medium | complex, opus / high |
| **Undecided** | investigate, then re-triage | plan, then take the decision to the user |

Expensive means auth, money, migrations, concurrency, public contracts, deleting anything not provably dead, or behavior a user can observe changing.

**Medium is the default effort.** `low` is for work with no decisions left; `high` is for consequence-heavy or stalled work. **Effort is capped at `high`.** When work stalls, a bigger model is a better lever than more effort, and when opus / high stalls the cause is almost always the brief or an unmade decision. The guard denies any Agent or Workflow call that asks for `xhigh` or `max`. The skill also tells the orchestrator not to launch ultracode-scale Workflow fan-outs.

Model and effort move independently. `implementer` at opus / medium is a real rung for briefs that are routine in shape but land in consequence-heavy code.

## Escalation and follow-up

**Small gap → continue the same worker.** `SendMessage` to a worker's agent ID resumes it with its full context, so a missed call site or a test to add costs a short follow-up rather than a cold start. A resumed worker keeps its model and effort.

**A wall → new dispatch, one step up.** When a worker is blocked, still failing, or holding a design question, the orchestrator raises the model first, then the effort, and passes along what the lower dispatch established. It never re-dispatches fresh at the same model and effort with a reworded brief.

**De-escalation matters as much.** An opus / high diagnosis usually makes the fix mechanical, so the fix goes to haiku / low.

## Dispatch mechanics

* **No forks.** A fork inherits the whole conversation, runs on the session model, and ignores `model` and `effort`. That is the cost and context this style avoids.
* **No `name` on dispatches.** With agent teams enabled, a named dispatch becomes a teammate.
* **Background, not polling.** Independent dispatches go out in one message. The orchestrator waits for notifications and never reads a worker's transcript, since that would pour the worker's context into its own.
* **Writers parallelize only on disjoint file sets**, or with `isolation: worktree`.
* **Short reports.** Every agent is told its report lands in the orchestrator's context and to aim for under 25 lines with `file:line` pointers.

## Composing with other plugins

**Convention skills still apply.** `implementer` lists `Skill` in its `tools` allowlist and is told to load the project's `CLAUDE.md` and any convention skills covering the files it touches. If all the writing happens inside subagents and conventions are encoded as skills, workers must be able to load skills or the conventions never take effect. A `tools` allowlist is strict, so leaving `Skill` out would silently drop them.

**No nested dispatch.** Subagents can now spawn their own subagents. None of these agents lists `Agent` in its allowlist, so fan-out stays with the orchestrator.

**`explore-haiku` composes cleanly.** It pins the built-in `Explore` to Haiku, so a forgotten `model` still lands on the right rung.

**Environment overrides.** `CLAUDE_CODE_SUBAGENT_MODEL` is now only a default below frontmatter, so it no longer flattens anything. `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` does: it ignores the `model` passed on each dispatch. `CLAUDE_CODE_EFFORT_LEVEL` overrides per-dispatch `effort`. Check these first if choices don't seem to take effect.

**Review boundaries:** built-in `/code-review` for a routine pass, `/security-review` for a quick security sweep, `dotnet-dev:security-reviewer` for a deep .NET-aware audit, `reviewer` for a changeset the orchestrator is about to accept without having read the code itself.

## Caveats

**Requires per-dispatch effort.** The Agent tool's `effort` parameter arrived in Claude Code v2.1.292. On older versions every dispatch runs at the agent's frontmatter effort (medium).

**Dispatch overhead is real.** Every fresh dispatch pays for a cold start. Batching matters: one brief covering five call sites beats five micro-dispatches. For a genuinely small change whose context is already in hand, the overhead can exceed the work, and the skill leaves that call to the orchestrator.

**Delegation is guidance, not enforcement.** Nothing blocks the main session from reading, searching, or editing; it keeps every tool. The doctrine and skill make delegation the strong default, and the orchestrator decides when doing something itself is plainly cheaper. If you find it drifting into doing everything itself on long sessions, that is the place to tighten the skill's wording.

**Read-only agents keep `Bash`.** The investigator, planner, and reviewer need it for `git log`, `rg`, and running tests, so "read-only" means no edit tools, enforced, plus an instruction not to change state with `Bash`.

**Not tested end to end.** The agent definitions, manifest, and hook script are validated, and the effort cap is exercised with crafted payloads. But no orchestrated task has been run through this version yet. Expect to adjust the defaults once you've used it on real work.

## What the hook does

Plugin hooks run automatically once the plugin is enabled, with no per-session prompt. `hooks/orchestrator-guard.sh` does two things, and neither takes a tool away from the main session:

* **`SessionStart`** — injects the doctrine: delegation as the default, the four agents, the default model/effort per kind of work, the effort cap, and the rule that workers never commit. A hook can inject text but cannot force a skill to load, so the essentials have to hold even when `orchestrate` is never invoked.
* **`PreToolUse` on `Agent`/`Workflow`** — denies any dispatch or Workflow script that asks for `xhigh` or `max` effort, including nested dispatches. The denial reason tells Claude to raise the model instead, so it re-dispatches rather than stalling.

The effort match is on the parameter itself, so a brief that merely mentions an effort level in its text passes. The script always exits 0, so a failure can never block startup or a tool call.

Set `SUBAGENT_ORCHESTRATION=off` (or `0`) in your settings.json `env` block to make the hook fully inert: nothing injected, nothing denied. The agents and skill remain available.

**This style is not always the right one.** A five-minute single-file change does not need a control plane. Reach for it on long sessions, wide codebases, and work whose difficulty genuinely varies task to task.
