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

You don't have to, though. The guard is active from the moment the plugin is enabled, and every session starts with the doctrine already in context. `/orchestrate` adds the full model/effort table, the escalation protocol, and the brief contract. See [Enforcement](#enforcement--on-by-default) for how to soften or disable it.

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

**Dispatch overhead is real.** Every fresh dispatch pays for a cold start. Batching matters: one brief covering five call sites beats five micro-dispatches. For a genuinely trivial change the overhead can exceed the work, and the skill still says dispatch it, because a rule with an exception costs more attention to police than the exception saves. If you want a one-line fix done in the main session, ask for it directly.

**The guard covers `Edit`/`Write`/`NotebookEdit`, not `Bash`.** Gating `Bash` would fire on every `git` and test command the orchestrator legitimately runs, so a determined `sed -i` still slips through. The skill tells Claude not to route around a denial that way, but that part is guidance: the guard raises the floor; it isn't a sandbox.

**Read-only agents keep `Bash`.** The investigator, planner, and reviewer need it for `git log`, `rg`, and running tests, so "read-only" means no edit tools, enforced, plus an instruction not to change state with `Bash`.

**Not tested end to end.** The agent definitions, manifest, and hook script are validated, and the guard's paths are exercised with crafted payloads. But no orchestrated task has been run through this version yet. Expect to adjust the defaults once you've used it on real work.

## Enforcement — on by default

Enabling the plugin *is* the consent. Plugin hooks run automatically once the plugin is enabled, with no per-session prompt. `hooks/orchestrator-guard.sh` does three things:

* **`SessionStart`** — injects the doctrine: the four agents, the default model/effort per kind of work, the effort cap, and the rules that workers never commit and the orchestrator never edits. A hook can inject text but cannot force a skill to load, so the essentials have to hold even when `orchestrate` is never invoked.
* **`PreToolUse` on `Edit`/`Write`/`NotebookEdit`** — **denies** main-session edits and returns a reason telling Claude to dispatch the implementer. Deny rather than prompt is the point: Claude reads the reason and re-routes on its own.
* **`PreToolUse` on `Agent`/`Workflow`** — denies any dispatch or Workflow script that asks for `xhigh` or `max` effort, including nested dispatches.

The edit gate relies on the payload carrying a top-level `agent_id` key for tool calls made inside a subagent. `PreToolUse` fires for subagent tool calls too, so without that check the guard would block the workers. The match is on the key itself, so file content that merely mentions it doesn't open the gate. Writes under `/tmp` pass through for scratch notes, unless the path contains `..`. The script always exits 0, so a failure can never block startup or a tool call.

### Tuning it

`SUBAGENT_ORCHESTRATION_STRICT` in your settings.json `env` block:

| Value | Behavior |
|---|---|
| unset, `on`, `1` | Deny main-session edits and `xhigh`/`max` effort. **Default.** |
| `ask` | Prompt instead of denying edits. `xhigh`/`max` effort is still denied. |
| `off`, `0` | Fully inert. Nothing injected, nothing blocked; the agents and skill remain available. |

### An alternative it doesn't use

Claude Code can run the main session *as* a named agent (`claude --agent`, or `"agent"` in a plugin's `settings.json`), which would let an orchestrator agent simply omit `Edit` and `Write`. This plugin doesn't ship that, because the agent's prompt replaces the default Claude Code system prompt entirely and applies to every session while the plugin is enabled. That's a far larger change than a hook that denies three tools.

**This style is not always the right one.** A five-minute single-file change does not need a control plane. Reach for it on long sessions, wide codebases, and work whose difficulty genuinely varies task to task.
</content>
</invoke>
<invoke name="Bash">
<parameter name="command">cd /home/user/claude-plugin-repository && sed -n 55,70p README.md && sed -n 128,160p README.md