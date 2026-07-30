---
name: orchestrate
description: Use when working in orchestrator mode — the main session triages and dispatches work to subagents chosen by model and effort tier, and does not read broadly or edit files itself. Load it at the start of a session the user wants run this way, when the user asks to orchestrate/delegate/dispatch rather than implement directly, and before deciding which tier a piece of work belongs to. Carries the triage rubric, the escalation protocol, the parallel-dispatch rules, and the dispatch-brief contract.
---

# Orchestrate

## Core principle

**The main context is a control plane, not a worker.** You triage, dispatch, verify, integrate, and talk to the user. The reading, searching, and writing happen inside subagents whose model and effort you chose deliberately for that specific piece of work.

This buys two things. Your context stays small, so long sessions don't degrade — search fan-out and whole-file reads never land here. And cost tracks difficulty instead of session model: a rename runs on Haiku while a migration runs on Opus at high effort, in the same session, without you switching models.

## The roster

Plugin agents are namespaced — dispatch as `subagent-orchestration:<name>`.

| Agent | Model / effort | Edits? | Dispatch it for |
|---|---|---|---|
| built-in `Explore` | inherits | No | "Where is X", "which files reference Y" — plain location lookups |
| `plan-standard` | sonnet / medium | No | Turning multi-step work into sequenced, tier-scoped dispatch briefs |
| `investigate-standard` | sonnet / medium | No | How and why code behaves as it does; scoping what a change would touch |
| `investigate-deep` | opus / high | No | Diagnosis that already resisted a cheaper pass: races, corruption, perf, contradictory evidence; architecture assessment |
| `implement-mechanical` | haiku / low | Yes | Fully decided changes: stated renames, known call-site edits, dead-branch deletion, pattern-verbatim boilerplate |
| `implement-standard` | sonnet / medium | Yes | Ordinary features and fixes with clear intent and an existing pattern to follow |
| `implement-complex` | opus / high | Yes | Consequence-heavy or unsettled work; anything a standard dispatch stalled on |
| `review-critical` | opus / high | No | A changeset you're about to accept in code where a subtle mistake is expensive |

Fan-out is structurally yours: Claude Code removes `Agent` from every subagent, so no worker can dispatch its own workers even if you wanted it to. It also removes `AskUserQuestion` — which is why a worker that hits an ambiguity must *report* rather than ask, and why your briefs have to answer questions in advance.

**Both built-ins inherit the session model.** `Explore` has since v2.1.198, and `Plan` always has. So in an Opus session they are the two rungs that escape the ladder: `Explore` costs Opus money for a grep, and `Plan` plans on Opus regardless of how ordinary the work is. Prefer `plan-standard` over built-in `Plan` here. For `Explore`, either pass `model: haiku` at dispatch or install `explore-haiku`, which pins it.

## Triage

Two questions decide the tier. Ask them in this order, every time.

**1. Is the work decided, or does it still have to be figured out?**
**2. What does being wrong cost?**

| | Cheap to be wrong | Expensive to be wrong |
|---|---|---|
| **Fully decided** — every file known, no choices left | `implement-mechanical` | `implement-standard` |
| **Clear intent** — ordinary judgment inside an existing pattern | `implement-standard` | `implement-complex` |
| **Undecided** — needs design, or the cause is unknown | investigate or plan first, then re-triage | Do not dispatch a writer. Plan, then take the decision to the user |

Signals that a task is **mechanical**: the brief could be executed by careful find-and-replace; you can name every file up front; no new decisions remain.

Signals that a task is **expensive to be wrong**: authorization or authentication, money or billing, data migrations and backfills, concurrency, public API or wire contracts, deletion of anything not provably dead, and anything a user can observe changing.

Signals to jump straight to the top: a cheaper tier already stalled here; the symptom is intermittent or environment-dependent; the change spans subsystems; the fix requires measurement.

When the two questions disagree, follow consequence. Tier down on cost, never on risk.

## Escalation

One attempt per tier. Escalate when a dispatch comes back blocked, ambiguous, still failing, or holding a design question — that report is the tier working as intended, not a failure to route around.

**Never re-dispatch the same tier on the same failure with a reworded brief.** It is the most expensive mistake available here: it spends a full dispatch to relearn the same wall, and when the second attempt half-succeeds you get two conflicting changesets to reconcile. If the tier was wrong, go up. If the brief was wrong, fix the brief *and* say what changed.

De-escalate just as deliberately. Investigation tier and implementation tier are independent choices: `investigate-deep` earning a precise diagnosis usually turns the fix mechanical, and it should then go to Haiku, not to Opus because the bug felt hard. Ask the investigator to state which tier its proposed fix needs — it has the context to know.

The Agent tool's `model` parameter overrides an agent's frontmatter model at dispatch time; **effort is frontmatter-only and cannot be overridden per dispatch**, which is why the ladder exists as separate definitions. Dispatching `implement-standard` with `model: opus` gives you opus at medium effort — a genuine intermediate rung for briefs that are routine but land in consequence-heavy code.

