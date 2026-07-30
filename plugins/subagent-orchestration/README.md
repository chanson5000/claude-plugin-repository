# subagent-orchestration

An orchestrator-first development style. The main session triages work and dispatches it; the reading, searching, and writing happen in subagents whose **model and effort were chosen for that specific task**.

## Install

```
/plugin marketplace add chanson5000/claude-plugin-repository
/plugin install subagent-orchestration@personal-claude-setups
```

Then start a session with:

```
/orchestrate
```

Or just tell Claude to work in orchestrator mode — the skill's description triggers on delegation-shaped requests.

## Why

Two problems this addresses, both of which get worse the longer a session runs.

**Context.** Search fan-out and whole-file reads are what fill the main context. Once they live in subagents, the main thread holds decisions and reports only, so hour-three quality resembles hour-one.

**Cost tracking difficulty instead of session model.** Without this, the session model sets the price of every piece of work: a rename on Opus costs Opus money, and switching models mid-session to fix that is manual and easy to forget. Here a rename runs on Haiku at low effort and a data migration runs on Opus at high effort, in the same session, decided per task.

## The ladder

Six agents across three lanes. Each has a fixed model and effort; the tier *is* the agent.

| Agent | Model / effort | Edits? | Dispatch for |
|---|---|---|---|
| `investigate-standard` | sonnet / medium | No | How and why code behaves as it does; scoping a change |
| `investigate-deep` | opus / high | No | Diagnosis that resisted a cheaper pass — races, corruption, perf, contradictory evidence |
| `implement-mechanical` | haiku / low | Yes, no commit | Fully decided changes: stated renames, known call sites, dead-branch deletion |
| `implement-standard` | sonnet / medium | Yes, no commit | Ordinary features and fixes with clear intent and a pattern to follow |
| `implement-complex` | opus / high | Yes, no commit | Consequence-heavy or unsettled work; anything a standard dispatch stalled on |
| `review-critical` | opus / high | No | A changeset about to be accepted in code where a subtle mistake is expensive |

The two built-ins fill in the ends: `Explore` is the bottom rung of the investigate lane (plain "where is X" lookups), and `Plan` produces the strategy when you need one before you can write briefs.

Investigators and the reviewer have read-only tool allowlists. That isn't caution for its own sake — an auditor with `Edit` will sometimes fix what it was asked to assess, which both hides the finding and produces changes nobody requested. No worker gets the `Agent` tool either: fan-out stays with the orchestrator, so every routing decision is visible in the main thread.

None of the implementers commit. They report; the orchestrator reviews the diff and commits.

## How tiers get chosen

Two questions, in this order: **is the work decided, or does it still have to be figured out?** and **what does being wrong cost?**

| | Cheap to be wrong | Expensive to be wrong |
|---|---|---|
| **Fully decided** | `implement-mechanical` | `implement-standard` |
| **Clear intent, ordinary judgment** | `implement-standard` | `implement-complex` |
| **Undecided** | investigate, then re-triage | plan, then take the decision to the user |

Expensive means auth, money, migrations, concurrency, public contracts, deleting anything not provably dead, or behavior a user can observe changing.

Escalation is one attempt per tier. A dispatch that comes back blocked or holding a design question is the tier working correctly; the response is to move up the ladder, never to re-prompt the same tier — that spends a full dispatch relearning the same wall and, when the second attempt half-succeeds, leaves two conflicting changesets to reconcile.

De-escalation matters as much. Investigation tier and fix tier are independent: `investigate-deep` producing a precise diagnosis usually makes the fix mechanical, so it drops to Haiku rather than staying on Opus because the bug *felt* hard.

## Why the ladder is six definitions instead of one agent

The Agent tool's `model` parameter overrides an agent's frontmatter model at dispatch time. **Effort has no such parameter** — it is frontmatter only. A single "worker" agent could therefore be pointed at a different model per dispatch but would be stuck at one effort level, which is half the lever.

The useful corollary: dispatching `implement-standard` with `model: opus` yields opus at *medium* effort — a real intermediate rung for briefs that are routine in shape but land in consequence-heavy code.

## Composing with other plugins

**Convention skills still apply.** The three implementers keep the `Skill` tool, and their prompts tell them to load the project's `CLAUDE.md` and any convention skills covering the files they touch. This matters more here than in a normal session: if all the writing happens inside subagents, and conventions are encoded as skills, then workers must be able to load skills or the conventions never take effect. `dotnet-dev`'s `api-conventions`, `test-conventions`, `blazor-components`, `db-migrations`, and `serilog-logging` work inside a dispatch.

**`explore-haiku` composes cleanly.** It pins the built-in `Explore` to Haiku, which is exactly the bottom rung this style wants. Note that `CLAUDE_CODE_SUBAGENT_MODEL` does *not* compose — set to anything other than `inherit`, it sits above subagent frontmatter in model resolution and flattens the whole ladder to one model. That's the first thing to check if tiers don't seem to take effect.

**Review boundaries:** built-in `/code-review` for a routine pass over your working diff, `/security-review` for a quick security sweep, `dotnet-dev:security-reviewer` for a deep .NET-aware audit of an area, `review-critical` for a changeset you're about to commit without having read the code yourself.

## Caveats

**Dispatch overhead is real.** Every dispatch pays for a cold start: the worker re-reads what it needs, and the brief has to restate everything. Batching matters — one brief covering five call sites beats five micro-dispatches. For a genuinely trivial change the overhead can exceed the work, and the skill still says dispatch it, because a rule with an exception costs more attention to police every turn than the exception saves. If you want a one-line fix done in the main session, ask for it directly; that's your call, not drift.

**Enforcement is by discipline, not mechanism.** The skill sets the orchestrator's edit budget to zero, but nothing blocks an `Edit`. A `PreToolUse` hook is the obvious enforcement, and this plugin deliberately doesn't ship one: hook matchers fire on subagent tool calls as well as the main session's, so a hook blocking `Edit` would also block the workers doing the actual work. Verify that behavior on your Claude Code version before building one.

**`effort` on Haiku.** Every agent sets `model` and `effort` explicitly, per this repo's convention, so nothing silently inherits the session model. Whether the smallest models act on `effort` is a model-side question; the field is harmless where unsupported.

**This style is not always the right one.** A five-minute single-file change does not need a control plane. Reach for it on long sessions, wide codebases, and work whose difficulty genuinely varies task to task.
