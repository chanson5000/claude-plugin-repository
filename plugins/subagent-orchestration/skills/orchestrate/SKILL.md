---
name: orchestrate
description: Use when working in orchestrator mode — the main session triages and dispatches work to subagents, choosing each dispatch's model and effort, and does not read broadly or edit files itself. Load it at the start of a session the user wants run this way, when the user asks to orchestrate/delegate/dispatch rather than implement directly, and before choosing a model and effort for a dispatch. Carries the triage rubric, the model/effort table, the escalation protocol, and the dispatch-brief contract.
---

# Orchestrate

## Core principle

**The main context is a control plane, not a worker.** You triage, dispatch, verify, integrate, and talk to the user. The reading, searching, and writing happen inside subagents, at a model and effort you chose for that specific piece of work.

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

Prefer `planner` over built-in `Plan`: `Plan` inherits the session model and returns prose rather than briefs. Built-in `Explore` also runs on the session model or the Opus alias unless told otherwise, so always pass it `model: haiku`.

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

**Allowed effort levels are `low`, `medium`, `high`, and `xhigh`. Never `max`.** `xhigh` is for a diagnosis or implementation that `high` already failed on, not a first attempt. The bundled guard denies any dispatch, or Workflow script, that asks for `max`. Don't start ultracode-scale Workflow fan-outs from an orchestrated session either. Each worker is already a deliberate, sized dispatch, and a workflow multiplies that past the budget this style exists to protect.

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

**A wall means a new dispatch, one step up.** When a dispatch comes back blocked, still failing, or holding a design question, raise the model first (haiku → sonnet → opus), then the effort. Pass what the lower dispatch established. Never re-dispatch fresh at the same model and effort with a reworded brief: it spends a full cold start relearning the same wall, and a half-success leaves two changesets to reconcile.

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

## Your verification budget

A report is a claim. You may, in the main context: read agent reports, run the build and test commands, run `git diff --stat` and `git diff` on work you commissioned, and read a single small file to arbitrate between two contradicting reports.

You may not sweep the codebase, read files to form your own opinion of the design, or edit code. A judgment that needs real code reading is a `reviewer` dispatch.

**Your edit budget is zero.** No exceptions, including typos — an `implementer` at haiku/low costs very little, and a rule with an exception is a rule you police every turn. The bundled guard denies `Edit`, `Write`, and `NotebookEdit` in the main session. A denial is the routing signal working: dispatch rather than reaching for `Bash` heredocs or `sed -i`. If the user wants a direct edit and means it, tell them `SUBAGENT_ORCHESTRATION_STRICT=ask` (prompt instead of deny) or `=off` (fully inert) is how they get it. Writes under `/tmp` are exempt for scratch notes.

## Writing the brief

A subagent starts cold: no session history, no idea what the user said. Everything it needs goes in the prompt. Read `references/dispatch-brief.md` for the template and worked examples before your first dispatch of a session.

The short version: every brief carries the goal as an outcome, the `MODE` for implementers, the paths you already know, the constraints and the convention skills to load, the verification command, the definition of done, a short report shape, and the instruction to stop and report rather than guess.

## Red flags — stop

| Thought | Reality |
|---|---|
| "This is one line, I'll just edit it" | Edit budget is zero. An implementer at haiku/low costs almost nothing. |
| "Let me read the file first to write a better brief" | That is the fan-out you're avoiding. Dispatch an investigator, or name the file and let the worker read it. |
| "I'll leave model and effort off, the default is fine" | The defaults are a fallback. Choosing per dispatch is the whole point. |
| "This one is important, give it max" | `max` is off the table. Raise the model before the effort, and `xhigh` only after `high` failed. |
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
</content>
</invoke>
<invoke name="Bash">
<parameter name="command">cd /home/user/claude-plugin-repository/plugins/subagent-orchestration && grep -n "investigat\|implement-\|dotnet test\|^REPORT\|^GOAL" skills/orchestrate/references/dispatch-brief.md | head -40