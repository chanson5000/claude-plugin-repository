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

You don't have to, though — the guard is active from the moment the plugin is enabled, and every session starts with the doctrine already in context. `/orchestrate` loads the full rubric, escalation protocol, and brief contract on top of that. See [Enforcement](#enforcement--on-by-default) for how to soften or disable it.

## Why

Two problems this addresses, both of which get worse the longer a session runs.

**Context.** Search fan-out and whole-file reads are what fill the main context. Once they live in subagents, the main thread holds decisions and reports only, so hour-three quality resembles hour-one.

**Cost tracking difficulty instead of session model.** Without this, the session model sets the price of every piece of work: a rename on Opus costs Opus money, and switching models mid-session to fix that is manual and easy to forget. Here a rename runs on Haiku at low effort and a data migration runs on Opus at high effort, in the same session, decided per task.

## The ladder

Seven agents across four lanes. Each has a fixed model and effort; the tier *is* the agent.

| Agent | Model / effort | Edits? | Dispatch for |
|---|---|---|---|
| `plan-standard` | sonnet / medium | No | Turning multi-step work into sequenced, tier-scoped dispatch briefs |
| `investigate-standard` | sonnet / medium | No | How and why code behaves as it does; scoping a change |
| `investigate-deep` | opus / high | No | Diagnosis that resisted a cheaper pass — races, corruption, perf, contradictory evidence |
| `implement-mechanical` | haiku / low | Yes, no commit | Fully decided changes: stated renames, known call sites, dead-branch deletion |
| `implement-standard` | sonnet / medium | Yes, no commit | Ordinary features and fixes with clear intent and a pattern to follow |
| `implement-complex` | opus / high | Yes, no commit | Consequence-heavy or unsettled work; anything a standard dispatch stalled on |
| `review-critical` | opus / high | No | A changeset about to be accepted in code where a subtle mistake is expensive |

The built-in `Explore` remains the bottom rung of the investigate lane for plain "where is X" lookups — but note that **both built-in agents inherit the session model.** `Explore` has since v2.1.198, and `Plan` always has. In an Opus session those are the two rungs that escape the ladder: `Explore` bills Opus for a grep, and `Plan` plans on Opus however ordinary the work is.

`plan-standard` exists for exactly that reason — it is the built-in `Plan`'s job pinned to sonnet/medium, with its output shaped as dispatch briefs rather than prose. For `Explore`, pass `model: haiku` at dispatch or install `explore-haiku`.

Investigators, the planner, and the reviewer have read-only tool allowlists. That isn't caution for its own sake — an auditor with `Edit` will sometimes fix what it was asked to assess, which both hides the finding and produces changes nobody requested.

Fan-out staying with the orchestrator is not something this plugin has to enforce: Claude Code removes `Agent` from every subagent, so no worker can dispatch its own workers. It also removes `AskUserQuestion`, which is the structural reason a worker must report an ambiguity rather than ask about it — and the reason the brief has to answer questions in advance.

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

## Why the ladder is separate definitions instead of one agent

The Agent tool's `model` parameter overrides an agent's frontmatter model at dispatch time. **Effort has no such parameter** — it is frontmatter only, and there is no per-dispatch equivalent. A single "worker" agent could therefore be pointed at a different model per dispatch but would be stuck at one effort level, which is half the lever.

The useful corollary: dispatching `implement-standard` with `model: opus` yields opus at *medium* effort — a real intermediate rung for briefs that are routine in shape but land in consequence-heavy code.

`effort` accepts `low`, `medium`, `high`, `xhigh`, and `max`, with available levels depending on the model. The ladder uses three on purpose: a rung you can hold in your head beats a dial nobody calibrates. Raise a tier to `xhigh` by editing its agent file if your work warrants it.

## Composing with other plugins

**Convention skills still apply.** The three implementers list `Skill` in their `tools` allowlist, and their prompts tell them to load the project's `CLAUDE.md` and any convention skills covering the files they touch. This matters more here than in a normal session: if all the writing happens inside subagents, and conventions are encoded as skills, then workers must be able to load skills or the conventions never take effect. `dotnet-dev`'s `api-conventions`, `test-conventions`, `blazor-components`, `db-migrations`, and `serilog-logging` work inside a dispatch.

