---
name: orchestrate
description: Use when working in orchestrator mode — the main session triages and dispatches work to subagents, choosing each dispatch's model and effort, and keeps broad reading, searching, and writing out of its own context by default. Load it at the start of a session the user wants run this way, when the user asks to orchestrate/delegate/dispatch rather than implement directly, and before choosing a model and effort for a dispatch. Carries the triage rubric, the model/effort table, the escalation protocol, and the dispatch-brief contract.
---

# Orchestrate

## Core principle

**The main context is a control plane by default.** You triage, dispatch, verify, integrate, and talk to the user. The reading, searching, and writing happen inside subagents, at a model and effort you chose for that specific piece of work.

This is a strong default, not a prohibition. You keep every tool, and nothing blocks you from doing work here. Use that judgment in the direction of delegating: the cost of drifting into doing everything yourself is invisible turn by turn and large by hour three.

This buys three things. Your context stays small, so long sessions don't degrade. Cost tracks difficulty instead of session model: a rename runs on Haiku at low effort while a migration runs on Opus at high effort, in the same session. And independent work runs concurrently in the background while you keep triaging.

## The roster

Four agents, one per job. Plugin agents are namespaced — dispatch as `subagent-orchestration:<name>`. None has a fixed tier: **you pass `model` and `effort` on every dispatch.** Their frontmatter defaults (sonnet / medium; opus / medium for the reviewer) only apply if you forget.

| Agent | Edits? | Dispatch it for |
|---|---|---|
| built-in `Explore` | No | "Where is X", "which files reference Y" — plain location lookups |
| `planner` | No | Turning multi-step work into sequenced dispatch briefs |
| `investigator` | No | How and why code behaves; scoping a change; root-cause diagnosis |
| `implementer` | Yes, never commits | Any decided change. State `MODE: mechanical`, `standard`, or `complex` in the brief |
| `reviewer` | No | A changeset you are about to accept where a subtle mistake is expensive |

Prefer `planner` over built-in `Plan`: `Plan` inherits the session model and returns prose rather than briefs. Built-in `Explore` inherits the session model too (Opus in an Opus session), so always pass it `model: haiku`.

## Choosing model and effort

Pass both on every dispatch. The Agent tool's `model` and `effort` parameters override the agent's frontmatter.

| Work | Agent | Model | Effort |
|---|---|---|---|
| Locate code | `Explore` | haiku | low |
| Explain behavior, scope a change, verify a claim | `investigator` | sonnet | medium |
| Diagnosis a cheaper pass couldn't settle; architecture assessment | `investigator` | opus | high |
| Sequence multi-step work | `planner` | sonnet | medium |
| Fully decided change | `implementer` MODE mechanical | haiku | low |
| Clear intent, existing pattern | `implementer` MODE standard | sonnet | medium |
| Routine shape, consequence-heavy code | `implementer` MODE standard | opus | medium |
| Consequence-heavy or unsettled | `implementer` MODE complex | opus | high |
| Review before accepting risky work | `reviewer` | opus | medium, or high for auth/money/migrations/concurrency |

**Medium is the default effort.** Move off it only for a reason you could state: `low` for work with no decisions left, `high` for consequence-heavy or already-stalled work.

**Allowed effort levels are `low`, `medium`, and `high`. Never `xhigh` or `max`.** When a dispatch stalls, a bigger model is a better lever than more effort on the same one. When opus / high stalls, the cause is almost always the brief or a decision nobody has made, and more thinking doesn't fix either. Fix the brief, investigate, or take the question to the user. The bundled guard denies any dispatch, or Workflow script, that asks for `xhigh` or `max`. Don't start ultracode-scale Workflow fan-outs from an orchestrated session either. Each worker is already a deliberate, sized dispatch, and a workflow multiplies that past the budget this style exists to protect.

## Triage

Two questions decide the row. Ask them in this order, every time.

**1. Is the work decided, or does it still have to be figured out?**
**2. What does being wrong cost?**

| | Cheap to be wrong | Expensive to be wrong |
|---|---|---|
| **Fully decided** — every file known, no choices left | mechanical, haiku / low | standard, sonnet / medium |
| **Clear intent** — ordinary judgment inside an existing pattern | standard, sonnet / medium | complex, opus / high |
| **Undecided** — needs design, or the cause is unknown | investigate or plan first, then re-triage | Don't dispatch a writer. Plan, then take the decision to the user |

**Mechanical** signals: the brief could be executed by careful find-and-replace; you can name every file; no decisions remain.

**Expensive** signals: authorization, money, migrations and backfills, concurrency, public API or wire contracts, deleting anything not provably dead, behavior a user can observe changing.

When the two questions disagree, follow consequence. Tier down on cost, never on risk.

## Escalation and follow-up

**A correction in the same scope continues the same worker.** If a worker comes back with a small gap — a missed call site, a test to add, a question the brief should have answered — resume it with `SendMessage` to its agent ID. It keeps its context and doesn't re-read everything, which costs far less than a fresh dispatch. A resumed worker keeps its original model and effort.

**A wall means a new dispatch, one step up.** When a dispatch comes back blocked, still failing, or holding a design question, raise the model first (haiku → sonnet → opus), then the effort, up to `high`. Pass what the lower dispatch established. Past opus / high there is no next rung: re-scope the brief or take the decision to the user. Never re-dispatch fresh at the same model and effort with a reworded brief: it spends a full cold start relearning the same wall, and a half-success leaves two changesets to reconcile.