Model resolution runs `CLAUDE_CODE_SUBAGENT_MODEL` → per-dispatch `model` → frontmatter `model` → session model. That first entry outranks everything you do here: set to anything other than `inherit`, it flattens the whole ladder to one model. Check it first if tiers don't seem to be taking effect.

`effort` accepts `low`, `medium`, `high`, `xhigh`, and `max`; available levels depend on the model. This ladder deliberately uses three, so a tier maps to a rung you can hold in your head. Reach for `xhigh` or `max` by editing an agent, not per dispatch — there is no per-dispatch effort parameter to reach for.

## What you never delegate

* **Talking to the user.** Clarifying questions, presenting results, approval gates. A subagent asking the user something is a subagent that has stalled.
* **Deciding.** Which tier, which order, whether a report is good enough, whether to accept a changeset.
* **Git that touches shared or destructive state.** Staging, committing, pushing, resetting, rebasing, force-pushing, branch deletion. Workers report; you commit. They cannot see the session's history or the user's intent, so they cannot judge whether a destructive operation is safe.
* **Anything the user asked you personally to confirm.**

## Your verification budget

Trust nothing that says "tests pass" without evidence. A report is a claim.

You may, in the main context: read agent reports, run the build and test commands, run `git diff` and `git diff --stat` on work you commissioned, and read a single small file when you must arbitrate between two reports that contradict each other.

You may not: sweep the codebase, read files to form your own opinion of the design, or edit code. When you need a judgment that requires reading real code, that is a `review-critical` dispatch — the point of this style is that the control plane stays a control plane, not that you go blind.

**Your edit budget is zero.** No exceptions, including one-line fixes and typos. A bottom-rung dispatch costs very little, and a rule with an exception becomes a rule you spend attention policing every turn. If the user asks you directly to make an edit yourself, do it — that is their call, not a drift.

## Dispatching in parallel

Independent dispatches go in **one** message block, not sequentially.

* **Read-only work parallelizes freely.** Several investigations at once is the main win of this style.
* **Writers parallelize only when their file sets are provably disjoint.** Two agents editing one file produce lost edits, not merged edits. When in doubt, serialize.
* **Cap around three or four concurrent.** Past that, reports arrive faster than you can integrate them, and the reconciliation cost eats the savings.
* **Don't split one coherent unit of work across dispatches.** One brief, one definition of done. Five micro-dispatches to change five call sites cost more than one brief naming all five.

## Writing the brief

A subagent starts cold: no session history, no idea what the user said, no memory of the last dispatch. Everything it needs goes in the prompt. Read `references/dispatch-brief.md` for the template and worked examples before your first dispatch of a session.

The short version — every brief carries the goal as an outcome, the paths you already know, the constraints and conventions that apply, the verification command, an explicit definition of done, and the instruction to stop and report rather than guess when something is ambiguous.

## Red flags — stop

| Thought | Reality |
|---|---|
| "This is one line, I'll just edit it" | Edit budget is zero. `implement-mechanical` costs almost nothing. |
| "Let me read the file first to write a better brief" | That is the fan-out you're avoiding. Dispatch an investigator, or name the file and let the worker read it. |
| "The user is in a hurry, I'll skip the tier question" | Triage is two questions. Skipping it is how mechanical work lands on Opus and consequence-heavy work lands on Haiku. |
| "It failed, let me try again with a clearer prompt" | Same tier twice on the same failure. Escalate or fix the routing. |
| "The agent said tests pass" | Run them. A claim is not a verification. |
| "This bug was hard, so the fix needs Opus" | Different question. A precise diagnosis usually makes the fix mechanical. |
| "I'll have the implementer commit while it's in there" | Workers never commit. Commit is yours, after you've seen the diff. |
| "I'll dispatch both writers now, they probably don't overlap" | Probably-disjoint is not disjoint. Serialize. |

## Common mistakes

| Mistake | Fix |
|---|---|
| Every dispatch goes to `implement-standard` | The ladder has five rungs. Ask both triage questions, not one. |
| Briefs that say "continue" or "as discussed" | The worker has no history. Restate the goal fully every time. |
| Sequential dispatches for independent work | One block, parallel. |
| Escalating by re-prompting rather than by tier | Move up the ladder; note what the lower tier established. |
| Accepting a changeset that quietly grew | `git diff --stat` against the brief's file list; scope drift is a rejection. |
| Reading the codebase to check a worker's reasoning | Dispatch `review-critical`. Keep your context clean. |
| Dispatching `investigate-deep` as a first pass | Start with `Explore` or `investigate-standard`; reserve deep for what those couldn't settle. |
| Asking the user to decide something you can decide | Routing is your job. Only genuine product and risk decisions go up. |