Listing it is load-bearing. A `tools` allowlist is strict — a subagent gets *only* what's listed — so an implementer without `Skill` in the list silently loses the ability to load conventions. (Frontmatter also has a `skills:` field that preloads named skills into a subagent's context. This plugin doesn't use it, because it can't know which plugins you have installed; on-demand loading via the tool keeps it decoupled. Missing entries in `skills:` are skipped with a debug-log warning rather than failing the dispatch, if you'd rather pin yours explicitly.)

**`explore-haiku` composes cleanly.** It pins the built-in `Explore` to Haiku, which is exactly the bottom rung this style wants. Note that `CLAUDE_CODE_SUBAGENT_MODEL` does *not* compose — set to anything other than `inherit`, it sits above subagent frontmatter in model resolution and flattens the whole ladder to one model. That's the first thing to check if tiers don't seem to take effect.

**Review boundaries:** built-in `/code-review` for a routine pass over your working diff, `/security-review` for a quick security sweep, `dotnet-dev:security-reviewer` for a deep .NET-aware audit of an area, `review-critical` for a changeset you're about to commit without having read the code yourself.

## Caveats

**Dispatch overhead is real.** Every dispatch pays for a cold start: the worker re-reads what it needs, and the brief has to restate everything. Batching matters — one brief covering five call sites beats five micro-dispatches. For a genuinely trivial change the overhead can exceed the work, and the skill still says dispatch it, because a rule with an exception costs more attention to police every turn than the exception saves. If you want a one-line fix done in the main session, ask for it directly; that's your call, not drift.

**`effort` on Haiku.** Every agent sets `model` and `effort` explicitly, per this repo's convention, so nothing silently inherits the session model. `effort` is a documented frontmatter field and the available levels depend on the model; whether the smallest models act on it is a model-side question, and the field is harmless where unsupported.

**The guard covers `Edit`/`Write`/`NotebookEdit`, not `Bash`.** Gating `Bash` would fire on every `git` and test command the orchestrator legitimately runs, so a determined `sed -i` in the main session still slips through. The skill tells Claude not to route around a denial that way, but that part is guidance again — the guard raises the floor, it isn't a sandbox.

**Not tested end to end.** The agent definitions, manifest, and hook script are validated — the guard's four paths are exercised, and its JSON parses — but no orchestrated task has been run through this plugin yet. Expect to adjust tier boundaries once you've used it on real work.

## Enforcement — on by default

Enabling the plugin *is* the consent. There is no flag to remember: orchestrator mode is the behavior you asked for by installing it, and `hooks/orchestrator-guard.sh` holds it in place from the first session.

Plugin hooks run automatically once the plugin is enabled, with no per-session prompt. The guard does two things:

* **`SessionStart`** — injects the doctrine into the session context: the roster with each agent's model and effort, the two triage questions, and the rules that workers never commit and the orchestrator never edits. This is deliberately the full essentials rather than a pointer, because a hook can inject text but cannot force a skill to load — the behavior has to hold even in a session where `orchestrate` is never invoked.
* **`PreToolUse` on `Edit`/`Write`/`NotebookEdit`** — **denies** main-session edits and returns a reason naming which tier to dispatch instead. Deny rather than prompt is the point: Claude reads the reason and re-routes to a worker on its own, so orchestration happens without stopping to ask you. A prompt on every edit would make *you* the enforcement mechanism.

The gate that makes this safe is that the payload carries `agent_id` **only** for tool calls made inside a subagent, and omits it in the main session. `PreToolUse` genuinely does fire for subagent tool calls, so without that check the guard would block the workers doing the actual work. Writes under `/tmp` pass through as well, so scratch notes aren't collateral. The script always exits 0 — a failure can never block startup or a tool call.

### Tuning it

`SUBAGENT_ORCHESTRATION_STRICT` in your settings.json `env` block, if the default isn't what you want:

| Value | Behavior |
|---|---|
| unset, `on`, `1` | Deny main-session edits; Claude re-routes to a worker. **Default.** |
| `ask` | Prompt instead of denying — you can approve and edit in place. |
| `off`, `0` | Fully inert. Nothing injected, nothing blocked; the agents and skill remain available. |

`ask` is the setting to reach for if you find yourself wanting occasional direct edits without giving up the reminder. `off` is there so a bad day never leaves you fighting your own tooling.

**This style is not always the right one.** A five-minute single-file change does not need a control plane. Reach for it on long sessions, wide codebases, and work whose difficulty genuinely varies task to task.