**De-escalate just as deliberately.** Investigation and implementation are independent choices. An opus/high diagnosis usually turns the fix mechanical, so the fix goes to haiku/low. Ask the investigator which MODE, model, and effort its proposed fix needs.

**If tiers don't seem to take effect**, check the environment. `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` ignores the `model` you pass, and `CLAUDE_CODE_EFFORT_LEVEL` overrides the `effort` you pass.

## Dispatch mechanics

* **Use the plugin agents or `Explore`, never `fork`.** A fork inherits this whole conversation and runs on the session model, and it ignores `model` and `effort`. That is the cost and context this style exists to avoid.
* **Don't pass `name` on a dispatch.** With agent teams enabled, a named dispatch becomes a teammate rather than a subagent.
* **Dispatches run in the background.** Independent dispatches go out together in one message, and you keep triaging while they work. When a result is the only thing your next step depends on, wait for its notification. Never poll, and never read a worker's transcript or output file: that pours its whole working context into yours.
* **Read-only work parallelizes freely.** Writers parallelize only when their file sets are provably disjoint. When in doubt, serialize. If disjointness can't be established but the work is truly independent, `isolation: worktree` gives each writer its own checkout.
* **Cap around three or four concurrent.** Past that, reports arrive faster than you can integrate them.
* **Don't split one coherent unit across dispatches.** One brief naming five call sites beats five micro-dispatches.

## What you never delegate

* **Talking to the user.** Subagents cannot ask the user anything, so the brief must answer questions in advance, and you carry anything they hand back.
* **Deciding.** Which agent, model, effort, and order; whether a report is good enough; whether to accept a changeset.
* **Git that touches shared or destructive state.** Staging, committing, pushing, resetting, rebasing, branch deletion. Workers report; you commit.
* **Anything the user asked you personally to confirm.**

## When to do it yourself

Delegate unless doing it here is plainly cheaper *and* keeps your context clean. In practice that means work where you already hold everything it needs:

* A small edit to a file whose relevant lines are already in your context, where writing the brief would take longer than the edit.
* Follow-through on work you're integrating: a commit message, resolving a trivial conflict between two workers' diffs, fixing a typo a reviewer pointed at.
* A single targeted read or command whose output is short and that decides your next dispatch.

Delegate when any of these hold: you'd need to search or read more than a file or two to do it; it touches several files; it's consequence-heavy (auth, money, migrations, concurrency, public contracts), where a fresh worker and a review are worth the cost; or a cheaper model could do it just as well and the session is going to run long.

If you notice yourself three or four reads deep into something, stop and dispatch the rest with what you've learned in the brief.

## Verifying reports

A report is a claim. Run the build and test commands yourself, and check `git diff --stat` against the brief's file list. When a judgment needs real code reading — is this changeset correct, is this design sound — prefer a `reviewer` dispatch over reading the code here.

## Writing the brief

A subagent starts cold: no session history, no idea what the user said. Everything it needs goes in the prompt. Read `references/dispatch-brief.md` for the template and worked examples before your first dispatch of a session.

The short version: every brief carries the goal as an outcome, the `MODE` for implementers, the paths you already know, the constraints and the convention skills to load, the verification command, the definition of done, a short report shape, and the instruction to stop and report rather than guess.

## Red flags — stop

| Thought | Reality |
|---|---|
| "I'll just do this part myself, I'm already here" | Fine for something small with the context in hand. Three or four reads in, it wasn't small — dispatch the rest. |
| "Let me read the file first to write a better brief" | That is the fan-out you're avoiding. Dispatch an investigator, or name the file and let the worker read it. |
| "I'll leave model and effort off, the default is fine" | The defaults are a fallback. Choosing per dispatch is the whole point. |
| "This one is important, give it xhigh" | Effort tops out at `high`. Raise the model instead; past opus / high, fix the brief. |
| "It failed, let me try again with a clearer prompt" | Same model and effort on the same wall. Continue the worker if the gap is small; otherwise go up a step. |
| "The agent said tests pass" | Run them. |
| "This bug was hard, so the fix needs Opus" | Different question. A precise diagnosis usually makes the fix mechanical. |
| "Let me check how the worker is doing" | Wait for the notification. Its transcript in your context is the cost you delegated to avoid. |
| "I'll dispatch both writers now, they probably don't overlap" | Probably-disjoint is not disjoint. Serialize, or isolate in worktrees. |

## Common mistakes

| Mistake | Fix |
|---|---|
| Every dispatch at sonnet/medium | Ask both triage questions. Haiku/low and opus/high both exist for a reason. |
| Briefs that say "continue" or "as discussed" | The worker has no history. Restate the goal every time — or `SendMessage` the worker that does have it. |
| Sequential dispatches for independent work | One message, all of them, in the background. |
| Accepting a changeset that quietly grew | `git diff --stat` against the brief's file list. Scope drift is a rejection. |
| Reading the codebase to check a worker's reasoning | Dispatch `reviewer`. Keep your context clean. |
| Opus/high as a first-pass investigation | Start with `Explore` on haiku or `investigator` on sonnet; reserve opus/high for what those couldn't settle. |
| Asking the user to decide something you can decide | Routing is your job. Only genuine product and risk decisions go up. |
